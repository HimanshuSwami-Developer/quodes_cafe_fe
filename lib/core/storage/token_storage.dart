import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// JWT pair in the platform keychain/keystore, cached in memory so the auth
/// interceptor never hits secure storage on the hot path.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _kAccess = 'auth.access';
  static const _kRefresh = 'auth.refresh';

  String? _access;
  String? _refresh;

  String? get access => _access;
  String? get refresh => _refresh;
  bool get hasSession => _access != null;

  Future<void> load() async {
    _access = await _storage.read(key: _kAccess);
    _refresh = await _storage.read(key: _kRefresh);
  }

  Future<void> save({required String access, String? refresh}) async {
    _access = access;
    await _storage.write(key: _kAccess, value: access);
    if (refresh != null) {
      _refresh = refresh;
      await _storage.write(key: _kRefresh, value: refresh);
    }
  }

  Future<void> clear() async {
    _access = null;
    _refresh = null;
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}
