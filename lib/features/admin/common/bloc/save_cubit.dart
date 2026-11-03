import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/network/api_exception.dart';

/// State of an admin form: submit status, server field errors, result.
class SaveState<T> extends Equatable {
  /// Creates a form state (idle by default).
  const SaveState({
    this.status = LoadStatus.initial,
    this.saved,
    this.fieldErrors = const {},
    this.error,
  });

  final LoadStatus status;

  /// What the server returned on success.
  final T? saved;

  /// `field → message` from DRF, shown under each input.
  final Map<String, String> fieldErrors;

  /// The failure; its message is shown when no field claims it.
  final ApiException? error;

  /// Error for a field (`null` when the field is fine).
  String? errorFor(String field) => fieldErrors[field];

  /// A message no input shows (`detail`, `non_field_errors`, unknown keys).
  String? formMessage(Iterable<String> shownFields) {
    final e = error;
    if (e == null) return null;
    final hidden = fieldErrors.keys.where((k) => !shownFields.contains(k));
    if (fieldErrors.isEmpty) return e.message;
    if (hidden.isNotEmpty) return fieldErrors[hidden.first];
    return null;
  }

  @override
  List<Object?> get props => [status, saved, fieldErrors, error];
}

/// Base for admin forms. [run] performs the save and captures server
/// validation errors; subclasses expose typed `save(...)` methods.
class SaveCubit<T> extends Cubit<SaveState<T>> {
  /// Starts idle.
  SaveCubit() : super(SaveState<T>());

  /// Runs [op]; returns the saved value or null on failure.
  Future<T?> run(Future<T> Function() op) async {
    if (state.status.isLoading) return null;
    emit(SaveState<T>(status: LoadStatus.loading));
    try {
      final saved = await op();
      if (!isClosed) {
        emit(SaveState<T>(status: LoadStatus.success, saved: saved));
      }
      return saved;
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(
          SaveState<T>(
            status: LoadStatus.failure,
            fieldErrors: e.fieldErrors,
            error: e,
          ),
        );
      }
      return null;
    }
  }

  /// Client-side validation failure (no request is sent).
  void invalid(Map<String, String> errors) => emit(
    SaveState<T>(
      status: LoadStatus.failure,
      fieldErrors: errors,
      error: ApiException(ApiErrorType.validation, errors.values.first),
    ),
  );
}
