import 'package:dio/dio.dart';

import '../api_exception.dart';

/// Last interceptor in the chain: turns every DioException into an
/// [ApiException] (carried in `error`) with a message a player can read.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err.copyWith(error: map(err)));
  }

  static ApiException map(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(
          ApiErrorType.timeout,
          'Quodes is taking too long to respond. Try again.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          ApiErrorType.network,
          'Can’t reach Quodes. Check your connection.',
        );
      case DioExceptionType.cancel:
        return const ApiException(ApiErrorType.cancelled, 'Request cancelled.');
      case DioExceptionType.badCertificate:
        return const ApiException(
          ApiErrorType.network,
          'Secure connection failed.',
        );
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }

    final status = e.response?.statusCode;
    final body = e.response?.data;
    final data = body is Map
        ? Map<String, dynamic>.from(body)
        : <String, dynamic>{};
    final type = switch (status) {
      400 || 422 => ApiErrorType.validation,
      401 => ApiErrorType.unauthorized,
      403 => ApiErrorType.forbidden,
      404 => ApiErrorType.notFound,
      409 => ApiErrorType.conflict,
      429 => ApiErrorType.rateLimited,
      final s? when s >= 500 => ApiErrorType.server,
      _ => ApiErrorType.unknown,
    };
    return ApiException(
      type,
      _message(data, body) ?? _fallback(type, status),
      statusCode: status,
      data: data,
    );
  }

  static String? _message(Map<String, dynamic> data, Object? body) {
    if (data['detail'] != null) return data['detail'].toString();
    for (final v in data.values) {
      if (v is List && v.isNotEmpty) return v.first.toString();
      if (v is String && v.isNotEmpty) return v;
    }
    if (body is List && body.isNotEmpty) return body.first.toString();
    return null;
  }

  static String _fallback(ApiErrorType t, int? status) => switch (t) {
    ApiErrorType.unauthorized => 'Please log in again.',
    ApiErrorType.forbidden => 'You don’t have access to that.',
    ApiErrorType.notFound => 'Not found.',
    ApiErrorType.rateLimited => 'Too many tries. Wait a minute and try again.',
    ApiErrorType.server => 'Quodes is having trouble. Try again shortly.',
    _ => 'Something went wrong${status == null ? '' : ' ($status)'}.',
  };
}
