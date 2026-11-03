import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart' show XFile;

import '../config/env.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

/// Thin typed wrapper over Dio. Repositories call this; it only ever throws
/// [ApiException].
///
/// Interceptor order (request → top-down, error → bottom-up as registered):
///   Auth (token + refresh) → Retry (idempotent GETs) → Logging → Error mapping.
class ApiClient {
  ApiClient({
    required AppConfig config,
    required TokenStorage tokens,
    required void Function() onSessionExpired,
    Dio? dio,
  }) : dio = dio ?? Dio() {
    final base = BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      sendTimeout: const Duration(seconds: 60), // screenshot uploads
      headers: {'Accept': 'application/json'},
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );
    this.dio.options = base;

    // Bare client for token refresh and auth replays (no AuthInterceptor).
    final bare = Dio(base);
    if (config.httpLogging) bare.interceptors.add(LoggingInterceptor());

    this.dio.interceptors.addAll([
      AuthInterceptor(
        tokens: tokens,
        refreshClient: bare,
        onSessionExpired: onSessionExpired,
      ),
      RetryInterceptor(dio: this.dio),
      if (config.httpLogging) LoggingInterceptor(),
      ErrorInterceptor(),
    ]);
  }

  final Dio dio;

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _call(() => dio.get<T>(path, queryParameters: query));

  Future<T> post<T>(String path, {Object? data, bool auth = true}) => _call(
    () => dio.post<T>(
      path,
      data: data,
      options: auth ? null : Options(extra: {AuthInterceptor.skipAuth: true}),
    ),
  );

  Future<T> patch<T>(String path, {Object? data}) =>
      _call(() => dio.patch<T>(path, data: data));

  /// DELETE (admin panel). DRF answers 204 with no body, so nothing is
  /// returned.
  Future<void> delete(String path, {Object? data}) =>
      _call<dynamic>(() => dio.delete<dynamic>(path, data: data));

  /// Multipart POST. [files] maps field name → picked file.
  Future<T> upload<T>(
    String path, {
    Map<String, String> fields = const {},
    Map<String, XFile> files = const {},
    void Function(int sent, int total)? onProgress,
  }) async {
    // Bytes, not file paths: works on Android, iOS and the web.
    final form = FormData.fromMap({
      ...fields,
      for (final f in files.entries)
        f.key: MultipartFile.fromBytes(
          await f.value.readAsBytes(),
          filename: f.value.name,
        ),
    });
    return _call(
      () => dio.post<T>(path, data: form, onSendProgress: onProgress),
    );
  }

  Future<T> _call<T>(Future<Response<T>> Function() send) async {
    try {
      final r = await send();
      return r.data as T;
    } on DioException catch (e) {
      final err = e.error;
      throw err is ApiException ? err : ErrorInterceptor.map(e);
    }
  }
}
