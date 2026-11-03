import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Compact request/response log for local & stage. Redacts tokens, passwords,
/// OTP codes and file bodies; truncates long payloads.
class LoggingInterceptor extends Interceptor {
  static const _secretKeys = {
    'password',
    'new_password',
    'code',
    'access',
    'refresh',
  };
  static const _maxLen = 800;

  static const _start = 'logStart';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_start] = DateTime.now();
    debugPrint('→ ${options.method} ${options.uri}${_body(options.data)}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final o = response.requestOptions;
    debugPrint(
      '← ${response.statusCode} ${o.method} ${o.uri.path} '
      '${_ms(o)}${_body(response.data)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final o = err.requestOptions;
    debugPrint(
      '✕ ${err.response?.statusCode ?? err.type.name} ${o.method} '
      '${o.uri.path} ${_ms(o)}${_body(err.response?.data)}',
    );
    handler.next(err);
  }

  String _ms(RequestOptions o) {
    final s = o.extra[_start];
    return s is DateTime
        ? '(${DateTime.now().difference(s).inMilliseconds}ms)'
        : '';
  }

  String _body(Object? data) {
    if (data == null) return '';
    if (data is FormData) {
      return ' form{${data.fields.map((f) => f.key).join(',')}'
          '${data.files.isEmpty ? '' : ' +${data.files.length} file'}}';
    }
    String text;
    try {
      text = jsonEncode(_redact(data));
    } catch (_) {
      text = data.toString();
    }
    return ' ${text.length > _maxLen ? '${text.substring(0, _maxLen)}…' : text}';
  }

  Object? _redact(Object? v) {
    if (v is Map) {
      return {
        for (final e in v.entries)
          e.key: _secretKeys.contains(e.key) ? '•••' : _redact(e.value),
      };
    }
    if (v is List) return v.map(_redact).toList();
    return v;
  }
}
