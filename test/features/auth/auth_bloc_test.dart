import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quodes_gaming/core/network/api_exception.dart';
import 'package:quodes_gaming/data/repositories/auth_repository.dart';
import 'package:quodes_gaming/features/auth/bloc/auth_bloc.dart';

import '../../helpers/fixtures.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;
  setUp(() {
    repo = MockAuthRepository();
    when(() => repo.logout()).thenAnswer((_) async {});
  });

  blocTest<AuthBloc, AuthState>(
    'start without a stored session → unauthenticated',
    build: () {
      when(() => repo.hasSession).thenReturn(false);
      return AuthBloc(repo);
    },
    act: (b) => b.add(const AuthStarted()),
    expect: () => [const AuthState.unauthenticated()],
    verify: (_) => verifyNever(() => repo.me()),
  );

  blocTest<AuthBloc, AuthState>(
    'start with a session → authenticated with me()',
    build: () {
      when(() => repo.hasSession).thenReturn(true);
      when(() => repo.me()).thenAnswer((_) async => user());
      return AuthBloc(repo);
    },
    act: (b) => b.add(const AuthStarted()),
    expect: () => [
      isA<AuthState>()
          .having((s) => s.status, 'status', AuthStatus.authenticated)
          .having((s) => s.user?.id, 'user', 7),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'me() 401 at start → logout + unauthenticated',
    build: () {
      when(() => repo.hasSession).thenReturn(true);
      when(() => repo.me()).thenThrow(
        const ApiException(ApiErrorType.unauthorized, 'Please log in again.'),
      );
      return AuthBloc(repo);
    },
    act: (b) => b.add(const AuthStarted()),
    expect: () => [const AuthState.unauthenticated()],
    verify: (_) => verify(() => repo.logout()).called(1),
  );

  blocTest<AuthBloc, AuthState>(
    'session expired → unauthenticated with the expired flag',
    build: () => AuthBloc(repo),
    seed: () => AuthState.authenticated(user()),
    act: (b) => b.add(const AuthSessionExpired()),
    expect: () => [const AuthState.unauthenticated(expired: true)],
    verify: (b) => expect(b.state.sessionExpired, isTrue),
  );

  blocTest<AuthBloc, AuthState>(
    'logout clears tokens',
    build: () => AuthBloc(repo),
    seed: () => AuthState.authenticated(user()),
    act: (b) => b.add(const AuthLogoutRequested()),
    expect: () => [const AuthState.unauthenticated()],
    verify: (_) => verify(() => repo.logout()).called(1),
  );
}
