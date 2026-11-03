import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/admin_models.dart';
import '../../../../data/repositories/admin_repository.dart';

/// Support tickets of one tab, plus per-ticket save progress.
class AdminTicketsState extends Equatable {
  /// Starts on the Open tab.
  const AdminTicketsState({
    this.tab = 'open',
    this.status = LoadStatus.initial,
    this.items,
    this.error,
    this.savingIds = const {},
    this.fieldErrors = const {},
    this.saved,
    this.saveError,
    this.seq = 0,
  });

  /// One of [ticketStatuses].
  final String tab;
  final LoadStatus status;

  /// Null until the first load of the tab.
  final List<AdminTicket>? items;
  final ApiException? error;

  /// Tickets with a PATCH in flight.
  final Set<int> savingIds;

  /// Server field errors per ticket id.
  final Map<int, Map<String, String>> fieldErrors;

  /// Last ticket saved (for the toast).
  final AdminTicket? saved;

  /// Last save failure (for the toast).
  final ApiException? saveError;

  /// Bumped on every save result so the listener fires each time.
  final int seq;

  AdminTicketsState copyWith({
    String? tab,
    LoadStatus? status,
    List<AdminTicket>? Function()? items,
    ApiException? error,
    Set<int>? savingIds,
    Map<int, Map<String, String>>? fieldErrors,
    AdminTicket? saved,
    ApiException? saveError,
    int? seq,
  }) => AdminTicketsState(
    tab: tab ?? this.tab,
    status: status ?? this.status,
    items: items != null ? items() : this.items,
    error: error,
    savingIds: savingIds ?? this.savingIds,
    fieldErrors: fieldErrors ?? this.fieldErrors,
    saved: saved,
    saveError: saveError,
    seq: seq ?? this.seq,
  );

  @override
  List<Object?> get props => [
    tab,
    status,
    items,
    error,
    savingIds,
    fieldErrors,
    saved,
    saveError,
    seq,
  ];
}

/// Lists tickets by status tab and saves staff replies / status changes.
class AdminTicketsCubit extends Cubit<AdminTicketsState> {
  /// Creates the cubit; call [load].
  AdminTicketsCubit(this._repo) : super(const AdminTicketsState());

  final AdminRepository _repo;
  int _request = 0;

  /// Loads the current tab.
  Future<void> load() async {
    final id = ++_request;
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final items = await _repo.tickets(status: state.tab);
      if (isClosed || id != _request) return;
      emit(state.copyWith(status: LoadStatus.success, items: () => items));
    } on ApiException catch (e) {
      if (!isClosed && id == _request) {
        emit(state.copyWith(status: LoadStatus.failure, error: e));
      }
    }
  }

  /// Switches tab and loads it.
  void selectTab(String tab) {
    if (tab == state.tab) return;
    emit(state.copyWith(tab: tab, items: () => null, fieldErrors: const {}));
    load();
  }

  /// Whether a ticket with [status] belongs on [tab].
  static bool belongs(String tab, String status) =>
      tab == 'open' ? status != 'resolved' : status == tab;

  /// PATCHes [t]'s status and reply. Returns true on success.
  Future<bool> save(
    AdminTicket t, {
    required String status,
    required String reply,
  }) async {
    if (state.savingIds.contains(t.id)) return false;
    emit(
      state.copyWith(
        savingIds: {...state.savingIds, t.id},
        fieldErrors: {...state.fieldErrors}..remove(t.id),
      ),
    );
    try {
      final updated = await _repo.updateTicket(
        t.id,
        status: status,
        staffReply: reply,
      );
      if (isClosed) return true;
      final items = [
        for (final e in state.items ?? const <AdminTicket>[])
          if (e.id != t.id)
            e
          else if (belongs(state.tab, updated.status))
            updated,
      ];
      emit(
        state.copyWith(
          items: () => items,
          savingIds: {...state.savingIds}..remove(t.id),
          saved: updated,
          seq: state.seq + 1,
        ),
      );
      return true;
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            savingIds: {...state.savingIds}..remove(t.id),
            fieldErrors: {...state.fieldErrors, t.id: e.fieldErrors},
            saveError: e,
            seq: state.seq + 1,
          ),
        );
      }
      return false;
    }
  }
}
