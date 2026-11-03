import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/admin_models.dart';
import '../../../../data/repositories/admin_repository.dart';

/// Review action last performed on the booking.
enum ReviewAction { approve, reject }

/// One booking in full, plus the approve/reject progress.
class AdminBookingDetailState extends Equatable {
  /// Starts empty.
  const AdminBookingDetailState({
    this.status = LoadStatus.initial,
    this.booking,
    this.error,
    this.actionStatus = LoadStatus.initial,
    this.action,
    this.actionError,
  });

  final LoadStatus status;
  final StaffBooking? booking;
  final ApiException? error;

  /// Progress of approve / reject.
  final LoadStatus actionStatus;
  final ReviewAction? action;
  final ApiException? actionError;

  AdminBookingDetailState copyWith({
    LoadStatus? status,
    StaffBooking? booking,
    ApiException? error,
    LoadStatus? actionStatus,
    ReviewAction? action,
    ApiException? actionError,
  }) => AdminBookingDetailState(
    status: status ?? this.status,
    booking: booking ?? this.booking,
    error: error,
    actionStatus: actionStatus ?? this.actionStatus,
    action: action ?? this.action,
    actionError: actionError,
  );

  @override
  List<Object?> get props => [
    status,
    booking,
    error,
    actionStatus,
    action,
    actionError,
  ];
}

/// Loads one booking and approves / rejects its payment.
class AdminBookingDetailCubit extends Cubit<AdminBookingDetailState> {
  /// Creates the cubit for booking [id].
  AdminBookingDetailCubit(this._repo, {required this.id})
    : super(const AdminBookingDetailState());

  final AdminRepository _repo;
  final int id;

  /// Loads (or reloads) the booking.
  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final b = await _repo.booking(id);
      if (!isClosed) {
        emit(state.copyWith(status: LoadStatus.success, booking: b));
      }
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(status: LoadStatus.failure, error: e));
    }
  }

  /// Confirms the payment.
  Future<bool> approve() => _act(ReviewAction.approve, () => _repo.approve(id));

  /// Rejects the payment with an optional [note] to the player.
  Future<bool> reject(String note) =>
      _act(ReviewAction.reject, () => _repo.reject(id, note: note));

  Future<bool> _act(
    ReviewAction action,
    Future<StaffBooking> Function() call,
  ) async {
    if (state.actionStatus.isLoading) return false;
    emit(state.copyWith(actionStatus: LoadStatus.loading, action: action));
    try {
      final b = await call();
      if (!isClosed) {
        emit(state.copyWith(actionStatus: LoadStatus.success, booking: b));
      }
      return true;
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(state.copyWith(actionStatus: LoadStatus.failure, actionError: e));
      }
      return false;
    }
  }
}
