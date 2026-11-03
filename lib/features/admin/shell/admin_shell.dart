import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../data/models/admin_models.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import '../../../theme/widgets.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../common/view/admin_ui.dart';
import 'admin_badges_cubit.dart';

/// One entry of the admin navigation.
class AdminNavItem {
  /// Creates a nav entry for [path].
  const AdminNavItem(this.label, this.icon, this.path, {this.badge});
  final String label;
  final IconData icon;
  final String path;

  /// Picks this item's live count from the KPIs (null = no badge).
  final int Function(DashboardKpis k)? badge;

  /// True when [location] is this item's page (or a sub-page of it).
  bool matches(String location) => path == Routes.admin
      ? location == Routes.admin
      : location == path || location.startsWith('$path/');
}

/// Every admin page, in sidebar order.
final adminNavItems = [
  const AdminNavItem('Dashboard', Icons.space_dashboard_outlined, Routes.admin),
  AdminNavItem(
    'Verify payments',
    Icons.fact_check_outlined,
    Routes.adminVerify,
    badge: (k) => k.toVerify,
  ),
  const AdminNavItem(
    'Bookings',
    Icons.event_note_outlined,
    Routes.adminBookings,
  ),
  AdminNavItem(
    'Tickets',
    Icons.support_agent_outlined,
    Routes.adminTickets,
    badge: (k) => k.openTickets,
  ),
  const AdminNavItem('Games', Icons.sports_esports_outlined, Routes.adminGames),
  const AdminNavItem('Stations', Icons.tv_outlined, Routes.adminStations),
  const AdminNavItem('Players', Icons.people_alt_outlined, Routes.adminPlayers),
  const AdminNavItem('FAQs', Icons.quiz_outlined, Routes.adminFaqs),
  const AdminNavItem('Policies', Icons.gavel_outlined, Routes.adminPolicies),
  const AdminNavItem('Settings', Icons.settings_outlined, Routes.adminSettings),
];

/// Width at which the sidebar is pinned (below it: AppBar + drawer).
const adminWideBreakpoint = 1000.0;

/// Max width of the page content.
const adminContentMaxWidth = 1400.0;

/// Responsive frame around every admin page (except login).
class AdminShell extends StatelessWidget {
  /// Wraps [child], highlighting the nav item for [location].
  const AdminShell({super.key, required this.location, required this.child});

  /// The matched path (e.g. `/admin/bookings/12`).
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => AdminBadgesCubit(ctx.read<AdminRepository>())..start(),
    child: _AdminFrame(location: location, child: child),
  );
}

class _AdminFrame extends StatelessWidget {
  const _AdminFrame({required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= adminWideBreakpoint;
    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: adminContentMaxWidth),
        child: child,
      ),
    );
    final current = adminNavItems.where((i) => i.matches(location)).firstOrNull;

    if (wide) {
      return Scaffold(
        backgroundColor: Q.bg,
        body: Row(
          children: [
            SizedBox(width: 248, child: _Sidebar(location: location)),
            const VerticalDivider(width: 1, color: Q.border),
            Expanded(child: content),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: Q.bg,
      appBar: AppBar(
        backgroundColor: Q.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          current?.label ?? 'Quodes Admin',
          style: display(18, weight: FontWeight.w700),
        ),
        actions: const [_BadgeSummary(), SizedBox(width: 8)],
      ),
      drawer: Drawer(
        backgroundColor: Q.surface,
        child: _Sidebar(location: location, inDrawer: true),
      ),
      body: content,
    );
  }
}

/// Small verify/tickets counters in the narrow AppBar.
class _BadgeSummary extends StatelessWidget {
  const _BadgeSummary();
  @override
  Widget build(BuildContext context) {
    final k = context.watch<AdminBadgesCubit>().state;
    return Row(
      children: [
        if (k.toVerify > 0)
          IconButton(
            tooltip: '${k.toVerify} to verify',
            onPressed: () => context.go(Routes.adminVerify),
            icon: Badge.count(
              count: k.toVerify,
              child: const Icon(Icons.fact_check_outlined),
            ),
          ),
        if (k.openTickets > 0)
          IconButton(
            tooltip: '${k.openTickets} open tickets',
            onPressed: () => context.go(Routes.adminTickets),
            icon: Badge.count(
              count: k.openTickets,
              child: const Icon(Icons.support_agent_outlined),
            ),
          ),
      ],
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.location, this.inDrawer = false});
  final String location;
  final bool inDrawer;

  @override
  Widget build(BuildContext context) {
    final kpis = context.watch<AdminBadgesCubit>().state;
    final email = context.select<AuthBloc, String>(
      (b) => b.state.user?.email ?? '',
    );
    return ColoredBox(
      color: Q.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  const QLogo(size: 40),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QUODES',
                        style: display(
                          18,
                          weight: FontWeight.w700,
                          spacing: 0.1,
                        ),
                      ),
                      Text(
                        'STAFF ADMIN',
                        style: display(
                          10,
                          color: Q.link,
                          weight: FontWeight.w700,
                          spacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Q.border),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                children: [
                  for (final item in adminNavItems)
                    _NavTile(
                      item: item,
                      selected: item.matches(location),
                      count: item.badge?.call(kpis) ?? 0,
                      onTap: () {
                        if (inDrawer) Navigator.of(context).pop();
                        context.go(item.path);
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: Q.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_circle_outlined,
                    color: Q.text3,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      email,
                      overflow: TextOverflow.ellipsis,
                      style: body(13, color: Q.text2, weight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Log out',
                    onPressed: () => context.read<AuthBloc>().add(
                      const AuthLogoutRequested(),
                    ),
                    icon: const Icon(Icons.logout_rounded, color: Q.text3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.count,
    required this.onTap,
  });
  final AdminNavItem item;
  final bool selected;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Material(
      color: selected ? Q.surfaceHi : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Semantics(
          selected: selected,
          button: true,
          child: Container(
            height: 44,
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 20,
                  margin: const EdgeInsets.only(right: 9),
                  decoration: BoxDecoration(
                    color: selected ? Q.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Icon(item.icon, size: 20, color: selected ? Q.link : Q.text3),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: body(
                      14,
                      color: selected ? Q.text : Q.text2,
                      weight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                CountBadge(count),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
