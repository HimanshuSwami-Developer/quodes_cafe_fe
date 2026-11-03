import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quodes_gaming/data/models/admin_models.dart';
import 'package:quodes_gaming/data/repositories/admin_repository.dart';
import 'package:quodes_gaming/features/admin/shell/admin_shell.dart';
import 'package:quodes_gaming/features/auth/bloc/auth_bloc.dart';
import 'package:quodes_gaming/theme/theme.dart';

import '../../helpers/admin_fixtures.dart';
import '../../helpers/fixtures.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAdminRepository repo;
  late MockAuthBloc auth;

  setUp(() {
    repo = MockAdminRepository();
    auth = MockAuthBloc();
    when(
      () => auth.state,
    ).thenReturn(AuthState.authenticated(user(staff: true)));
    when(() => repo.dashboard()).thenAnswer(
      (_) async =>
          AdminDashboard.fromJson(dashboardJson(toVerify: 3, openTickets: 2)),
    );
  });

  Future<void> pumpShell(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepositoryProvider<AdminRepository>.value(
        value: repo,
        child: BlocProvider<AuthBloc>.value(
          value: auth,
          child: MaterialApp(
            theme: buildTheme(),
            home: const AdminShell(
              location: '/admin/verify',
              child: Center(child: Text('PAGE')),
            ),
          ),
        ),
      ),
    );
    await tester.pump(); // dashboard KPIs arrive
  }

  testWidgets('at 1280px the sidebar shows every nav item with badges', (
    tester,
  ) async {
    await pumpShell(tester, const Size(1280, 800));

    for (final item in adminNavItems) {
      expect(find.text(item.label), findsOneWidget, reason: item.label);
    }
    expect(find.text('PAGE'), findsOneWidget);
    expect(find.text('player@email.com'), findsOneWidget);
    expect(find.byTooltip('Log out'), findsOneWidget);
    expect(find.byType(Drawer), findsNothing);
    // Live badges from the dashboard KPIs.
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('log out dispatches AuthLogoutRequested', (tester) async {
    await pumpShell(tester, const Size(1280, 800));
    await tester.tap(find.byTooltip('Log out'));
    verify(() => auth.add(const AuthLogoutRequested())).called(1);
  });

  testWidgets('below 1000px the nav moves into a drawer', (tester) async {
    await pumpShell(tester, const Size(800, 900));

    expect(find.text('Bookings'), findsNothing);
    expect(find.text('Verify payments'), findsOneWidget); // AppBar title
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('Bookings'), findsOneWidget);
  });
}
