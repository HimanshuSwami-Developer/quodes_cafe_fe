import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/load_status.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/support_repository.dart';

class HelpState extends Equatable {
  const HelpState({
    this.status = LoadStatus.initial,
    this.faqs,
    this.query = '',
    this.openId,
    this.error,
  });

  final LoadStatus status;
  final List<Faq>? faqs;
  final String query;

  /// The expanded FAQ (accordion: at most one open).
  final int? openId;
  final ApiException? error;

  /// FAQs matching [query] in the question or answer.
  List<Faq> get visible {
    final q = query.toLowerCase();
    return (faqs ?? const <Faq>[])
        .where(
          (f) =>
              q.isEmpty ||
              f.question.toLowerCase().contains(q) ||
              f.answer.toLowerCase().contains(q),
        )
        .toList();
  }

  HelpState copyWith({
    LoadStatus? status,
    List<Faq>? faqs,
    String? query,
    int? Function()? openId,
    ApiException? error,
  }) => HelpState(
    status: status ?? this.status,
    faqs: faqs ?? this.faqs,
    query: query ?? this.query,
    openId: openId != null ? openId() : this.openId,
    error: error,
  );

  @override
  List<Object?> get props => [status, faqs?.length, query, openId, error];
}

class HelpCubit extends Cubit<HelpState> {
  HelpCubit(this._support) : super(const HelpState());
  final SupportRepository _support;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final f = await _support.faqs();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: LoadStatus.success,
          faqs: f,
          // First question starts open, as in the design.
          openId: () => state.openId ?? f.firstOrNull?.id,
        ),
      );
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(status: LoadStatus.failure, error: e));
    }
  }

  void search(String q) => emit(state.copyWith(query: q));

  void toggle(int faqId) =>
      emit(state.copyWith(openId: () => state.openId == faqId ? null : faqId));
}
