import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/load_status.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/catalog_repository.dart';

class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    this.status = LoadStatus.initial,
    this.sent,
    this.error,
    this.supportPhone = '',
  });

  final LoadStatus status;
  final CodeSent? sent;
  final String? error;

  /// Desk phone from the (public) café endpoint, for the "Support" link.
  final String supportPhone;

  ForgotPasswordState copyWith({
    LoadStatus? status,
    CodeSent? sent,
    String? error,
    String? supportPhone,
  }) => ForgotPasswordState(
    status: status ?? this.status,
    sent: sent,
    error: error,
    supportPhone: supportPhone ?? this.supportPhone,
  );

  @override
  List<Object?> get props => [status, sent?.email, error, supportPhone];
}

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit(this._auth, this._catalog)
    : super(const ForgotPasswordState()) {
    _loadSupport();
  }

  final AuthRepository _auth;
  final CatalogRepository _catalog;

  Future<void> _loadSupport() async {
    try {
      final cafe = await _catalog.cafe();
      if (!isClosed) emit(state.copyWith(supportPhone: cafe.supportPhone));
    } on ApiException {
      // Optional: the link falls back to the policies page.
    }
  }

  Future<void> submit(String email) async {
    if (state.status.isLoading) return;
    final e = email.trim();
    if (e.isEmpty) {
      return emit(
        state.copyWith(
          status: LoadStatus.failure,
          error: 'Enter your account email',
        ),
      );
    }
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final sent = await _auth.forgotPassword(e);
      emit(state.copyWith(status: LoadStatus.success, sent: sent));
    } on ApiException catch (err) {
      emit(state.copyWith(status: LoadStatus.failure, error: err.message));
    }
  }
}
