import 'package:flutter_test/flutter_test.dart';
import 'package:quodes_gaming/core/router/app_router.dart';
import 'package:quodes_gaming/core/router/routes.dart';
import 'package:quodes_gaming/features/auth/bloc/auth_bloc.dart';

import '../../helpers/fixtures.dart';

void main() {
  String? go(AuthState s, String loc) => authRedirect(s, loc, loc);

  group('authRedirect', () {
    test('unknown: everything waits on the splash', () {
      const s = AuthState.unknown();
      expect(go(s, Routes.splash), isNull);
      expect(go(s, Routes.login), '/?from=%2Flogin');
      expect(go(s, Routes.games), '/?from=%2Fgames');
      expect(go(s, '/bookings/1/hold'), '/?from=%2Fbookings%2F1%2Fhold');
    });

    test('unauthenticated: public paths open, private ones go to login', () {
      const s = AuthState.unauthenticated();
      for (final p in Routes.publicPaths) {
        expect(go(s, p), isNull, reason: p);
      }
      expect(go(s, Routes.splash), Routes.login);
      expect(go(s, Routes.games), Routes.login);
      expect(go(s, Routes.profile), Routes.login);
      expect(go(s, '/bookings/1/pay'), Routes.login);
    });

    test('unauthenticated after expiry flags the login page', () {
      const s = AuthState.unauthenticated(expired: true);
      expect(go(s, Routes.games), '${Routes.login}?expired=1');
      expect(go(s, Routes.policies), isNull);
    });

    test('authenticated: auth entry pages bounce to games', () {
      final s = AuthState.authenticated(user());
      for (final p in Routes.authOnlyEntry) {
        expect(go(s, p), Routes.games, reason: p);
      }
      expect(go(s, Routes.games), isNull);
      expect(go(s, Routes.station), isNull);
      expect(go(s, '/bookings/1/hold'), isNull);
      // Policies stay reachable when signed in.
      expect(go(s, Routes.policies), isNull);
    });
    test('authenticated at splash resumes the requested page', () {
      final s = AuthState.authenticated(user());
      expect(
        authRedirect(s, Routes.splash, '/?from=%2Fprofile'),
        Routes.profile,
      );
      expect(
        authRedirect(s, Routes.splash, '/?from=https%3A%2F%2Fevil.com'),
        Routes.games,
      );
    });
  });

  group('authRedirect /admin', () {
    final player = AuthState.authenticated(user());
    final staff = AuthState.authenticated(user(staff: true));

    test('unknown waits on splash and remembers the admin page', () {
      expect(
        go(const AuthState.unknown(), Routes.adminBookings),
        '/?from=%2Fadmin%2Fbookings',
      );
    });

    test('logged out: admin login, keeping the target', () {
      const s = AuthState.unauthenticated();
      expect(go(s, Routes.adminLogin), isNull);
      expect(go(s, Routes.adminVerify), '/admin/login?from=%2Fadmin%2Fverify');
      // Session check finished on the splash: go to ADMIN login, not player login.
      expect(
        authRedirect(s, Routes.splash, '/?from=%2Fadmin%2Fgames'),
        '/admin/login?from=%2Fadmin%2Fgames',
      );
    });

    test('players are refused', () {
      expect(go(player, Routes.admin), '/admin/login?denied=1');
      expect(go(player, Routes.adminGames), '/admin/login?denied=1');
      expect(go(player, Routes.adminLogin), isNull);
    });

    test('staff get in and login bounces to the requested page', () {
      expect(go(staff, Routes.admin), isNull);
      expect(go(staff, Routes.adminSettings), isNull);
      expect(
        authRedirect(
          staff,
          Routes.adminLogin,
          '/admin/login?from=%2Fadmin%2Ftickets',
        ),
        Routes.adminTickets,
      );
      expect(go(staff, Routes.adminLogin), Routes.admin);
    });
  });
}
