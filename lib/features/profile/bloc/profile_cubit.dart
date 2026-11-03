import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/load_status.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/booking_repository.dart';

class ProfileState extends Equatable {
  const ProfileState({
    this.status = LoadStatus.initial,
    this.activeBookings,
    this.saveStatus = LoadStatus.initial,
    this.error,
  });

  final LoadStatus status;

  /// Null until loaded. The user itself lives in the AuthBloc.
  final List<Booking>? activeBookings;
  final LoadStatus saveStatus;
  final ApiException? error;

  ProfileState copyWith({
    LoadStatus? status,
    List<Booking>? activeBookings,
    LoadStatus? saveStatus,
    ApiException? error,
  }) => ProfileState(
    status: status ?? this.status,
    activeBookings: activeBookings ?? this.activeBookings,
    saveStatus: saveStatus ?? this.saveStatus,
    error: error,
  );

  @override
  List<Object?> get props => [
    status,
    activeBookings?.map((b) => '${b.id}:${b.status}').toList(),
    saveStatus,
    error,
  ];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._auth, this._bookings) : super(const ProfileState());

  final AuthRepository _auth;
  final BookingRepository _bookings;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final list = await _bookings.mine(activeOnly: true);
      if (!isClosed) {
        emit(state.copyWith(status: LoadStatus.success, activeBookings: list));
      }
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(status: LoadStatus.failure, error: e));
    }
  }

  /// On success the view asks the AuthBloc to refresh the signed-in user.
  Future<void> updateMe({
    required String gamertag,
    required String fullName,
    required String phone,
  }) async {
    if (state.saveStatus.isLoading) return;
    emit(state.copyWith(saveStatus: LoadStatus.loading));
    try {
      await _auth.updateMe(
        gamertag: gamertag.trim(),
        fullName: fullName.trim(),
        phone: phone.trim(),
      );
      if (!isClosed) emit(state.copyWith(saveStatus: LoadStatus.success));
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(state.copyWith(saveStatus: LoadStatus.failure, error: e));
      }
    }
  }
}
