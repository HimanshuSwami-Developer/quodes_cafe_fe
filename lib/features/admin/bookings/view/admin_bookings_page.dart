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
import '../bloc/admin_bookings_cubit.dart';

/// Searchable, filterable table of all bookings.
class AdminBookingsPage extends StatelessWidget {
  /// Creates the page.
  const AdminBookingsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => AdminBookingsCubit(ctx.read<AdminRepository>())..load(),
    child: const _BookingsView(),
  );
}

class _BookingsView extends StatefulWidget {
  const _BookingsView();
  @override
  State<_BookingsView> createState() => _BookingsViewState();
}

class _BookingsViewState extends State<_BookingsView> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _pickDate(String? current) async {
    final cubit = context.read<AdminBookingsCubit>();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current == null ? now : DateTime.tryParse(current) ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) cubit.setDate(apiDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdminBookingsCubit>();
    final s = context.watch<AdminBookingsCubit>().state;
    return AdminPage(
      title: 'Bookings',
      subtitle: 'Newest first · up to 200 results',
      actions: [
        AdminOutlineButton(
          label: 'Refresh',
          icon: Icons.refresh_rounded,
          onPressed: cubit.load,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _q,
                  onChanged: cubit.search,
                  style: body(14),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search code, UTR, email, gamertag, phone',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: s.query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _q.clear();
                              cubit.search('');
                            },
                          ),
                  ),
                ),
              ),
              AdminOutlineButton(
                label: s.date ?? 'Any date',
                icon: Icons.calendar_today_outlined,
                onPressed: () => _pickDate(s.date),
              ),
              if (s.date != null)
                IconButton(
                  tooltip: 'Clear date',
                  onPressed: () => cubit.setDate(null),
                  icon: const Icon(Icons.close_rounded, color: Q.text3),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              QChip(
                label: 'All',
                height: 34,
                glow: false,
                selected: s.statuses.isEmpty,
                onTap: cubit.clearStatuses,
              ),
              for (final e in bookingStatusLabels.entries)
                QChip(
                  label: e.value,
                  height: 34,
                  glow: false,
                  selected: s.statuses.contains(e.key),
                  onTap: () => cubit.toggleStatus(e.key),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: AdminAsync<StaffBooking>(
              status: s.status,
              items: s.items,
              error: s.error,
              onRetry: cubit.load,
              emptyIcon: Icons.event_busy_outlined,
              emptyText: 'No bookings match these filters.',
              builder: (items) => SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: _BookingsTable(items),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingsTable extends StatelessWidget {
  const _BookingsTable(this.items);
  final List<StaffBooking> items;

  @override
  Widget build(BuildContext context) => AdminTable(
    columns: const [
      DataColumn(label: Text('CODE')),
      DataColumn(label: Text('PLAYER')),
      DataColumn(label: Text('GAME')),
      DataColumn(label: Text('DATE / TIME')),
      DataColumn(label: Text('STATION')),
      DataColumn(label: Text('AMOUNT'), numeric: true),
      DataColumn(label: Text('STATUS')),
    ],
    rows: [
      for (final sb in items)
        adminRow(
          key: ValueKey(sb.id),
          onTap: () => context.go(Routes.adminBookingOf(sb.id)),
          cells: [
            DataCell(
              Text(
                sb.code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Q.link,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sb.player.display, style: body(14)),
                  if (sb.player.email.isNotEmpty &&
                      sb.player.email != sb.player.display)
                    Text(sb.player.email, style: body(12, color: Q.text3)),
                ],
              ),
            ),
            DataCell(Text(sb.booking.game?.name ?? '—')),
            DataCell(
              Text(
                '${sb.booking.dateLabel.isEmpty ? sb.booking.date : sb.booking.dateLabel}'
                ' · ${sb.booking.timeLabel}',
              ),
            ),
            DataCell(
              Text(
                sb.booking.stationLabel.isEmpty
                    ? sb.booking.stationTypeName
                    : sb.booking.stationLabel,
              ),
            ),
            DataCell(Text(inr(sb.booking.amountDue))),
            DataCell(
              StatusPill(
                sb.status,
                label: bookingStatusLabels[sb.status] ?? sb.booking.statusLabel,
              ),
            ),
          ],
        ),
    ],
  );
}
