import 'package:equatable/equatable.dart';

enum ApiErrorType {
  network,
  timeout,
  cancelled,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  rateLimited,
  server,
  unknown,
}

/// The only error type that leaves the data layer. Blocs show [message];
/// [code] / [data] carry machine-readable details from the API body
/// (e.g. `code: email_not_verified` with `email`, `masked_email`).
class ApiException extends Equatable implements Exception {
  const ApiException(
    this.type,
    this.message, {
    this.statusCode,
    this.data = const {},
  });

  final ApiErrorType type;
  final String message;
  final int? statusCode;
  final Map<String, dynamic> data;

  String? get code => data['code']?.toString();

  /// Field errors from DRF (`{"field": ["msg"]}`), for inline form errors.
  Map<String, String> get fieldErrors => {
    for (final e in data.entries)
      if (e.value is List && (e.value as List).isNotEmpty)
        e.key: (e.value as List).first.toString(),
  };

  bool get isRetryable =>
      type == ApiErrorType.network ||
      type == ApiErrorType.timeout ||
      type == ApiErrorType.server;

  @override
  String toString() => message;

  @override
  List<Object?> get props => [type, message, statusCode, code];
}
