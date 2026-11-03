import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../data/models/admin_models.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/theme.dart';
import '../../../../theme/widgets.dart';
import '../../common/view/admin_ui.dart';
import '../../shell/admin_badges_cubit.dart';
import '../bloc/admin_dashboard_cubit.dart';

/// Staff landing page: KPIs, the verify queue and today's sessions.
/// Refreshes itself every 20 seconds.
class AdminDashboardPage extends StatelessWidget {
  /// Creates the dashboard.
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => AdminDashboardCubit(ctx.read<AdminRepository>())..start(),
    child: BlocListener<AdminDashboardCubit, AdminDashboardState>(
      listenWhen: (a, b) => a.data?.kpis != b.data?.kpis && b.data != null,
      // Keep the sidebar badges in step with what the dashboard shows.
      listener: (context, s) =>
          context.read<AdminBadgesCubit>().update(s.data!.kpis),
      child: const _DashboardView(),
    ),
  );
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AdminDashboardCubit>().state;
    final cubit = context.read<AdminDashboardCubit>();
    final d = s.data;
    return AdminPage(
      title: 'Dashboard',
      subtitle: d?.serverTime == null
          ? null
          : 'Updated ${adminDateTime(d!.serverTime)} · refreshes every 20s',
      actions: [
        AdminOutlineButton(
          label: 'Refresh',
          icon: Icons.refresh_rounded,
          onPressed: () => cubit.load(silent: true),
        ),
      ],
      child: d == null
          ? (s.status.isFailure
                ? ErrorView(error: s.error ?? 'Failed', onRetry: cubit.load)
                : const LoadingView())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _KpiGrid(d.kpis),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, c) {
                    final queue = _QueueCard(d.queue);
                    final today = _TodayCard(d.today);
                    if (c.maxWidth < 1100) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [queue, const SizedBox(height: 20), today],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: queue),
                        const SizedBox(width: 20),
                        Expanded(flex: 3, child: today),
                      ],
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid(this.k);
  final DashboardKpis k;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _Kpi(
        'To verify',
        '${k.toVerify}',
        Icons.fact_check_outlined,
        k.toVerify > 0 ? Q.amber : Q.green,
        Routes.adminVerify,
      ),
      _Kpi(
        'Sessions today',
        '${k.sessionsToday}',
        Icons.event_available_outlined,
        Q.link,
        Routes.adminBookings,
      ),
      _Kpi(
        'Revenue today',
        inr(k.revenueToday),
        Icons.currency_rupee_rounded,
        Q.green,
        Routes.adminBookings,
      ),
      _Kpi(
        'Live locks',
        '${k.liveLocks}',
        Icons.lock_clock_outlined,
        Q.cyan,
        Routes.adminBookings,
      ),
      _Kpi(
        'Open tickets',
        '${k.openTickets}',
        Icons.support_agent_outlined,
        k.openTickets > 0 ? Q.pink : Q.text3,
        Routes.adminTickets,
      ),
      _Kpi(
        'Players',
        '${k.players}',
        Icons.people_alt_outlined,
        Q.linkHi,
        Routes.adminPlayers,
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 1100
            ? 6
            : c.maxWidth >= 700
            ? 3
            : 2;
        const gap = 12.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final k in cards) SizedBox(width: w, child: _KpiCard(k)),
          ],
        );
      },
    );
  }
}

class _Kpi {
  const _Kpi(this.label, this.value, this.icon, this.color, this.route);
  final String label, value, route;
  final IconData icon;
  final Color color;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard(this.k);
  final _Kpi k;

  @override
  Widget build(BuildContext context) => Material(
    color: Q.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: Q.border),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.go(k.route),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(k.icon, color: k.color, size: 20),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Q.text3,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(k.value, style: display(28, weight: FontWeight.w700)),
            ),
            const SizedBox(height: 2),
            Text(
              k.label.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: label(11),
            ),
          ],
        ),
      ),
    ),
  );
}

class _QueueCard extends StatelessWidget {
  const _QueueCard(this.queue);
  final List<StaffBooking> queue;

  @override
  Widget build(BuildContext context) => AdminCard(
    title: 'Verify queue',
    trailing: TextLink(
      'Open queue',
      size: 13,
      onTap: () => context.go(Routes.adminVerify),
    ),
    child: queue.isEmpty
        ? const AdminEmpty(
            icon: Icons.task_alt_rounded,
            text: 'All payments verified.',
          )
        : Column(
            children: [
              for (final b in queue)
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => context.go(Routes.adminBookingOf(b.id)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 4,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${b.code} · ${b.player.display}',
                                overflow: TextOverflow.ellipsis,
                                style: body(14, weight: FontWeight.w800),
                              ),
                              Text(
                                '${b.booking.dateLabel} ${b.booking.timeLabel}'
                                ' · ${inr(b.booking.amountDue)}',
                                overflow: TextOverflow.ellipsis,
                                style: body(12, color: Q.text3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        VerifyCountdown(b.booking),
                      ],
                    ),
                  ),
                ),
            ],
          ),
  );
}

class _TodayCard extends StatelessWidget {
  const _TodayCard(this.today);
  final List<StaffBooking> today;

  @override
  Widget build(BuildContext context) => AdminCard(
    title: "Today's sessions",
    trailing: Text('${today.length}', style: label(12)),
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
    child: today.isEmpty
        ? const AdminEmpty(
            icon: Icons.event_busy_outlined,
            text: 'No sessions booked for today.',
          )
        : AdminTable(
            columns: const [
              DataColumn(label: Text('TIME')),
              DataColumn(label: Text('BOOKING')),
              DataColumn(label: Text('PLAYER')),
              DataColumn(label: Text('GAME')),
              DataColumn(label: Text('SEATS')),
              DataColumn(label: Text('STATUS')),
            ],
            rows: [
              for (final b in today)
                adminRow(
                  onTap: () => context.go(Routes.adminBookingOf(b.id)),
                  cells: [
                    DataCell(Text(b.booking.timeLabel)),
                    DataCell(
                      Text(
                        b.code,
                        style: body(14, color: Q.link, weight: FontWeight.w800),
                      ),
                    ),
                    DataCell(Text(b.player.display)),
                    DataCell(Text(b.booking.game?.name ?? '—')),
                    DataCell(
                      Text(
                        b.booking.seats.map((s) => s.code).join(', '),
                        style: body(13, color: Q.text2),
                      ),
                    ),
                    DataCell(StatusPill(b.status)),
                  ],
                ),
            ],
          ),
  );
}
