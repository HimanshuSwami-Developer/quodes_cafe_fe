import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/admin_models.dart';
import '../../../../data/repositories/admin_repository.dart';

/// Café settings page: the loaded settings plus the save outcome.
class AdminSettingsState extends Equatable {
  /// Creates the state (nothing loaded yet).
  const AdminSettingsState({
    this.status = LoadStatus.initial,
    this.settings,
    this.error,
    this.saveStatus = LoadStatus.initial,
    this.fieldErrors = const {},
    this.saveError,
  });

  /// Loading the settings.
  final LoadStatus status;
  final CafeSettings? settings;

  /// Why loading failed.
  final ApiException? error;

  /// Saving the form.
  final LoadStatus saveStatus;

  /// `api_key → message` from the server, shown under each input.
  final Map<String, String> fieldErrors;

  /// Why saving failed.
  final ApiException? saveError;

  AdminSettingsState copyWith({
    LoadStatus? status,
    CafeSettings? settings,
    ApiException? error,
    LoadStatus? saveStatus,
    Map<String, String>? fieldErrors,
    ApiException? saveError,
  }) => AdminSettingsState(
    status: status ?? this.status,
    settings: settings ?? this.settings,
    error: error,
    saveStatus: saveStatus ?? this.saveStatus,
    fieldErrors: fieldErrors ?? this.fieldErrors,
    saveError: saveError,
  );

  @override
  List<Object?> get props => [
    status,
    settings,
    error,
    saveStatus,
    fieldErrors,
    saveError,
  ];
}

/// Loads and saves the café settings singleton.
class AdminSettingsCubit extends Cubit<AdminSettingsState> {
  /// Creates the cubit; call [load].
  AdminSettingsCubit(this._repo) : super(const AdminSettingsState());
  final AdminRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final s = await _repo.cafe();
      if (!isClosed) {
        emit(state.copyWith(status: LoadStatus.success, settings: s));
      }
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(status: LoadStatus.failure, error: e));
    }
  }

  /// Saves [s]; returns true on success.
  Future<bool> save(CafeSettings s) async {
    if (state.saveStatus.isLoading) return false;
    emit(state.copyWith(saveStatus: LoadStatus.loading, fieldErrors: const {}));
    try {
      final saved = await _repo.saveCafe(s);
      if (!isClosed) {
        emit(
          state.copyWith(
            saveStatus: LoadStatus.success,
            settings: saved,
            fieldErrors: const {},
          ),
        );
      }
      return true;
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            saveStatus: LoadStatus.failure,
            fieldErrors: e.fieldErrors,
            saveError: e,
          ),
        );
      }
      return false;
    }
  }
}
