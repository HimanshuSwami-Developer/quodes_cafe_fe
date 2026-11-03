import '../core/config/env.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../data/repositories/admin_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/booking_repository.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/support_repository.dart';
import '../features/auth/bloc/auth_bloc.dart';

/// Composition root: everything the app needs, wired once in bootstrap.
/// Swap pieces here (or pass fakes) in tests.
class AppDependencies {
  AppDependencies._({
    required this.config,
    required this.tokens,
    required this.api,
    required this.authRepository,
    required this.catalogRepository,
    required this.bookingRepository,
    required this.supportRepository,
    required this.adminRepository,
    required this.authBloc,
  });

  final AppConfig config;
  final TokenStorage tokens;
  final ApiClient api;
  final AuthRepository authRepository;
  final CatalogRepository catalogRepository;
  final BookingRepository bookingRepository;
  final SupportRepository supportRepository;

  /// Staff API for the /admin web panel.
  final AdminRepository adminRepository;
  final AuthBloc authBloc;

  static Future<AppDependencies> create(
    AppConfig config, {
    TokenStorage? tokens,
  }) async {
    final store = tokens ?? TokenStorage();
    await store.load();

    // The interceptor needs to tell the AuthBloc about a dead session, and the
    // AuthBloc needs the repository built on that client: break the cycle
    // with a late reference.
    late final AuthBloc authBloc;
    final api = ApiClient(
      config: config,
      tokens: store,
      onSessionExpired: () => authBloc.add(const AuthSessionExpired()),
    );
    final authRepo = AuthRepository(api, store);
    authBloc = AuthBloc(authRepo)..add(const AuthStarted());

    return AppDependencies._(
      config: config,
      tokens: store,
      api: api,
      authRepository: authRepo,
      catalogRepository: CatalogRepository(api),
      bookingRepository: BookingRepository(api),
      supportRepository: SupportRepository(api),
      adminRepository: AdminRepository(api),
      authBloc: authBloc,
    );
  }
}
