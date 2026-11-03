import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/load_status.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/support_repository.dart';

class SupportState extends Equatable {
  const SupportState({
    this.status = LoadStatus.initial,
    this.cafe,
    this.tickets,
    this.topic = 'Payment',
    this.attachment,
    this.submitStatus = LoadStatus.initial,
    this.created,
    this.error,
  });

  static const topics = [
    'Payment',
    'Reschedule',
    'Refund',
    'Station issue',
    'Other',
  ];

  final LoadStatus status;
  final Cafe? cafe;
  final List<Ticket>? tickets;
  final String topic;
  final XFile? attachment;
  final LoadStatus submitStatus;

  /// The ticket just raised (for the confirmation toast).
  final Ticket? created;
  final ApiException? error;

  SupportState copyWith({
    LoadStatus? status,
    Cafe? cafe,
    List<Ticket>? tickets,
    String? topic,
    XFile? Function()? attachment,
    LoadStatus? submitStatus,
    Ticket? created,
    ApiException? error,
  }) => SupportState(
    status: status ?? this.status,
    cafe: cafe ?? this.cafe,
    tickets: tickets ?? this.tickets,
    topic: topic ?? this.topic,
    attachment: attachment != null ? attachment() : this.attachment,
    submitStatus: submitStatus ?? this.submitStatus,
    created: created ?? this.created,
    error: error,
  );

  @override
  List<Object?> get props => [
    status,
    cafe?.supportPhone,
    tickets?.map((t) => '${t.id}:${t.status}').toList(),
    topic,
    attachment?.path,
    submitStatus,
    created?.id,
    error,
  ];
}

class SupportCubit extends Cubit<SupportState> {
  SupportCubit(this._catalog, this._support, {String? topic})
    : super(SupportState(topic: _validTopic(topic) ?? 'Payment'));

  final CatalogRepository _catalog;
  final SupportRepository _support;

  static String? _validTopic(String? t) =>
      SupportState.topics.contains(t) ? t : null;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final r = await Future.wait([_catalog.cafe(), _support.tickets()]);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: LoadStatus.success,
          cafe: r[0] as Cafe,
          tickets: r[1] as List<Ticket>,
        ),
      );
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: LoadStatus.failure,
            tickets: state.tickets ?? const [],
            error: e,
          ),
        );
      }
    }
  }

  /// Deep link from another screen (e.g. "Request refund").
  void prefill({String? topic}) {
    final t = _validTopic(topic);
    if (t != null) emit(state.copyWith(topic: t));
  }

  void selectTopic(String t) => emit(state.copyWith(topic: t));

  void setAttachment(XFile? f) => emit(state.copyWith(attachment: () => f));

  /// Returns true when the ticket was created (the view clears its fields).
  Future<bool> submit({
    required String message,
    String bookingCode = '',
  }) async {
    if (state.submitStatus.isLoading) return false;
    if (message.trim().isEmpty) {
      emit(
        state.copyWith(
          submitStatus: LoadStatus.failure,
          error: const ApiException(
            ApiErrorType.validation,
            'Tell us what happened',
          ),
        ),
      );
      return false;
    }
    emit(state.copyWith(submitStatus: LoadStatus.loading));
    try {
      final t = await _support.createTicket(
        topic: state.topic,
        message: message.trim(),
        bookingCode: bookingCode.trim(),
        attachment: state.attachment,
      );
      if (isClosed) return true;
      emit(
        state.copyWith(
          submitStatus: LoadStatus.success,
          tickets: [t, ...?state.tickets],
          attachment: () => null,
          created: t,
        ),
      );
      return true;
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(state.copyWith(submitStatus: LoadStatus.failure, error: e));
      }
      return false;
    }
  }
}
