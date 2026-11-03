import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/load_status.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/catalog_repository.dart';
import 'booking_flow_cubit.dart';

class StationState extends Equatable {
  const StationState({
    this.status = LoadStatus.initial,
    this.types,
    this.typeCode,
    this.map,
    this.mapLoading = false,
    this.error,
    this.notice,
  });

  final LoadStatus status;
  final List<StationType>? types;
  final String? typeCode;
  final SeatMap? map;
  final bool mapLoading;
  final ApiException? error;

  /// One-shot hint (e.g. "Valorant isn’t on PS5").
  final String? notice;

  StationType? get type => types?.where((t) => t.code == typeCode).firstOrNull;

  StationState copyWith({
    LoadStatus? status,
    List<StationType>? types,
    String? typeCode,
    SeatMap? Function()? map,
    bool? mapLoading,
    ApiException? error,
    String? notice,
  }) => StationState(
    status: status ?? this.status,
    types: types ?? this.types,
    typeCode: typeCode ?? this.typeCode,
    map: map != null ? map() : this.map,
    mapLoading: mapLoading ?? this.mapLoading,
    error: error,
    notice: notice,
  );

  @override
  List<Object?> get props => [
    status,
    types?.map((t) => t.code).toList(),
    typeCode,
    map?.type,
    map?.stations.length,
    mapLoading,
    error,
    notice,
  ];
}

/// Station types and the live seat map. The seat *selection* lives in the
/// app-wide [BookingFlowCubit] so later steps can read it.
class StationCubit extends Cubit<StationState> {
  StationCubit(this._catalog, this._flow) : super(const StationState());

  final CatalogRepository _catalog;
  final BookingFlowCubit _flow;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final types = await _catalog.stationTypes(gameId: _flow.state.game?.id);
      if (isClosed) return;
      emit(state.copyWith(status: LoadStatus.success, types: types));
      if (types.isEmpty) return;
      final current = _flow.state.type;
      final keep = current == null
          ? null
          : types.where((t) => t.code == current.code && t.enabled).firstOrNull;
      final pick =
          keep ?? types.firstWhere((t) => t.enabled, orElse: () => types.first);
      await _show(pick);
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(status: LoadStatus.failure, error: e));
    }
  }

  Future<void> selectType(StationType t) async {
    if (!t.enabled) {
      final game = _flow.state.game?.name ?? 'This game';
      return emit(state.copyWith(notice: '$game isn’t on ${t.name}'));
    }
    if (t.code == state.typeCode) return;
    await _show(t);
  }

  Future<void> _show(StationType t) async {
    _flow.selectType(t);
    emit(state.copyWith(typeCode: t.code, map: () => null, mapLoading: true));
    try {
      final m = await _catalog.seatMap(t.code);
      if (!isClosed && state.typeCode == t.code) {
        emit(state.copyWith(map: () => m, mapLoading: false));
      }
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(mapLoading: false, error: e));
    }
  }
}
