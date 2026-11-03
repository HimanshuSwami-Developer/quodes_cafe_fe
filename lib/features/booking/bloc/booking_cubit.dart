import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/booking_repository.dart';

enum BookingAction { none, cancelling, uploading, requestingReview, rebooking }

class BookingState extends Equatable {
  const BookingState({
    this.booking,
    this.loading = false,
    this.action = BookingAction.none,
    this.uploadProgress = 0,
    this.error,
    this.tick = 0,
  });

  /// Null only while the first load runs (deep link without `extra`).
  final Booking? booking;
  final bool loading;
  final BookingAction action;

  /// 0..1 while uploading a screenshot.
  final double uploadProgress;

  /// One-shot error for a SnackBar; cleared on the next emit.
  final ApiException? error;

  /// Bumps every second so countdown widgets rebuild.
  final int tick;

  bool get busy => action != BookingAction.none;

  BookingState copyWith({
    Booking? booking,
    bool? loading,
    BookingAction? action,
    double? uploadProgress,
    ApiException? error,
    int? tick,
  }) => BookingState(
    booking: booking ?? this.booking,
    loading: loading ?? this.loading,
    action: action ?? this.action,
    uploadProgress: uploadProgress ?? this.uploadProgress,
    error: error,
    tick: tick ?? this.tick,
  );

  @override
  List<Object?> get props => [
    booking?.id,
    booking?.status,
    booking?.aiChecks.length,
    booking?.utr,
    booking?.receivedAt,
    loading,
    action,
    uploadProgress,
    error,
    tick,
  ];
}

/// One booking on screen: loads it, ticks every second for countdowns,
/// optionally polls the server, and runs the booking actions.
///
/// Views react to status changes with a BlocListener and route via
/// `booking.defaultStep` (see core/router/routes.dart).
class BookingCubit extends Cubit<BookingState> {
  BookingCubit(
    this._repo, {
    required this.bookingId,
    Booking? initial,
    Duration? pollEvery,
  }) : super(BookingState(booking: initial, loading: initial == null)) {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    if (pollEvery != null) {
      _poller = Timer.periodic(pollEvery, (_) => refresh(silent: true));
    }
    refresh(silent: initial != null);
  }

  final BookingRepository _repo;
  final int bookingId;
  Timer? _ticker;
  Timer? _poller;

  void _onTick() {
    if (isClosed) return;
    emit(state.copyWith(tick: state.tick + 1));
    // When a server deadline passes, ask the server what happened
    // (it expires / releases lazily on read).
    final b = state.booking;
    if (b == null) return;
    final deadline = switch (b.status) {
      'locked' || 'ai_failed' => b.lockExpiresAt,
      'pending_human' => b.verifyDeadline,
      _ => null,
    };
    if (deadline != null &&
        b.remainingUntil(deadline) == Duration.zero &&
        state.tick % 5 == 0) {
      refresh(silent: true);
    }
  }

  Future<void> refresh({bool silent = false}) async {
    if (!silent) emit(state.copyWith(loading: true));
    try {
      final b = await _repo.byId(bookingId);
      if (!isClosed) emit(state.copyWith(booking: b, loading: false));
    } on ApiException catch (e) {
      // Background polls stay quiet; a visible load reports the error.
      if (!isClosed) {
        emit(state.copyWith(loading: false, error: silent ? null : e));
      }
    }
  }

  Future<bool> _run(BookingAction a, Future<Booking> Function() call) async {
    if (state.busy) return false;
    emit(state.copyWith(action: a, uploadProgress: 0));
    try {
      final b = await call();
      if (!isClosed) {
        emit(state.copyWith(booking: b, action: BookingAction.none));
      }
      return true;
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(action: BookingAction.none, error: e));
      return false;
    }
  }

  Future<bool> cancel() =>
      _run(BookingAction.cancelling, () => _repo.cancel(bookingId));

  Future<bool> uploadProof(XFile screenshot, {String utr = ''}) => _run(
    BookingAction.uploading,
    () => _repo.uploadProof(
      bookingId,
      screenshot: screenshot,
      utr: utr,
      onProgress: (sent, total) {
        if (total > 0 && !isClosed) {
          emit(state.copyWith(uploadProgress: sent / total));
        }
      },
    ),
  );

  Future<bool> requestManualReview() => _run(
    BookingAction.requestingReview,
    () => _repo.requestManualReview(bookingId),
  );

  /// Returns the NEW booking (different id) so the view can navigate to it.
  Future<Booking?> rebookWithCredit() async {
    if (state.busy) return null;
    emit(state.copyWith(action: BookingAction.rebooking));
    try {
      final nb = await _repo.rebookWithCredit(bookingId);
      if (!isClosed) emit(state.copyWith(action: BookingAction.none));
      return nb;
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(action: BookingAction.none, error: e));
      return null;
    }
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    _poller?.cancel();
    return super.close();
  }
}
