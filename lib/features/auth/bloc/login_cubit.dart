import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/load_status.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/auth_repository.dart';

class LoginState extends Equatable {
  const LoginState({
    this.status = LoadStatus.initial,
    this.user,
    this.verificationRequired,
    this.error,
  });

  final LoadStatus status;

  /// Set on success; the view hands it to the AuthBloc.
  final User? user;

  /// Set when the account exists but the email isn't verified yet.
  final CodeSent? verificationRequired;
  final String? error;

  LoginState copyWith({
    LoadStatus? status,
    User? user,
    CodeSent? verificationRequired,
    String? error,
  }) => LoginState(
    status: status ?? this.status,
    user: user,
    verificationRequired: verificationRequired,
    error: error,
  );

  @override
  List<Object?> get props => [
    status,
    user?.id,
    verificationRequired?.email,
    error,
  ];
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._auth) : super(const LoginState());
  final AuthRepository _auth;

  Future<void> submit(String email, String password) async {
    if (state.status.isLoading) return;
    final e = email.trim();
    if (e.isEmpty || password.isEmpty) {
      return emit(
        state.copyWith(
          status: LoadStatus.failure,
          error: 'Enter your email and password',
        ),
      );
    }
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final user = await _auth.login(e, password);
      emit(state.copyWith(status: LoadStatus.success, user: user));
    } on ApiException catch (err) {
      if (err.code == 'email_not_verified') {
        emit(
          state.copyWith(
            status: LoadStatus.initial,
            verificationRequired: CodeSent.fromJson(err.data, fallbackEmail: e),
            error: err.message,
          ),
        );
      } else {
        emit(state.copyWith(status: LoadStatus.failure, error: err.message));
      }
    }
  }
}
