import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quodes_gaming/core/network/api_exception.dart';
import 'package:quodes_gaming/core/network/interceptors/error_interceptor.dart';

void main() {
  final req = RequestOptions(path: 'bookings/');

  DioException bad(int status, Object? data) => DioException(
    requestOptions: req,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: req, statusCode: status, data: data),
  );

  group('ErrorInterceptor.map', () {
    test('timeouts', () {
      for (final t in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        final e = ErrorInterceptor.map(
          DioException(requestOptions: req, type: t),
        );
        expect(e.type, ApiErrorType.timeout, reason: t.name);
        expect(e.isRetryable, isTrue);
      }
    });

    test('connection error', () {
      final e = ErrorInterceptor.map(
        DioException(
          requestOptions: req,
          type: DioExceptionType.connectionError,
        ),
      );
      expect(e.type, ApiErrorType.network);
      expect(e.message, contains('Can’t reach Quodes'));
    });

    test('400 uses detail', () {
      final e = ErrorInterceptor.map(
        bad(400, {'detail': 'Pick 1 to 4 hours.'}),
      );
      expect(e.type, ApiErrorType.validation);
      expect(e.message, 'Pick 1 to 4 hours.');
      expect(e.statusCode, 400);
    });

    test('400 with only field errors uses the first one', () {
      final e = ErrorInterceptor.map(
        bad(400, {
          'email': ['Enter a valid email address.'],
        }),
      );
      expect(e.message, 'Enter a valid email address.');
      expect(e.fieldErrors, {'email': 'Enter a valid email address.'});
    });

    test('409 conflict keeps the code', () {
      final e = ErrorInterceptor.map(
        bad(409, {'detail': 'Seat taken.', 'code': 'slot_taken'}),
      );
      expect(e.type, ApiErrorType.conflict);
      expect(e.code, 'slot_taken');
      expect(e.message, 'Seat taken.');
    });

    test('500 without a body gets a friendly fallback', () {
      final e = ErrorInterceptor.map(bad(500, '<html>oops</html>'));
      expect(e.type, ApiErrorType.server);
      expect(e.message, 'Quodes is having trouble. Try again shortly.');
      expect(e.isRetryable, isTrue);
    });
  });
}
