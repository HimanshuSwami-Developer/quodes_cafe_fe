import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/load_status.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/catalog_repository.dart';
import 'booking_flow_cubit.dart';

/// "4 PM" style label for an hour of day (0–24+).
String hourLabel(int h) {
  final hh = h % 24;
  final v = hh % 12 == 0 ? 12 : hh % 12;
  return '$v ${hh >= 12 ? 'PM' : 'AM'}';
}

/// Why a session of [duration] hours starting at index [start] can't be
/// booked, or null if every hour is open.
String? slotClash(List<SlotHour> hours, int? start, int duration) {
  if (start == null) return null;
  if (start + duration > hours.length) return 'Session runs past closing time';
  for (var k = start; k < start + duration; k++) {
    if (hours[k].status != 'open') {
      return '${hourLabel(hours[k].hour)} is taken, try a shorter session';
    }
  }
  return null;
}

class SlotsState extends Equatable {
  const SlotsState({
    this.status = LoadStatus.initial,
    this.days,
    this.day = 0,
    this.hours,
    this.error,
  });

  final LoadStatus status;
  final List<DayOption>? days;
  final int day;

  /// Null while the selected day's hours load.
  final List<SlotHour>? hours;
  final ApiException? error;

  DayOption? get selectedDay => days == null ? null : days![day];

  /// Index into [hours] of the flow's start hour.
  int? startIndex(int? startHour) {
    if (startHour == null || hours == null) return null;
    final i = hours!.indexWhere((h) => h.hour == startHour);
    return i < 0 ? null : i;
  }

  SlotsState copyWith({
    LoadStatus? status,
    List<DayOption>? days,
    int? day,
    List<SlotHour>? Function()? hours,
    ApiException? error,
  }) => SlotsState(
    status: status ?? this.status,
    days: days ?? this.days,
    day: day ?? this.day,
    hours: hours != null ? hours() : this.hours,
    error: error,
  );

  @override
  List<Object?> get props => [
    status,
    days?.length,
    day,
    hours?.map((h) => '${h.hour}${h.status}').join(),
    error,
  ];
}

/// Dates and per-hour status for the selected seats. Date, duration and
/// start time are written to the [BookingFlowCubit].
class SlotsCubit extends Cubit<SlotsState> {
  SlotsCubit(this._catalog, this._flow) : super(const SlotsState());

  final CatalogRepository _catalog;
  final BookingFlowCubit _flow;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final days = await _catalog.dates();
      if (isClosed) return;
      if (days.isEmpty) {
        return emit(
          state.copyWith(
            status: LoadStatus.success,
            days: days,
            hours: () => [],
          ),
        );
      }
      final idx = days.indexWhere((x) => x.date == _flow.state.date);
      emit(state.copyWith(days: days, day: idx < 0 ? 0 : idx));
      _selectFlowDate();
      await loadHours();
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(status: LoadStatus.failure, error: e));
    }
  }

  void selectDay(int i) {
    if (i == state.day || state.days == null) return;
    emit(state.copyWith(day: i));
    _selectFlowDate();
    loadHours();
  }

  void _selectFlowDate() {
    final d = state.selectedDay!;
    final label =
        '${d.dow[0]}${d.dow.substring(1).toLowerCase()}, ${d.num} ${d.mon}';
    if (_flow.state.date != d.date) {
      _flow.selectDate(d.date, label);
    }
  }

  Future<void> loadHours() async {
    final d = state.selectedDay;
    if (d == null) return;
    emit(state.copyWith(hours: () => null));
    try {
      final h = await _catalog.slots(_flow.state.seatIds, d.date);
      if (isClosed || state.selectedDay?.date != d.date) return;
      emit(state.copyWith(status: LoadStatus.success, hours: () => h));
      // A start time picked earlier may no longer be open.
      if (state.startIndex(_flow.state.startHour) == null) {
        _flow.selectStart(null);
      }
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(status: LoadStatus.failure, error: e));
    }
  }
}
