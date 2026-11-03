import 'dart:math';

import 'package:dio/dio.dart';

/// Retries idempotent requests (GET/HEAD) on connection errors, timeouts and
/// 502/503/504, with exponential backoff + jitter. Never retries POST/PATCH:
/// replaying "lock slot" or "upload proof" could double-act.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 400),
  });

  final Dio dio;
  final int maxRetries;
  final Duration baseDelay;
  final _rand = Random();

  static const _attempt = 'retryAttempt';

  bool _shouldRetry(DioException e) {
    final method = e.requestOptions.method.toUpperCase();
    if (method != 'GET' && method != 'HEAD') return false;
    if (e.requestOptions.extra['noRetry'] == true) return false;
    final status = e.response?.statusCode;
    return switch (e.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout => true,
      DioExceptionType.badResponse =>
        status == 502 || status == 503 || status == 504,
      _ => false,
    };
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = (err.requestOptions.extra[_attempt] as int?) ?? 0;
    if (attempt >= maxRetries || !_shouldRetry(err)) return handler.next(err);

    final backoff = baseDelay * pow(2, attempt).toInt();
    await Future<void>.delayed(
      backoff + Duration(milliseconds: _rand.nextInt(250)),
    );
    final req = err.requestOptions..extra[_attempt] = attempt + 1;
    try {
      handler.resolve(await dio.fetch(req));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
