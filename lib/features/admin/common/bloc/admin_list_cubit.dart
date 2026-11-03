import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/network/api_exception.dart';

/// State of an admin list page: the rows plus load / action errors.
class AdminListState<T> extends Equatable {
  /// Creates a list state; [items] stays null until the first load.
  const AdminListState({
    this.status = LoadStatus.initial,
    this.items,
    this.error,
    this.actionError,
    this.busyIds = const {},
    this.seq = 0,
  });

  final LoadStatus status;

  /// Null until the first load (keeps the table during refreshes).
  final List<T>? items;

  /// Why the list failed to load (shown as an error view with Retry).
  final ApiException? error;

  /// Why a row action (delete, toggle) failed (shown as a toast).
  final ApiException? actionError;

  /// Rows with a request in flight.
  final Set<int> busyIds;

  /// Bumped on every action error so the same message toasts twice.
  final int seq;

  AdminListState<T> copyWith({
    LoadStatus? status,
    List<T>? items,
    ApiException? error,
    ApiException? actionError,
    Set<int>? busyIds,
    int? seq,
  }) => AdminListState<T>(
    status: status ?? this.status,
    items: items ?? this.items,
    error: error,
    actionError: actionError,
    busyIds: busyIds ?? this.busyIds,
    seq: seq ?? this.seq,
  );

  @override
  List<Object?> get props => [status, items, error, actionError, busyIds, seq];
}

/// Base for admin list pages: load, upsert after a form save, and row
/// actions with error reporting. Subclasses supply [fetch] and [idOf].
abstract class AdminListCubit<T> extends Cubit<AdminListState<T>> {
  /// Starts empty; call [load].
  AdminListCubit() : super(AdminListState<T>());

  /// Loads the rows from the API.
  Future<List<T>> fetch();

  /// Stable id of a row.
  int idOf(T item);

  /// Optional client-side ordering applied after every change.
  List<T> sort(List<T> items) => items;

  int _request = 0;

  /// Loads the list. [silent] keeps the current rows on screen (no spinner).
  Future<void> load({bool silent = false}) async {
    final id = ++_request;
    if (!silent || state.items == null) {
      emit(state.copyWith(status: LoadStatus.loading));
    }
    try {
      final items = await fetch();
      if (isClosed || id != _request) return;
      emit(state.copyWith(status: LoadStatus.success, items: sort(items)));
    } on ApiException catch (e) {
      if (isClosed || id != _request) return;
      // A failed background refresh keeps the rows already shown.
      if (silent && state.items != null) {
        emit(state.copyWith(actionError: e, seq: state.seq + 1));
      } else {
        emit(state.copyWith(status: LoadStatus.failure, error: e));
      }
    }
  }

  /// Replaces the row with [item]'s id, or appends it.
  void upsert(T item) {
    final list = [...?state.items];
    final i = list.indexWhere((e) => idOf(e) == idOf(item));
    i < 0 ? list.add(item) : list[i] = item;
    emit(state.copyWith(items: sort(list)));
  }

  /// Runs [call] for row [item]; on success [onDone] maps the list
  /// (default: drop the row). Returns false (and reports) on error.
  Future<bool> act(
    T item,
    Future<void> Function() call, {
    List<T> Function(List<T> items)? onDone,
  }) async {
    final id = idOf(item);
    if (state.busyIds.contains(id)) return false;
    emit(state.copyWith(busyIds: {...state.busyIds, id}));
    try {
      await call();
      if (isClosed) return true;
      final items = [...?state.items];
      emit(
        state.copyWith(
          items: sort(
            onDone != null
                ? onDone(items)
                : items.where((e) => idOf(e) != id).toList(),
          ),
          busyIds: {...state.busyIds}..remove(id),
        ),
      );
      return true;
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            actionError: e,
            seq: state.seq + 1,
            busyIds: {...state.busyIds}..remove(id),
          ),
        );
      }
      return false;
    }
  }
}
