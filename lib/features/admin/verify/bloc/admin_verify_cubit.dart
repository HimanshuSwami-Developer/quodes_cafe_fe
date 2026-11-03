import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/admin_models.dart';
import '../../../../data/repositories/admin_repository.dart';

/// The payment verification queue.
class AdminVerifyState extends Equatable {
  /// Creates a state; [items] stays null until the first load.
  const AdminVerifyState({
    this.status = LoadStatus.initial,
    this.items,
    this.error,
    this.actionError,
    this.busyIds = const {},
    this.done,
    this.seq = 0,
  });

  final LoadStatus status;

  /// Bookings waiting for a human, oldest verify deadline first.
  final List<StaffBooking>? items;

  /// Why the queue failed to load.
  final ApiException? error;

  /// Why an approve/reject failed (toast).
  final ApiException? actionError;

  /// Bookings with an approve/reject in flight.
  final Set<int> busyIds;

  /// Message for the last successful action (toast).
  final String? done;

  /// Bumped on every action outcome so repeated messages still toast.
  final int seq;

  AdminVerifyState copyWith({
    LoadStatus? status,
    List<StaffBooking>? items,
    ApiException? error,
    ApiException? actionError,
    Set<int>? busyIds,
    String? done,
    int? seq,
  }) => AdminVerifyState(
    status: status ?? this.status,
    items: items ?? this.items,
    error: error,
    actionError: actionError,
    busyIds: busyIds ?? this.busyIds,
    done: done,
    seq: seq ?? this.seq,
  );

  @override
  List<Object?> get props => [
    status,
    items,
    error,
    actionError,
    busyIds,
    done,
    seq,
  ];
}

/// Loads the verify queue and approves / rejects payments.
///
/// Approve is optimistic: the card disappears at once and comes back (at
/// the same position) if the server refuses.
class AdminVerifyCubit extends Cubit<AdminVerifyState> {
  /// [refreshEvery] null disables background refresh (tests).
  AdminVerifyCubit(this._repo, {this.refreshEvery})
    : super(const AdminVerifyState());

  final AdminRepository _repo;
  final Duration? refreshEvery;
  Timer? _timer;
  int _request = 0;

  /// First load plus the background refresh.
  void start() {
    load();
    if (refreshEvery != null) {
      _timer?.cancel();
      _timer = Timer.periodic(refreshEvery!, (_) => load(silent: true));
    }
  }

  /// Loads the queue; [silent] keeps the cards on screen.
  Future<void> load({bool silent = false}) async {
    // Don't overwrite an optimistic removal with a stale list.
    if (silent && state.busyIds.isNotEmpty) return;
    final id = ++_request;
    if (!silent || state.items == null) {
      emit(state.copyWith(status: LoadStatus.loading));
    }
    try {
      final items = await _repo.verifyQueue();
      if (isClosed || id != _request) return;
      emit(state.copyWith(status: LoadStatus.success, items: _sorted(items)));
    } on ApiException catch (e) {
      if (isClosed || id != _request) return;
      if (silent && state.items != null) return; // keep the cards
      emit(state.copyWith(status: LoadStatus.failure, error: e));
    }
  }

  static List<StaffBooking> _sorted(List<StaffBooking> l) {
    final far = DateTime(9999);
    return [...l]..sort(
      (a, b) => (a.booking.verifyDeadline ?? far).compareTo(
        b.booking.verifyDeadline ?? far,
      ),
    );
  }

  /// Confirms [b]'s payment. Returns true on success.
  Future<bool> approve(StaffBooking b) async {
    final items = [...?state.items];
    final index = items.indexWhere((e) => e.id == b.id);
    if (index < 0 || state.busyIds.contains(b.id)) return false;
    _request++; // drop any refresh already in flight
    items.removeAt(index);
    emit(state.copyWith(items: items, busyIds: {...state.busyIds, b.id}));
    try {
      await _repo.approve(b.id);
      if (isClosed) return true;
      emit(
        state.copyWith(
          busyIds: {...state.busyIds}..remove(b.id),
          done: '${b.code} approved',
          seq: state.seq + 1,
        ),
      );
      return true;
    } on ApiException catch (e) {
      if (isClosed) return false;
      final restored = [...?state.items];
      restored.insert(index.clamp(0, restored.length), b);
      emit(
        state.copyWith(
          items: restored,
          busyIds: {...state.busyIds}..remove(b.id),
          actionError: e,
          seq: state.seq + 1,
        ),
      );
      return false;
    }
  }

  /// Rejects [b]'s payment with an optional [note] to the player.
  Future<bool> reject(StaffBooking b, {String note = ''}) async {
    if (state.busyIds.contains(b.id)) return false;
    emit(state.copyWith(busyIds: {...state.busyIds, b.id}));
    try {
      await _repo.reject(b.id, note: note);
      if (isClosed) return true;
      emit(
        state.copyWith(
          items: [...?state.items]..removeWhere((e) => e.id == b.id),
          busyIds: {...state.busyIds}..remove(b.id),
          done: '${b.code} rejected',
          seq: state.seq + 1,
        ),
      );
      return true;
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            busyIds: {...state.busyIds}..remove(b.id),
            actionError: e,
            seq: state.seq + 1,
          ),
        );
      }
      return false;
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
