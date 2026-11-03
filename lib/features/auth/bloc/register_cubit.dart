import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/load_status.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/auth_repository.dart';

class RegisterState extends Equatable {
  const RegisterState({
    this.status = LoadStatus.initial,
    this.codeSent,
    this.user,
    this.error,
    this.fieldErrors = const {},
  });

  final LoadStatus status;

  /// Success with email verification pending.
  final CodeSent? codeSent;

  /// Success with an immediate session.
  final User? user;
  final String? error;
  final Map<String, String> fieldErrors;

  @override
  List<Object?> get props => [
    status,
    codeSent?.email,
    user?.id,
    error,
    fieldErrors,
  ];
}

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit(this._auth) : super(const RegisterState());
  final AuthRepository _auth;

  Future<void> submit({
    required String gamertag,
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (state.status.isLoading) return;
    if ([gamertag, fullName, email, password].any((v) => v.trim().isEmpty)) {
      return emit(
        const RegisterState(
          status: LoadStatus.failure,
          error: 'Fill in gamertag, name, email and password',
        ),
      );
    }
    if (!Validators.isEmail(email)) {
      return emit(
        const RegisterState(
          status: LoadStatus.failure,
          error: 'That email doesn’t look right',
          fieldErrors: {'email': 'Enter a valid email'},
        ),
      );
    }
    emit(const RegisterState(status: LoadStatus.loading));
    try {
      final sent = await _auth.register(
        email: email.trim(),
        password: password,
        gamertag: gamertag.trim(),
        fullName: fullName.trim(),
        phone: phone.trim(),
      );
      if (sent != null) {
        emit(RegisterState(status: LoadStatus.success, codeSent: sent));
      } else {
        emit(RegisterState(status: LoadStatus.success, user: await _auth.me()));
      }
    } on ApiException catch (e) {
      emit(
        RegisterState(
          status: LoadStatus.failure,
          error: e.message,
          fieldErrors: e.fieldErrors,
        ),
      );
    }
  }
}
