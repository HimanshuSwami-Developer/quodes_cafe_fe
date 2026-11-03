import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/load_status.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/auth_repository.dart';
import 'resend_countdown.dart';

class VerifyEmailState extends Equatable {
  const VerifyEmailState({
    this.status = LoadStatus.initial,
    this.resendLeft = 0,
    this.resending = false,
    this.user,
    this.error,
    this.notice,
  });

  final LoadStatus status;
  final int resendLeft;
  final bool resending;
  final User? user;
  final String? error;

  /// One-shot info toast (e.g. "New code sent").
  final String? notice;

  VerifyEmailState copyWith({
    LoadStatus? status,
    int? resendLeft,
    bool? resending,
    User? user,
    String? error,
    String? notice,
  }) => VerifyEmailState(
    status: status ?? this.status,
    resendLeft: resendLeft ?? this.resendLeft,
    resending: resending ?? this.resending,
    user: user ?? this.user,
    error: error,
    notice: notice,
  );

  @override
  List<Object?> get props => [
    status,
    resendLeft,
    resending,
    user?.id,
    error,
    notice,
  ];
}

class VerifyEmailCubit extends Cubit<VerifyEmailState> {
  VerifyEmailCubit(this._auth, this.sent) : super(const VerifyEmailState()) {
    _countdown = ResendCountdown((left) {
      if (!isClosed) emit(state.copyWith(resendLeft: left));
    })..start(sent.resendAfter);
  }

  final AuthRepository _auth;
  final CodeSent sent;
  late final ResendCountdown _countdown;

  Future<void> verify(String code) async {
    if (state.status.isLoading) return;
    if (code.length != Validators.otpLength) {
      return emit(
        state.copyWith(
          status: LoadStatus.failure,
          error: 'Enter the 6-digit code',
        ),
      );
    }
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final user = await _auth.verifyEmail(sent.email, code);
      emit(state.copyWith(status: LoadStatus.success, user: user));
    } on ApiException catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, error: e.message));
    }
  }

  Future<void> resend() async {
    if (state.resending || state.resendLeft > 0) return;
    emit(state.copyWith(resending: true));
    try {
      await _auth.resendVerification(sent.email);
      _countdown.start(sent.resendAfter);
      emit(
        state.copyWith(
          resending: false,
          notice: 'New code sent to ${sent.maskedEmail}',
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(resending: false, error: e.message));
    }
  }

  @override
  Future<void> close() {
    _countdown.dispose();
    return super.close();
  }
}
