import 'app/bootstrap.dart';
import 'core/config/env.dart';

/// The only entrypoint. Pick the environment with a flag:
///   flutter run                                   → local (default)
///   flutter run --dart-define=FLAVOR=stage
///   flutter build appbundle --dart-define=FLAVOR=prod
/// Optional: --dart-define=API_BASE=http://192.168.1.10:8000/api/ overrides the server URL.
void main() => bootstrap(AppConfig.flavorFromDefine());
