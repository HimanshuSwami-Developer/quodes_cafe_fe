import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState._(this.status, [this.user, this.sessionExpired = false]);
  const AuthState.unknown() : this._(AuthStatus.unknown);
  const AuthState.authenticated(User user)
    : this._(AuthStatus.authenticated, user);
  const AuthState.unauthenticated({bool expired = false})
    : this._(AuthStatus.unauthenticated, null, expired);

  final AuthStatus status;
  final User? user;

  /// True when we got here because the refresh token died (show a toast).
  final bool sessionExpired;

  @override
  List<Object?> get props => [
    status,
    user?.id,
    user?.credit,
    user?.gamertag,
    sessionExpired,
  ];
}

sealed class AuthEvent {
  const AuthEvent();
}

/// App launch: restore the session from secure storage.
class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// Login / verify-email / signup finished with a session.
class AuthLoggedIn extends AuthEvent {
  const AuthLoggedIn(this.user);
  final User user;
}

/// Re-fetch `me/` (credit, stats) after a booking changes.
class AuthUserRefreshRequested extends AuthEvent {
  const AuthUserRefreshRequested();
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Fired by the Dio AuthInterceptor when the refresh token is rejected.
class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}

/// App-wide session state. go_router listens to it for redirects.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repo) : super(const AuthState.unknown()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoggedIn>((e, emit) => emit(AuthState.authenticated(e.user)));
    on<AuthUserRefreshRequested>(_onRefresh);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthSessionExpired>(
      (e, emit) => emit(const AuthState.unauthenticated(expired: true)),
    );
  }

  final AuthRepository _repo;

  Future<void> _onStarted(AuthStarted e, Emitter<AuthState> emit) async {
    if (!_repo.hasSession) return emit(const AuthState.unauthenticated());
    try {
      emit(AuthState.authenticated(await _repo.me()));
    } on ApiException catch (err) {
      if (err.type == ApiErrorType.unauthorized) {
        await _repo.logout();
        emit(const AuthState.unauthenticated());
      } else {
        // Offline at launch: keep the stored session, load the profile later.
        emit(AuthState.authenticated(User.placeholder()));
      }
    }
  }

  Future<void> _onRefresh(
    AuthUserRefreshRequested e,
    Emitter<AuthState> emit,
  ) async {
    if (state.status != AuthStatus.authenticated) return;
    try {
      emit(AuthState.authenticated(await _repo.me()));
    } on ApiException {
      // keep the last known user
    }
  }

  Future<void> _onLogout(AuthLogoutRequested e, Emitter<AuthState> emit) async {
    await _repo.logout();
    emit(const AuthState.unauthenticated());
  }
}
