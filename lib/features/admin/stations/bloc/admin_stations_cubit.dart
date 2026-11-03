import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/admin_models.dart';
import '../../../../data/repositories/admin_repository.dart';

/// Stations page: station types (inline-editable) and the stations of the
/// selected type.
class AdminStationsState extends Equatable {
  /// Creates the state (nothing loaded yet).
  const AdminStationsState({
    this.typesStatus = LoadStatus.initial,
    this.types,
    this.typesError,
    this.selected,
    this.stationsStatus = LoadStatus.initial,
    this.stations,
    this.stationsError,
    this.editingId,
    this.saveStatus = LoadStatus.initial,
    this.fieldErrors = const {},
    this.busyIds = const {},
    this.adding = false,
    this.message,
    this.actionError,
    this.seq = 0,
  });

  final LoadStatus typesStatus;
  final List<AdminStationType>? types;
  final ApiException? typesError;

  /// Code of the selected station type.
  final String? selected;

  final LoadStatus stationsStatus;
  final List<AdminStation>? stations;
  final ApiException? stationsError;

  /// Station type being edited inline (null = none).
  final int? editingId;
  final LoadStatus saveStatus;

  /// Server field errors for the inline edit.
  final Map<String, String> fieldErrors;

  /// Stations with a request in flight.
  final Set<int> busyIds;

  /// "Add station" in flight.
  final bool adding;

  /// Success toast text (with [seq]).
  final String? message;

  /// Row action failure (with [seq]).
  final ApiException? actionError;

  /// Bumped on every toast-worthy event.
  final int seq;

  /// The selected station type, if loaded.
  AdminStationType? get selectedType =>
      types?.where((t) => t.code == selected).firstOrNull;

  /// The number "Add station" will use: one past the highest.
  int get nextNumber {
    final s = stations ?? const <AdminStation>[];
    if (s.isEmpty) return 1;
    return s.map((e) => e.number).reduce((a, b) => a > b ? a : b) + 1;
  }

  AdminStationsState copyWith({
    LoadStatus? typesStatus,
    List<AdminStationType>? types,
    ApiException? typesError,
    String? selected,
    LoadStatus? stationsStatus,
    List<AdminStation>? Function()? stations,
    ApiException? stationsError,
    int? Function()? editingId,
    LoadStatus? saveStatus,
    Map<String, String>? fieldErrors,
    Set<int>? busyIds,
    bool? adding,
    String? message,
    ApiException? actionError,
    int? seq,
  }) => AdminStationsState(
    typesStatus: typesStatus ?? this.typesStatus,
    types: types ?? this.types,
    typesError: typesError,
    selected: selected ?? this.selected,
    stationsStatus: stationsStatus ?? this.stationsStatus,
    stations: stations != null ? stations() : this.stations,
    stationsError: stationsError,
    editingId: editingId != null ? editingId() : this.editingId,
    saveStatus: saveStatus ?? this.saveStatus,
    fieldErrors: fieldErrors ?? this.fieldErrors,
    busyIds: busyIds ?? this.busyIds,
    adding: adding ?? this.adding,
    message: message,
    actionError: actionError,
    seq: seq ?? this.seq,
  );

  @override
  List<Object?> get props => [
    typesStatus,
    types,
    typesError,
    selected,
    stationsStatus,
    stations,
    stationsError,
    editingId,
    saveStatus,
    fieldErrors,
    busyIds,
    adding,
    message,
    actionError,
    seq,
  ];
}

/// Loads station types and stations; edits types, adds/toggles/deletes
/// stations.
class AdminStationsCubit extends Cubit<AdminStationsState> {
  /// Creates the cubit; call [load].
  AdminStationsCubit(this._repo) : super(const AdminStationsState());

  final AdminRepository _repo;
  int _stationsRequest = 0;

  /// Loads the types and selects the first (or the current) one.
  Future<void> load() async {
    emit(state.copyWith(typesStatus: LoadStatus.loading));
    try {
      final types = await _repo.stationTypes();
      if (isClosed) return;
      final keep = types.any((t) => t.code == state.selected);
      final sel = keep ? state.selected : types.firstOrNull?.code;
      emit(
        state.copyWith(
          typesStatus: LoadStatus.success,
          types: types,
          selected: sel,
        ),
      );
      if (sel != null) await _loadStations();
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(state.copyWith(typesStatus: LoadStatus.failure, typesError: e));
      }
    }
  }

  /// Shows the stations of type [code].
  Future<void> select(String code) async {
    if (code == state.selected && state.stations != null) return;
    emit(state.copyWith(selected: code, stations: () => null));
    await _loadStations();
  }

  /// Reloads the stations of the selected type.
  Future<void> reloadStations() => _loadStations();

  Future<void> _loadStations() async {
    final code = state.selected;
    if (code == null) return;
    final id = ++_stationsRequest;
    emit(state.copyWith(stationsStatus: LoadStatus.loading));
    try {
      final list = await _repo.stations(typeCode: code);
      if (isClosed || id != _stationsRequest) return;
      list.sort((a, b) => a.number.compareTo(b.number));
      emit(
        state.copyWith(
          stationsStatus: LoadStatus.success,
          stations: () => list,
        ),
      );
    } on ApiException catch (e) {
      if (!isClosed && id == _stationsRequest) {
        emit(
          state.copyWith(stationsStatus: LoadStatus.failure, stationsError: e),
        );
      }
    }
  }

  /// Turns type [id]'s row into inputs.
  void startEdit(int id) => emit(
    state.copyWith(
      editingId: () => id,
      fieldErrors: const {},
      saveStatus: LoadStatus.initial,
    ),
  );

  /// Leaves inline edit without saving.
  void cancelEdit() =>
      emit(state.copyWith(editingId: () => null, fieldErrors: const {}));

  /// Saves an edited type; true on success.
  Future<bool> saveType(AdminStationType t) async {
    if (state.saveStatus.isLoading) return false;
    emit(state.copyWith(saveStatus: LoadStatus.loading, fieldErrors: const {}));
    try {
      final saved = await _repo.saveStationType(t);
      if (isClosed) return true;
      emit(
        state.copyWith(
          saveStatus: LoadStatus.success,
          editingId: () => null,
          types: [
            for (final x in state.types ?? const <AdminStationType>[])
              x.id == saved.id ? saved : x,
          ],
          message: '${saved.name} saved',
          seq: state.seq + 1,
        ),
      );
      return true;
    } on ApiException catch (e) {
      if (!isClosed) {
        final fields = e.fieldErrors;
        emit(
          state.copyWith(
            saveStatus: LoadStatus.failure,
            fieldErrors: fields,
            // Errors no inline input shows still need a toast.
            actionError: fields.isEmpty ? e : null,
            seq: fields.isEmpty ? state.seq + 1 : state.seq,
          ),
        );
      }
      return false;
    }
  }

  /// Adds the next free station number to the selected type.
  Future<void> addStation() async {
    final type = state.selectedType;
    if (type == null || state.adding) return;
    final number = state.nextNumber;
    emit(state.copyWith(adding: true));
    try {
      final st = await _repo.createStation(typeId: type.id, number: number);
      if (isClosed) return;
      final list = [...?state.stations, st]
        ..sort((a, b) => a.number.compareTo(b.number));
      emit(
        state.copyWith(
          adding: false,
          stations: () => list,
          types: _withCount(type.code, list),
          message: 'Station ${st.code} added',
          seq: state.seq + 1,
        ),
      );
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(state.copyWith(adding: false, actionError: e, seq: state.seq + 1));
      }
    }
  }

  /// Turns a station on or off for booking.
  Future<void> setActive(AdminStation s, bool active) => _act(s, () async {
    final updated = await _repo.setStationActive(s.id, active);
    return [
      for (final x in state.stations ?? const <AdminStation>[])
        x.id == s.id ? updated : x,
    ];
  });

  /// Deletes a station (and its seats).
  Future<void> delete(AdminStation s) => _act(s, () async {
    await _repo.deleteStation(s.id);
    return [
      for (final x in state.stations ?? const <AdminStation>[])
        if (x.id != s.id) x,
    ];
  }, message: 'Station ${s.code} deleted');

  Future<void> _act(
    AdminStation s,
    Future<List<AdminStation>> Function() call, {
    String? message,
  }) async {
    if (state.busyIds.contains(s.id)) return;
    emit(state.copyWith(busyIds: {...state.busyIds, s.id}));
    try {
      final list = await call();
      if (isClosed) return;
      emit(
        state.copyWith(
          stations: () => list,
          types: _withCount(state.selected, list),
          busyIds: {...state.busyIds}..remove(s.id),
          message: message,
          seq: message == null ? state.seq : state.seq + 1,
        ),
      );
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            busyIds: {...state.busyIds}..remove(s.id),
            actionError: e,
            seq: state.seq + 1,
          ),
        );
      }
    }
  }

  /// Types with [code]'s active-station count recomputed from [list].
  List<AdminStationType>? _withCount(String? code, List<AdminStation> list) =>
      state.types
          ?.map(
            (t) => t.code == code
                ? t.copyWith(stationCount: list.where((s) => s.isActive).length)
                : t,
          )
          .toList();
}
