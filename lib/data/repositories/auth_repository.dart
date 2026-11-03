import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../models/models.dart';

/// Result of signup / unverified login: where the code was sent.
class CodeSent {
  final String email;
  final String maskedEmail;
  final int resendAfter;
  const CodeSent({
    required this.email,
    required this.maskedEmail,
    this.resendAfter = 60,
  });

  factory CodeSent.fromJson(Map<String, dynamic> j, {String? fallbackEmail}) =>
      CodeSent(
        email: (j['email'] ?? fallbackEmail ?? '').toString(),
        maskedEmail: (j['masked_email'] ?? j['email'] ?? fallbackEmail ?? '')
            .toString(),
        resendAfter: (j['resend_after'] as num?)?.toInt() ?? 60,
      );
}

class AuthRepository {
  AuthRepository(this._api, this._tokens);
  final ApiClient _api;
  final TokenStorage _tokens;

  bool get hasSession => _tokens.hasSession;

  Future<User> _startSession(Map<String, dynamic> b) async {
    await _tokens.save(
      access: b['access'] as String,
      refresh: b['refresh'] as String?,
    );
    return User.fromJson(Map<String, dynamic>.from(b['user'] as Map));
  }

  /// Throws ApiException; `code == 'email_not_verified'` means a code was sent
  /// (see [CodeSent.fromJson] on `e.data`).
  Future<User> login(String email, String password) async => _startSession(
    await _api.post<Map<String, dynamic>>(
      'auth/login/',
      data: {'email': email, 'password': password},
      auth: false,
    ),
  );

  /// Returns null when the server signed the player in straight away,
  /// otherwise where the verification code went.
  Future<CodeSent?> register({
    required String email,
    required String password,
    required String gamertag,
    required String fullName,
    required String phone,
  }) async {
    final b = await _api.post<Map<String, dynamic>>(
      'auth/register/',
      data: {
        'email': email,
        'password': password,
        'gamertag': gamertag,
        'full_name': fullName,
        'phone': phone,
      },
      auth: false,
    );
    if (b['access'] != null) {
      await _startSession(b);
      return null;
    }
    return CodeSent.fromJson(b, fallbackEmail: email);
  }

  Future<User> verifyEmail(String email, String code) async => _startSession(
    await _api.post<Map<String, dynamic>>(
      'auth/email/verify/',
      data: {'email': email, 'code': code},
      auth: false,
    ),
  );

  Future<void> resendVerification(String email) => _api.post<dynamic>(
    'auth/email/resend/',
    data: {'email': email, 'purpose': 'verify'},
    auth: false,
  );

  Future<CodeSent> forgotPassword(String email) async => CodeSent.fromJson(
    await _api.post<Map<String, dynamic>>(
      'auth/password/forgot/',
      data: {'email': email},
      auth: false,
    ),
    fallbackEmail: email,
  );

  Future<void> resetPassword(String email, String code, String newPassword) =>
      _api.post<dynamic>(
        'auth/password/reset/',
        data: {'email': email, 'code': code, 'new_password': newPassword},
        auth: false,
      );

  Future<User> me() async =>
      User.fromJson(await _api.get<Map<String, dynamic>>('me/'));

  Future<User> updateMe({
    String? gamertag,
    String? fullName,
    String? phone,
  }) async => User.fromJson(
    await _api.patch<Map<String, dynamic>>(
      'me/',
      data: {'gamertag': ?gamertag, 'full_name': ?fullName, 'phone': ?phone},
    ),
  );

  Future<void> logout() => _tokens.clear();
}
