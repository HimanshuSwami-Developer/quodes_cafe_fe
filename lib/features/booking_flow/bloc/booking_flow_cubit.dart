import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/booking_repository.dart';

/// Choices made across Games → Station → Availability → Slots, before a lock.
class BookingFlowState extends Equatable {
  const BookingFlowState({
    this.game,
    this.type,
    this.seats = const [],
    this.date,
    this.dateLabel,
    this.startHour,
    this.duration = 2,
    this.locking = false,
    this.error,
  });

  final Game? game;
  final StationType? type;

  /// Selected seats with their station code.
  final List<({Seat seat, String station})> seats;
  final String? date;
  final String? dateLabel;
  final int? startHour;
  final int duration;
  final bool locking;
  final ApiException? error;

  List<int> get seatIds => seats.map((s) => s.seat.id).toList();
  int get players => seats.length;

  String get stationSummary {
    if (seats.isEmpty) return '';
    final codes = seats.map((s) => s.station).toSet().toList();
    if (codes.length == 1) {
      return '${type?.name ?? ''} · #${codes.first.split('-').last}';
    }
    return '${type?.name ?? ''} · ${codes.map((c) => '#${c.split('-').last}').join(', ')}';
  }

  bool get canLock =>
      game != null && seats.isNotEmpty && date != null && startHour != null;

  BookingFlowState copyWith({
    Game? game,
    StationType? type,
    List<({Seat seat, String station})>? seats,
    String? date,
    String? dateLabel,
    int? Function()? startHour,
    int? duration,
    bool? locking,
    ApiException? error,
  }) => BookingFlowState(
    game: game ?? this.game,
    type: type ?? this.type,
    seats: seats ?? this.seats,
    date: date ?? this.date,
    dateLabel: dateLabel ?? this.dateLabel,
    startHour: startHour != null ? startHour() : this.startHour,
    duration: duration ?? this.duration,
    locking: locking ?? this.locking,
    error: error,
  );

  @override
  List<Object?> get props => [
    game?.id,
    type?.code,
    seatIds,
    date,
    startHour,
    duration,
    locking,
    error,
  ];
}

class BookingFlowCubit extends Cubit<BookingFlowState> {
  BookingFlowCubit(this._bookings) : super(const BookingFlowState());
  final BookingRepository _bookings;

  static const maxPlayers = 4;

  /// Starting a new booking from the games list resets everything.
  void start(Game game) => emit(BookingFlowState(game: game));

  void selectType(StationType type) {
    if (type.code == state.type?.code) return;
    emit(
      BookingFlowState(game: state.game, type: type, duration: state.duration),
    );
  }

  /// Returns false if the max-players limit blocked the selection.
  bool toggleSeat(Seat seat, String station) {
    final has = state.seats.any((s) => s.seat.id == seat.id);
    if (has) {
      emit(
        state.copyWith(
          seats: state.seats.where((s) => s.seat.id != seat.id).toList(),
        ),
      );
      return true;
    }
    final cap = state.game == null
        ? maxPlayers
        : (state.game!.maxPlayers < maxPlayers
              ? state.game!.maxPlayers
              : maxPlayers);
    if (state.seats.length >= cap) return false;
    emit(
      state.copyWith(seats: [...state.seats, (seat: seat, station: station)]),
    );
    return true;
  }

  /// Replace the selection (e.g. "pick another slot" from a released booking).
  void restore({
    required Game? game,
    required StationType type,
    required List<({Seat seat, String station})> seats,
  }) => emit(BookingFlowState(game: game, type: type, seats: seats));

  void selectDate(String date, String label) =>
      emit(state.copyWith(date: date, dateLabel: label, startHour: () => null));

  void selectDuration(int hours) => emit(state.copyWith(duration: hours));

  void selectStart(int? hour) => emit(state.copyWith(startHour: () => hour));

  /// Locks the slot. Returns the new booking, or null (error is in state).
  Future<Booking?> lock() async {
    if (!state.canLock || state.locking) return null;
    emit(state.copyWith(locking: true));
    try {
      final b = await _bookings.create(
        gameId: state.game!.id,
        seatIds: state.seatIds,
        date: state.date!,
        startHour: state.startHour!,
        durationHours: state.duration,
      );
      emit(state.copyWith(locking: false));
      return b;
    } on ApiException catch (e) {
      emit(state.copyWith(locking: false, error: e));
      return null;
    }
  }
}
