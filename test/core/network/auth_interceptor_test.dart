import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quodes_gaming/core/network/interceptors/auth_interceptor.dart';
import 'package:quodes_gaming/core/storage/token_storage.dart';

/// In-memory tokens (no platform keychain in unit tests).
class MemoryTokenStorage extends TokenStorage {
  MemoryTokenStorage({String? access, String? refresh})
    : _a = access,
      _r = refresh;
  String? _a;
  String? _r;

  @override
  String? get access => _a;
  @override
  String? get refresh => _r;
  @override
  bool get hasSession => _a != null;
  @override
  Future<void> load() async {}
  @override
  Future<void> save({required String access, String? refresh}) async {
    _a = access;
    if (refresh != null) _r = refresh;
  }

  @override
  Future<void> clear() async {
    _a = null;
    _r = null;
  }
}

/// Fake server: `me/` needs `Bearer new`; `auth/refresh/` is slow so that
/// both 401s are in flight before it completes.
class FakeServer implements HttpClientAdapter {
  FakeServer({this.refreshOk = true});
  final bool refreshOk;
  int refreshCalls = 0;
  final authHeaders = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    ResponseBody json(int status, Object body) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

    if (o.path.endsWith('auth/refresh/')) {
      refreshCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return refreshOk
          ? json(200, {'access': 'new', 'refresh': 'r2'})
          : json(401, {'detail': 'Token is invalid or expired'});
    }
    final auth = o.headers['Authorization']?.toString() ?? '';
    authHeaders.add(auth);
    return auth == 'Bearer new'
        ? json(200, {'ok': true, 'path': o.path})
        : json(401, {'detail': 'Given token not valid'});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late FakeServer server;
  late MemoryTokenStorage tokens;
  late int expired;

  Dio build({bool refreshOk = true}) {
    server = FakeServer(refreshOk: refreshOk);
    tokens = MemoryTokenStorage(access: 'old', refresh: 'r1');
    expired = 0;
    final base = BaseOptions(baseUrl: 'https://api.test/api/');
    final bare = Dio(base)..httpClientAdapter = server;
    return Dio(base)
      ..httpClientAdapter = server
      ..interceptors.add(
        AuthInterceptor(
          tokens: tokens,
          refreshClient: bare,
          onSessionExpired: () => expired++,
        ),
      );
  }

  test('two concurrent 401s share ONE refresh and both replay', () async {
    final dio = build();
    final results = await Future.wait([
      dio.get<Map<String, dynamic>>('me/'),
      dio.get<Map<String, dynamic>>('bookings/'),
    ]);

    expect(server.refreshCalls, 1);
    expect(results.map((r) => r.statusCode), [200, 200]);
    expect(results.map((r) => r.data?['path']), ['me/', 'bookings/']);
    // Two originals with the old token, two replays with the new one.
    expect(server.authHeaders.where((h) => h == 'Bearer old'), hasLength(2));
    expect(server.authHeaders.where((h) => h == 'Bearer new'), hasLength(2));
    expect(tokens.access, 'new');
    expect(tokens.refresh, 'r2');
    expect(expired, 0);
  });

  test('a later request uses the refreshed token directly', () async {
    final dio = build();
    await dio.get<dynamic>('me/');
    server.authHeaders.clear();
    await dio.get<dynamic>('games/');
    expect(server.authHeaders, ['Bearer new']);
    expect(server.refreshCalls, 1);
  });

  test('refresh rejected → session cleared and expiry fired once', () async {
    final dio = build(refreshOk: false);
    final calls = [dio.get<dynamic>('me/'), dio.get<dynamic>('bookings/')];
    for (final c in calls) {
      await expectLater(
        c,
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            401,
          ),
        ),
      );
    }
    expect(server.refreshCalls, 1);
    expect(tokens.hasSession, isFalse);
    expect(expired, 1);
  });
}
