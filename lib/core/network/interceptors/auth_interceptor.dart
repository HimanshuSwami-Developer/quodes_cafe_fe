import 'dart:async';

import 'package:dio/dio.dart';

import '../../storage/token_storage.dart';

/// Attaches the access token and transparently refreshes it on a 401.
///
/// Concurrency: a refresh is single-flight. Requests that fail with 401 while a
/// refresh is running wait for the same future, then replay with the new token.
/// If the refresh itself fails the session is cleared and [onSessionExpired]
/// fires once (the AuthBloc then routes to login).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokens,
    required this.refreshClient,
    required this.onSessionExpired,
  });

  final TokenStorage tokens;

  /// A bare Dio (no auth interceptor) used for the refresh call and replays,
  /// so a failing refresh can never recurse into this interceptor.
  final Dio refreshClient;
  final void Function() onSessionExpired;

  Future<String?>? _refreshing;

  static const skipAuth = 'skipAuth';
  static const _retried = 'authRetried';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = tokens.access;
    if (token != null && options.extra[skipAuth] != true) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final req = err.requestOptions;
    final is401 = err.response?.statusCode == 401;
    if (!is401 || req.extra[skipAuth] == true || req.extra[_retried] == true) {
      return handler.next(err);
    }
    if (tokens.refresh == null) {
      await _expire();
      return handler.next(err);
    }

    final newToken = await (_refreshing ??= _refresh().whenComplete(
      () => _refreshing = null,
    ));
    if (newToken == null) return handler.next(err);

    try {
      req.headers['Authorization'] = 'Bearer $newToken';
      req.extra[_retried] = true;
      handler.resolve(await refreshClient.fetch(req));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<String?> _refresh() async {
    try {
      final r = await refreshClient.post<Map<String, dynamic>>(
        'auth/refresh/',
        data: {'refresh': tokens.refresh},
        options: Options(extra: {skipAuth: true}),
      );
      final access = r.data?['access'] as String?;
      if (access == null) throw StateError('no access token');
      await tokens.save(access: access, refresh: r.data?['refresh'] as String?);
      return access;
    } catch (_) {
      await _expire();
      return null;
    }
  }

  Future<void> _expire() async {
    if (!tokens.hasSession) return;
    await tokens.clear();
    onSessionExpired();
  }
}
