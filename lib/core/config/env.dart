import 'package:flutter/foundation.dart' show kIsWeb;

/// Build environments, chosen at build time with `--dart-define=FLAVOR=local|stage|prod`
/// (default: local). See lib/main.dart.
enum Flavor { local, stage, prod }

class AppConfig {
  final Flavor flavor;
  final String appName;

  /// Must end with `/` (paths are resolved relative to it).
  final String apiBaseUrl;

  /// Logs requests/responses (with secrets redacted). Never on in prod.
  final bool httpLogging;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  const AppConfig({
    required this.flavor,
    required this.appName,
    required this.apiBaseUrl,
    required this.httpLogging,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 30),
  });

  bool get isProd => flavor == Flavor.prod;

  /// `API_BASE` overrides the URL for any flavor, e.g. a real phone on the LAN:
  /// `--dart-define=API_BASE=http://192.168.1.7:8000/api/`.
  static const _override = String.fromEnvironment('API_BASE');

  static AppConfig of(Flavor flavor) {
    final c = switch (flavor) {
      // Phone/emulator: your dev server's address below. Browser (admin
      // panel): the Django dev server on this machine.
      Flavor.local => AppConfig(
        flavor: Flavor.local,
        appName: 'Quodes LOCAL',
        apiBaseUrl: kIsWeb
            ? 'http://localhost:8000/api/'
            : 'http://192.168.1.7:8000/api/',
        httpLogging: true,
      ),
      Flavor.stage => const AppConfig(
        flavor: Flavor.stage,
        appName: 'Quodes STAGE',
        apiBaseUrl: 'https://stage-api.quodes.gg/api/',
        httpLogging: true,
      ),
      Flavor.prod => const AppConfig(
        flavor: Flavor.prod,
        appName: 'Quodes Gaming',
        apiBaseUrl: 'https://api.quodes.gg/api/',
        httpLogging: false,
      ),
    };
    if (_override.isEmpty) return c;
    return AppConfig(
      flavor: c.flavor,
      appName: c.appName,
      apiBaseUrl: _override.endsWith('/') ? _override : '$_override/',
      httpLogging: c.httpLogging,
      connectTimeout: c.connectTimeout,
      receiveTimeout: c.receiveTimeout,
    );
  }

  static Flavor flavorFromDefine() {
    const name = String.fromEnvironment('FLAVOR', defaultValue: 'local');
    return Flavor.values.firstWhere(
      (f) => f.name == name,
      orElse: () => Flavor.local,
    );
  }
}
