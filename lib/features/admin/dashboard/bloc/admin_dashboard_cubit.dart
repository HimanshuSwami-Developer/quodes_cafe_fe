import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/admin_models.dart';
import '../../../../data/repositories/admin_repository.dart';

/// Dashboard data plus load status.
class AdminDashboardState extends Equatable {
  /// Creates a state; [data] stays null until the first load.
  const AdminDashboardState({
    this.status = LoadStatus.initial,
    this.data,
    this.error,
  });

  final LoadStatus status;
  final AdminDashboard? data;
  final ApiException? error;

  AdminDashboardState copyWith({
    LoadStatus? status,
    AdminDashboard? data,
    ApiException? error,
  }) => AdminDashboardState(
    status: status ?? this.status,
    data: data ?? this.data,
    error: error,
  );

  @override
  List<Object?> get props => [status, data, error];
}

/// Loads the dashboard and refreshes it in the background.
class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  /// Refreshes every [every] after [start] (null: never).
  AdminDashboardCubit(this._repo, {this.every = const Duration(seconds: 20)})
    : super(const AdminDashboardState());

  final AdminRepository _repo;
  final Duration? every;
  Timer? _timer;

  /// First load plus the auto-refresh.
  void start() {
    load();
    if (every != null) {
      _timer?.cancel();
      _timer = Timer.periodic(every!, (_) => load(silent: true));
    }
  }

  /// Loads; [silent] keeps the current data on screen (and on error).
  Future<void> load({bool silent = false}) async {
    if (!silent || state.data == null) {
      emit(state.copyWith(status: LoadStatus.loading));
    }
    try {
      final d = await _repo.dashboard();
      if (!isClosed) emit(state.copyWith(status: LoadStatus.success, data: d));
    } on ApiException catch (e) {
      if (isClosed || (silent && state.data != null)) return;
      emit(state.copyWith(status: LoadStatus.failure, error: e));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
