import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/load_status.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/auth_repository.dart';
import 'resend_countdown.dart';

class ResetPasswordState extends Equatable {
  const ResetPasswordState({
    this.status = LoadStatus.initial,
    this.password = '',
    this.resendLeft = 0,
    this.user,
    this.loginFailed = false,
    this.error,
    this.notice,
  });

  final LoadStatus status;
  final String password;
  final int resendLeft;

  /// Signed in with the new password (hand to AuthBloc).
  final User? user;

  /// Reset worked but the automatic login didn't: send the player to login.
  final bool loginFailed;
  final String? error;
  final String? notice;

  List<(String, bool)> get rules => Validators.passwordRules(password);
  int get score => Validators.passwordScore(password);

  ResetPasswordState copyWith({
    LoadStatus? status,
    String? password,
    int? resendLeft,
    User? user,
    bool? loginFailed,
    String? error,
    String? notice,
  }) => ResetPasswordState(
    status: status ?? this.status,
    password: password ?? this.password,
    resendLeft: resendLeft ?? this.resendLeft,
    user: user ?? this.user,
    loginFailed: loginFailed ?? this.loginFailed,
    error: error,
    notice: notice,
  );

  @override
  List<Object?> get props => [
    status,
    password,
    resendLeft,
    user?.id,
    loginFailed,
    error,
    notice,
  ];
}

class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  ResetPasswordCubit(this._auth, this.sent)
    : super(const ResetPasswordState()) {
    _countdown = ResendCountdown((left) {
      if (!isClosed) emit(state.copyWith(resendLeft: left));
    })..start(sent.resendAfter);
  }

  final AuthRepository _auth;
  final CodeSent sent;
  late final ResendCountdown _countdown;

  void passwordChanged(String v) => emit(state.copyWith(password: v));

  Future<void> resend() async {
    if (state.resendLeft > 0) return;
    try {
      await _auth.forgotPassword(sent.email);
      _countdown.start(sent.resendAfter);
      emit(state.copyWith(notice: 'New code sent'));
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
    }
  }

  Future<void> submit({required String code, required String confirm}) async {
    if (state.status.isLoading) return;
    String? invalid;
    if (code.length != Validators.otpLength) {
      invalid = 'Enter the 6-digit code';
    } else if (state.password != confirm) {
      invalid = 'Passwords don’t match';
    } else if (state.rules.any((r) => !r.$2)) {
      invalid = 'Password is too weak';
    }
    if (invalid != null) {
      return emit(state.copyWith(status: LoadStatus.failure, error: invalid));
    }
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      await _auth.resetPassword(sent.email, code, state.password);
    } on ApiException catch (e) {
      return emit(state.copyWith(status: LoadStatus.failure, error: e.message));
    }
    try {
      final user = await _auth.login(sent.email, state.password);
      emit(state.copyWith(status: LoadStatus.success, user: user));
    } on ApiException {
      emit(
        state.copyWith(
          status: LoadStatus.success,
          loginFailed: true,
          notice: 'Password reset. Log in with your new password.',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _countdown.dispose();
    return super.close();
  }
}
