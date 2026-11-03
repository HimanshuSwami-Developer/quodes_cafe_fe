import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/admin_models.dart';
import '../../../data/repositories/admin_repository.dart';

/// Live counts for the sidebar badges ("Verify payments", "Tickets"),
/// polled from the dashboard KPIs.
class AdminBadgesCubit extends Cubit<DashboardKpis> {
  /// Polls every [every] once [start] is called.
  AdminBadgesCubit(this._repo, {this.every = const Duration(seconds: 30)})
    : super(const DashboardKpis());

  final AdminRepository _repo;
  final Duration every;
  Timer? _timer;

  /// Loads now and then on every tick.
  void start() {
    refresh();
    _timer?.cancel();
    _timer = Timer.periodic(every, (_) => refresh());
  }

  /// Re-reads the counts (e.g. right after approving a payment).
  Future<void> refresh() async {
    try {
      final d = await _repo.dashboard();
      if (!isClosed) emit(d.kpis);
    } on ApiException {
      // Badges are best-effort; keep the last counts.
    }
  }

  /// Uses fresh KPIs fetched elsewhere (the dashboard page).
  void update(DashboardKpis k) => emit(k);

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
