import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/admin_models.dart';
import '../../../../data/repositories/admin_repository.dart';

/// Filters and results of the admin bookings table.
class AdminBookingsState extends Equatable {
  /// Starts with no filters and no rows.
  const AdminBookingsState({
    this.status = LoadStatus.initial,
    this.items,
    this.query = '',
    this.statuses = const {},
    this.date,
    this.error,
  });

  final LoadStatus status;

  /// Null until the first load.
  final List<StaffBooking>? items;
  final String query;

  /// Selected status codes (empty = all).
  final Set<String> statuses;

  /// `YYYY-MM-DD` or null for any date.
  final String? date;
  final ApiException? error;

  AdminBookingsState copyWith({
    LoadStatus? status,
    List<StaffBooking>? items,
    String? query,
    Set<String>? statuses,
    String? Function()? date,
    ApiException? error,
  }) => AdminBookingsState(
    status: status ?? this.status,
    items: items ?? this.items,
    query: query ?? this.query,
    statuses: statuses ?? this.statuses,
    date: date != null ? date() : this.date,
    error: error,
  );

  @override
  List<Object?> get props => [status, items, query, statuses, date, error];
}

/// Loads bookings for the admin table with debounced search and filters.
class AdminBookingsCubit extends Cubit<AdminBookingsState> {
  /// [debounce] delays search requests while typing.
  AdminBookingsCubit(
    this._repo, {
    this.debounce = const Duration(milliseconds: 300),
  }) : super(const AdminBookingsState());

  final AdminRepository _repo;
  final Duration debounce;
  Timer? _debounce;
  int _request = 0;

  /// Loads with the current filters.
  Future<void> load() async {
    final id = ++_request;
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final items = await _repo.bookings(
        statuses: state.statuses.toList(),
        date: state.date,
        query: state.query,
      );
      // Drop stale responses from an earlier filter/query.
      if (isClosed || id != _request) return;
      emit(state.copyWith(status: LoadStatus.success, items: items));
    } on ApiException catch (e) {
      if (!isClosed && id == _request) {
        emit(state.copyWith(status: LoadStatus.failure, error: e));
      }
    }
  }

  /// Debounced free-text search (code, UTR, email, gamertag, phone).
  void search(String q) {
    final t = q.trim();
    if (t == state.query) return;
    emit(state.copyWith(query: t));
    _debounce?.cancel();
    _debounce = Timer(debounce, load);
  }

  /// Adds or removes [code] from the status filter.
  void toggleStatus(String code) {
    final s = {...state.statuses};
    s.contains(code) ? s.remove(code) : s.add(code);
    emit(state.copyWith(statuses: s));
    load();
  }

  /// Clears the status filter.
  void clearStatuses() {
    if (state.statuses.isEmpty) return;
    emit(state.copyWith(statuses: const {}));
    load();
  }

  /// Sets (or clears with null) the date filter.
  void setDate(String? date) {
    if (date == state.date) return;
    emit(state.copyWith(date: () => date));
    load();
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
