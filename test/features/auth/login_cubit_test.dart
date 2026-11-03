import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quodes_gaming/core/bloc/load_status.dart';
import 'package:quodes_gaming/core/network/api_exception.dart';
import 'package:quodes_gaming/data/repositories/auth_repository.dart';
import 'package:quodes_gaming/features/auth/bloc/login_cubit.dart';

import '../../helpers/fixtures.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;
  setUp(() => repo = MockAuthRepository());

  blocTest<LoginCubit, LoginState>(
    'success emits loading then the signed-in user',
    build: () {
      when(() => repo.login(any(), any())).thenAnswer((_) async => user());
      return LoginCubit(repo);
    },
    act: (c) => c.submit(' player@email.com ', 'Secret#123'),
    expect: () => [
      const LoginState(status: LoadStatus.loading),
      isA<LoginState>()
          .having((s) => s.status, 'status', LoadStatus.success)
          .having((s) => s.user?.id, 'user', 7),
    ],
    verify: (_) =>
        verify(() => repo.login('player@email.com', 'Secret#123')).called(1),
  );

  blocTest<LoginCubit, LoginState>(
    'email_not_verified asks for verification with where the code went',
    build: () {
      when(() => repo.login(any(), any())).thenThrow(
        const ApiException(
          ApiErrorType.forbidden,
          'Verify your email first. We sent you a new code.',
          statusCode: 403,
          data: {
            'code': 'email_not_verified',
            'email': 'player@email.com',
            'masked_email': 'p•••••@email.com',
            'resend_after': 45,
          },
        ),
      );
      return LoginCubit(repo);
    },
    act: (c) => c.submit('player@email.com', 'pw'),
    skip: 1,
    expect: () => [
      isA<LoginState>()
          .having((s) => s.user, 'user', isNull)
          .having(
            (s) => s.verificationRequired?.maskedEmail,
            'masked',
            'p•••••@email.com',
          )
          .having((s) => s.verificationRequired?.resendAfter, 'resend', 45),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'wrong password surfaces the server message',
    build: () {
      when(() => repo.login(any(), any())).thenThrow(
        const ApiException(
          ApiErrorType.validation,
          'Wrong email or password.',
          statusCode: 400,
        ),
      );
      return LoginCubit(repo);
    },
    act: (c) => c.submit('player@email.com', 'nope'),
    expect: () => [
      const LoginState(status: LoadStatus.loading),
      const LoginState(
        status: LoadStatus.failure,
        error: 'Wrong email or password.',
      ),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'empty fields fail without calling the API',
    build: () => LoginCubit(repo),
    act: (c) => c.submit('', ''),
    expect: () => [
      const LoginState(
        status: LoadStatus.failure,
        error: 'Enter your email and password',
      ),
    ],
    verify: (_) => verifyNever(() => repo.login(any(), any())),
  );
}
