import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/bloc/load_status.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/catalog_repository.dart';

class AvailabilityState extends Equatable {
  const AvailabilityState({
    required this.days,
    this.status = LoadStatus.initial,
    this.day = 0,
    this.typeCode = 'PS5',
    this.data,
    this.updatedAt,
    this.error,
  });

  /// Today, tomorrow and the day after.
  final List<DateTime> days;
  final LoadStatus status;
  final int day;

  /// Highlighted column (display only; seats were picked on the previous step).
  final String typeCode;
  final Availability? data;
  final DateTime? updatedAt;
  final ApiException? error;

  DateTime get selectedDay => days[day];
  String get isoDate => DateFormat('yyyy-MM-dd').format(selectedDay);

  String dayName(int i) => i == 0
      ? 'Today'
      : i == 1
      ? 'Tomorrow'
      : DateFormat('EEEE').format(days[i]);

  AvailabilityType? get current =>
      data?.types.where((t) => t.code == typeCode).firstOrNull;

  AvailabilityState copyWith({
    LoadStatus? status,
    int? day,
    String? typeCode,
    Availability? Function()? data,
    DateTime? updatedAt,
    ApiException? error,
  }) => AvailabilityState(
    days: days,
    status: status ?? this.status,
    day: day ?? this.day,
    typeCode: typeCode ?? this.typeCode,
    data: data != null ? data() : this.data,
    updatedAt: updatedAt ?? this.updatedAt,
    error: error,
  );

  @override
  List<Object?> get props => [
    status,
    day,
    typeCode,
    data?.date,
    updatedAt,
    error,
  ];
}

class AvailabilityCubit extends Cubit<AvailabilityState> {
  AvailabilityCubit(this._catalog, {String? typeCode, DateTime? today})
    : super(
        AvailabilityState(
          days: List.generate(3, (i) {
            final t = today ?? DateTime.now();
            return DateTime(t.year, t.month, t.day + i);
          }),
          typeCode: typeCode ?? 'PS5',
        ),
      );

  final CatalogRepository _catalog;

  Future<void> load() async {
    final day = state.day;
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final d = await _catalog.availability(state.isoDate);
      if (isClosed || day != state.day) return;
      emit(
        state.copyWith(
          status: LoadStatus.success,
          data: () => d,
          updatedAt: DateTime.now(),
        ),
      );
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(status: LoadStatus.failure, error: e));
    }
  }

  void selectDay(int i) {
    if (i == state.day) return;
    emit(state.copyWith(day: i, data: () => null));
    load();
  }

  void selectType(String code) => emit(state.copyWith(typeCode: code));
}
