import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/load_status.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/support_repository.dart';

class PoliciesState extends Equatable {
  const PoliciesState({
    this.status = LoadStatus.initial,
    this.policies,
    this.tab = 0,
    this.error,
  });

  final LoadStatus status;
  final List<Policy>? policies;
  final int tab;
  final ApiException? error;

  PoliciesState copyWith({
    LoadStatus? status,
    List<Policy>? policies,
    int? tab,
    ApiException? error,
  }) => PoliciesState(
    status: status ?? this.status,
    policies: policies ?? this.policies,
    tab: tab ?? this.tab,
    error: error,
  );

  @override
  List<Object?> get props => [status, policies?.length, tab, error];
}

class PoliciesCubit extends Cubit<PoliciesState> {
  PoliciesCubit(this._support) : super(const PoliciesState());
  final SupportRepository _support;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final p = await _support.policies();
      if (!isClosed) {
        emit(state.copyWith(status: LoadStatus.success, policies: p));
      }
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(status: LoadStatus.failure, error: e));
    }
  }

  void selectTab(int i) => emit(state.copyWith(tab: i));
}
