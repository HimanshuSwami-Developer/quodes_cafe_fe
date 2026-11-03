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
import '../bloc/admin_verify_cubit.dart';

/// Payments waiting for a human: approve or reject each one.
class AdminVerifyPage extends StatelessWidget {
  /// Creates the verify queue page.
  const AdminVerifyPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => AdminVerifyCubit(
      ctx.read<AdminRepository>(),
      refreshEvery: const Duration(seconds: 30),
    )..start(),
    child: BlocListener<AdminVerifyCubit, AdminVerifyState>(
      listenWhen: (a, b) => a.seq != b.seq,
      listener: (context, s) {
        if (s.actionError != null) {
          showError(context, s.actionError!);
        } else if (s.done != null) {
          showToast(context, s.done!);
          context.read<AdminBadgesCubit>().refresh();
        }
      },
      child: const _VerifyView(),
    ),
  );
}

class _VerifyView extends StatelessWidget {
  const _VerifyView();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AdminVerifyCubit>().state;
    final cubit = context.read<AdminVerifyCubit>();
    return AdminPage(
      title: 'Verify payments',
      subtitle: s.items == null
          ? null
          : '${s.items!.length} waiting · oldest deadline first',
      actions: [
        AdminOutlineButton(
          label: 'Refresh',
          icon: Icons.refresh_rounded,
          onPressed: () => cubit.load(silent: true),
        ),
      ],
      child: AdminAsync<StaffBooking>(
        status: s.status,
        items: s.items,
        error: s.error,
        onRetry: cubit.load,
        emptyIcon: Icons.task_alt_rounded,
        emptyText: 'All caught up. No payments to verify.',
        builder: (items) => ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => VerifyCard(
            key: ValueKey(items[i].id),
            booking: items[i],
            busy: s.busyIds.contains(items[i].id),
          ),
        ),
      ),
    );
  }
}

/// One payment to check: player, slot, amount, UTR, AI checks, screenshot.
class VerifyCard extends StatelessWidget {
  /// Creates a card; [busy] disables the actions.
  const VerifyCard({super.key, required this.booking, this.busy = false});
  final StaffBooking booking;
  final bool busy;

  Future<void> _reject(BuildContext context) async {
    final cubit = context.read<AdminVerifyCubit>();
    final note = await askRejectNote(context, code: booking.code);
    if (note != null) await cubit.reject(booking, note: note);
  }

  @override
  Widget build(BuildContext context) {
    final b = booking.booking;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            InkWell(
              onTap: () => context.go(Routes.adminBookingOf(booking.id)),
              child: Text(
                booking.code,
                style: display(18, color: Q.link, weight: FontWeight.w700),
              ),
            ),
            StatusPill(booking.status),
            VerifyCountdown(b),
          ],
        ),
        const SizedBox(height: 8),
        Text(booking.player.display, style: body(15, weight: FontWeight.w800)),
        Text(
          [
            booking.player.email,
            booking.player.phone,
          ].where((e) => e.isNotEmpty).join(' · '),
          style: body(13, color: Q.text3),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 24,
          runSpacing: 10,
          children: [
            KV('SLOT', '${b.dateLabel} · ${b.timeLabel}'),
            KV(
              'STATION',
              b.stationLabel.isEmpty ? b.stationTypeName : b.stationLabel,
            ),
            KV('GAME', b.game?.name ?? '—'),
            KV('AMOUNT', inr(b.amountDue)),
            KV('UTR', b.utr.isEmpty ? '—' : b.utr),
          ],
        ),
        const SizedBox(height: 12),
        AiChecksView(checks: b.aiChecks, message: b.aiMessage),
      ],
    );
    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        AdminButton(
          label: 'Approve',
          icon: Icons.check_rounded,
          color: Q.greenDeep,
          loading: busy,
          onPressed: () => context.read<AdminVerifyCubit>().approve(booking),
        ),
        AdminOutlineButton(
          label: 'Reject',
          icon: Icons.block_rounded,
          color: Q.red,
          onPressed: busy ? null : () => _reject(context),
        ),
      ],
    );

    return Panel(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, c) {
          final thumb = ScreenshotThumb(booking.screenshotUrl);
          if (c.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    thumb,
                    const SizedBox(width: 12),
                    Expanded(child: actions),
                  ],
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: details),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  thumb,
                  const SizedBox(height: 12),
                  SizedBox(width: 220, child: actions),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
