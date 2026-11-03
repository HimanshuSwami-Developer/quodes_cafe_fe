import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/models.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/booking_repository.dart';
import '../../features/admin/bookings/view/admin_booking_detail_page.dart';
import '../../features/admin/bookings/view/admin_bookings_page.dart';
import '../../features/admin/dashboard/view/admin_dashboard_page.dart';
import '../../features/admin/faqs/view/admin_faqs_page.dart';
import '../../features/admin/games/view/admin_games_page.dart';
import '../../features/admin/login/view/admin_login_page.dart';
import '../../features/admin/players/view/admin_players_page.dart';
import '../../features/admin/policies/view/admin_policies_page.dart';
import '../../features/admin/settings/view/admin_settings_page.dart';
import '../../features/admin/shell/admin_shell.dart';
import '../../features/admin/stations/view/admin_stations_page.dart';
import '../../features/admin/tickets/view/admin_tickets_page.dart';
import '../../features/admin/verify/view/admin_verify_page.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/view/forgot_password_page.dart';
import '../../features/auth/view/login_page.dart';
import '../../features/auth/view/register_page.dart';
import '../../features/auth/view/reset_password_page.dart';
import '../../features/auth/view/splash_page.dart';
import '../../features/auth/view/verify_email_page.dart';
import '../../features/booking/bloc/booking_cubit.dart';
import '../../features/booking/view/approved_page.dart';
import '../../features/booking/view/hold_page.dart';
import '../../features/booking/view/human_pending_page.dart';
import '../../features/booking/view/pay_page.dart';
import '../../features/booking/view/slot_released_page.dart';
import '../../features/booking/view/upload_page.dart';
import '../../features/booking/view/verify_failed_page.dart';
import '../../features/booking/view/verifying_page.dart';
import '../../features/booking_flow/view/availability_page.dart';
import '../../features/booking_flow/view/slots_page.dart';
import '../../features/booking_flow/view/station_page.dart';
import '../../features/games/view/games_page.dart';
import '../../features/help/view/help_page.dart';
import '../../features/policies/view/policies_page.dart';
import '../../features/profile/view/profile_page.dart';
import '../../features/shell/app_shell.dart';
import '../../features/support/view/support_page.dart';
import 'go_router_refresh_stream.dart';
import 'routes.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter buildRouter(AuthBloc auth) => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: Routes.splash,
  refreshListenable: GoRouterRefreshStream(auth.stream),
  debugLogDiagnostics: false,
  redirect: (context, state) =>
      authRedirect(auth.state, state.matchedLocation, state.uri.toString()),
  routes: [
    GoRoute(path: Routes.splash, builder: (_, _) => const SplashPage()),

    // ---- Public ----
    GoRoute(
      path: Routes.login,
      builder: (_, s) =>
          LoginPage(expired: s.uri.queryParameters['expired'] == '1'),
    ),
    GoRoute(path: Routes.register, builder: (_, _) => const RegisterPage()),
    GoRoute(
      path: Routes.verifyEmail,
      builder: (_, s) => VerifyEmailPage(sent: _codeSent(s)),
    ),
    GoRoute(
      path: Routes.forgotPassword,
      builder: (_, _) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: Routes.resetPassword,
      builder: (_, s) => ResetPasswordPage(sent: _codeSent(s)),
    ),
    GoRoute(path: Routes.policies, builder: (_, _) => const PoliciesPage()),

    // ---- Tabs ----
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: Routes.games, builder: (_, _) => const GamesPage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: Routes.help, builder: (_, _) => const HelpPage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.support,
              builder: (_, s) => SupportPage(
                topic: s.uri.queryParameters['topic'],
                bookingCode: s.uri.queryParameters['booking'],
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.profile,
              builder: (_, _) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),

    // ---- Booking flow (full screen, over the tabs) ----
    GoRoute(path: Routes.station, builder: (_, _) => const StationPage()),
    GoRoute(
      path: Routes.availability,
      builder: (_, _) => const AvailabilityPage(),
    ),
    GoRoute(path: Routes.slots, builder: (_, _) => const SlotsPage()),

    // ---- One booking ----
    GoRoute(
      path: Routes.bookingStep,
      redirect: (_, s) {
        final ok =
            int.tryParse(s.pathParameters['id'] ?? '') != null &&
            BookingStep.values.any((e) => e.name == s.pathParameters['step']);
        return ok ? null : Routes.games;
      },
      pageBuilder: (context, s) {
        final id = int.parse(s.pathParameters['id']!);
        final step = BookingStep.values.byName(s.pathParameters['step']!);
        final extra = s.extra is Booking ? s.extra as Booking : null;
        return MaterialPage(
          key: ValueKey('booking-$id-${step.name}'),
          child: BlocProvider(
            create: (ctx) => BookingCubit(
              ctx.read<BookingRepository>(),
              bookingId: id,
              initial: extra?.id == id ? extra : null,
              pollEvery: switch (step) {
                BookingStep.verifying => const Duration(seconds: 2),
                BookingStep.pending => const Duration(seconds: 15),
                _ => null,
              },
            ),
            child: _bookingPage(step),
          ),
        );
      },
    ),

    // ---- Staff admin panel (web) ----
    GoRoute(
      path: Routes.adminLogin,
      pageBuilder: (_, s) => NoTransitionPage(
        child: AdminLoginPage(
          from: s.uri.queryParameters['from'],
          denied: s.uri.queryParameters['denied'] == '1',
        ),
      ),
    ),
    ShellRoute(
      builder: (_, s, child) => AdminShell(location: s.uri.path, child: child),
      routes: [
        _admin(Routes.admin, (_) => const AdminDashboardPage()),
        _admin(Routes.adminVerify, (_) => const AdminVerifyPage()),
        _admin(Routes.adminBookings, (_) => const AdminBookingsPage()),
        GoRoute(
          path: Routes.adminBooking,
          redirect: (_, s) => int.tryParse(s.pathParameters['id'] ?? '') == null
              ? Routes.adminBookings
              : null,
          pageBuilder: (_, s) {
            final id = int.parse(s.pathParameters['id']!);
            return NoTransitionPage(
              key: ValueKey('admin-booking-$id'),
              child: AdminBookingDetailPage(id: id),
            );
          },
        ),
        _admin(Routes.adminTickets, (_) => const AdminTicketsPage()),
        _admin(Routes.adminGames, (_) => const AdminGamesPage()),
        _admin(Routes.adminStations, (_) => const AdminStationsPage()),
        _admin(Routes.adminPlayers, (_) => const AdminPlayersPage()),
        _admin(Routes.adminFaqs, (_) => const AdminFaqsPage()),
        _admin(Routes.adminPolicies, (_) => const AdminPoliciesPage()),
        _admin(Routes.adminSettings, (_) => const AdminSettingsPage()),
      ],
    ),
  ],
  errorBuilder: (_, _) => const GamesPage(),
);

/// Admin pages swap instantly (web feel, no slide transition).
GoRoute _admin(String path, Widget Function(GoRouterState s) page) => GoRoute(
  path: path,
  pageBuilder: (_, s) => NoTransitionPage(key: s.pageKey, child: page(s)),
);

Widget _bookingPage(BookingStep step) => switch (step) {
  BookingStep.hold => const HoldPage(),
  BookingStep.pay => const PayPage(),
  BookingStep.upload => const UploadPage(),
  BookingStep.verifying => const VerifyingPage(),
  BookingStep.pending => const HumanPendingPage(),
  BookingStep.approved => const ApprovedPage(),
  BookingStep.failed => const VerifyFailedPage(),
  BookingStep.released => const SlotReleasedPage(),
};

CodeSent _codeSent(GoRouterState s) {
  if (s.extra is CodeSent) return s.extra as CodeSent;
  final email = s.uri.queryParameters['email'] ?? '';
  return CodeSent(email: email, maskedEmail: email);
}

/// Pure so it can be unit-tested. [location] is the matched path,
/// [fullUri] the path + query the user asked for (kept across login).
String? authRedirect(AuthState auth, String location, String fullUri) {
  final from = Uri.encodeQueryComponent(fullUri);

  // ---- Staff admin panel ----
  if (Routes.isAdmin(location)) {
    final staff = auth.user?.isStaff ?? false;
    switch (auth.status) {
      case AuthStatus.unknown:
        return '${Routes.splash}?from=$from';
      case AuthStatus.unauthenticated:
        if (location == Routes.adminLogin) return null;
        return '${Routes.adminLogin}?from=$from';
      case AuthStatus.authenticated:
        if (location == Routes.adminLogin) {
          // A player who logged in here is told they're not staff.
          return staff ? _adminTarget(fullUri) : null;
        }
        return staff ? null : '${Routes.adminLogin}?denied=1';
    }
  }

  // ---- Player app ----
  switch (auth.status) {
    case AuthStatus.unknown:
      return location == Routes.splash ? null : '${Routes.splash}?from=$from';
    case AuthStatus.unauthenticated:
      if (Routes.publicPaths.contains(location)) return null;
      final target = _fromParam(fullUri);
      if (target != null && Routes.isAdmin(target)) {
        return '${Routes.adminLogin}?from=${Uri.encodeQueryComponent(target)}';
      }
      return auth.sessionExpired ? '${Routes.login}?expired=1' : Routes.login;
    case AuthStatus.authenticated:
      if (location == Routes.splash) {
        // Resume where the user was heading before the session check.
        return _fromParam(fullUri) ?? Routes.games;
      }
      return Routes.authOnlyEntry.contains(location) ? Routes.games : null;
  }
}

String? _fromParam(String fullUri) {
  final f = Uri.tryParse(fullUri)?.queryParameters['from'];
  return (f == null || f.isEmpty || !f.startsWith('/')) ? null : f;
}

/// After admin login: the page they asked for, else the dashboard.
String _adminTarget(String fullUri) {
  final f = _fromParam(fullUri);
  return (f != null && Routes.isAdmin(f) && f != Routes.adminLogin)
      ? f
      : Routes.admin;
}

/// Navigation helpers so screens never build paths by hand.
extension AppNavigation on BuildContext {
  /// Go to the screen matching [b]'s status, replacing the current booking
  /// screen. Terminal statuses show a message and return to games.
  void goBooking(Booking b, {BookingStep? step}) {
    final target = step ?? b.defaultStep;
    if (target == null) {
      ScaffoldMessenger.maybeOf(this)?.showSnackBar(
        SnackBar(
          content: Text(
            '${b.code}: ${b.statusLabel.isEmpty ? b.status : b.statusLabel}',
          ),
        ),
      );
      go(Routes.games);
      return;
    }
    go(Routes.booking(b.id, target), extra: b);
  }

  /// Push a booking step on top (keeps back navigation), e.g. Hold → Pay.
  void pushBooking(Booking b, BookingStep step) =>
      push(Routes.booking(b.id, step), extra: b);

  void goSupport({String? topic, String? bookingCode}) => go(
    Uri(
      path: Routes.support,
      queryParameters: {'topic': ?topic, 'booking': ?bookingCode},
    ).toString(),
  );
}

/// Kept for screens that need the auth repo during navigation.
AuthRepository authRepo(BuildContext c) => c.read<AuthRepository>();
