import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../data/models/admin_models.dart';
import '../../../../data/models/models.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/theme.dart';
import '../../../../theme/widgets.dart';
import '../../common/view/admin_ui.dart';
import '../../shell/admin_badges_cubit.dart';
import '../bloc/admin_booking_detail_cubit.dart';

/// Everything about one booking, with Approve / Reject when allowed.
class AdminBookingDetailPage extends StatelessWidget {
  /// Creates the page for booking [id].
  const AdminBookingDetailPage({super.key, required this.id});

  /// Booking id from the URL.
  final int id;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) =>
        AdminBookingDetailCubit(ctx.read<AdminRepository>(), id: id)..load(),
    child: BlocListener<AdminBookingDetailCubit, AdminBookingDetailState>(
      listenWhen: (a, b) => a.actionStatus != b.actionStatus,
      listener: (context, s) {
        if (s.actionStatus.isSuccess) {
          showToast(
            context,
            s.action == ReviewAction.approve
                ? 'Payment approved · ${s.booking?.code}'
                : 'Payment rejected · ${s.booking?.code}',
          );
          _refreshBadges(context);
        } else if (s.actionStatus.isFailure) {
          showApiError(context, s.actionError);
        }
      },
      child: const _DetailView(),
    ),
  );
}

void _refreshBadges(BuildContext context) {
  try {
    context.read<AdminBadgesCubit>().refresh();
  } catch (_) {
    // Not inside the admin shell (e.g. tests): nothing to refresh.
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdminBookingDetailCubit>();
    final s = context.watch<AdminBookingDetailCubit>().state;
    final sb = s.booking;
    final busy = s.actionStatus.isLoading;

    return AdminPage(
      title: sb == null ? 'Booking' : 'Booking ${sb.code}',
      subtitle: sb == null
          ? null
          : '${sb.player.display} · ${sb.booking.game?.name ?? ''}',
      leading: IconButton(
        tooltip: 'Back to bookings',
        onPressed: () => context.go(Routes.adminBookings),
        icon: const Icon(Icons.arrow_back_rounded, color: Q.text),
      ),
      actions: [
        if (sb != null) StatusPill(sb.status, label: _statusText(sb)),
        if (sb != null && sb.canReview) ...[
          AdminButton(
            label: 'Approve',
            icon: Icons.check_rounded,
            color: Q.greenDeep,
            loading: busy && s.action == ReviewAction.approve,
            onPressed: busy ? null : cubit.approve,
          ),
          AdminButton(
            label: 'Reject',
            icon: Icons.block_rounded,
            color: const Color(0xFFD9364F),
            loading: busy && s.action == ReviewAction.reject,
            onPressed: busy
                ? null
                : () async {
                    final note = await askRejectNote(context, code: sb.code);
                    if (note != null) await cubit.reject(note);
                  },
          ),
        ],
        AdminOutlineButton(
          label: 'Refresh',
          icon: Icons.refresh_rounded,
          onPressed: cubit.load,
        ),
      ],
      child: sb == null
          ? (s.status.isFailure
                ? ErrorView(error: s.error ?? 'Failed', onRetry: cubit.load)
                : const LoadingView())
          : _Body(sb),
    );
  }
}

String _statusText(StaffBooking sb) => sb.booking.statusLabel.isNotEmpty
    ? sb.booking.statusLabel
    : (bookingStatusLabels[sb.status] ?? sb.status);

class _Body extends StatelessWidget {
  const _Body(this.sb);
  final StaffBooking sb;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final wide = c.maxWidth >= 900;
      final left = [
        _overview(context),
        const SizedBox(height: 16),
        _amounts(),
        const SizedBox(height: 16),
        _timeline(),
      ];
      final right = [
        _payment(),
        const SizedBox(height: 16),
        _aiRaw(),
        const SizedBox(height: 16),
        _review(context),
      ];
      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: left,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: right,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [...left, const SizedBox(height: 16), ...right],
              ),
      );
    },
  );

  Booking get b => sb.booking;

  Widget _overview(BuildContext context) => AdminCard(
    title: 'Overview',
    child: Wrap(
      spacing: 32,
      runSpacing: 16,
      children: [
        _kv('Player', sb.player.display),
        _kv('Email', sb.player.email),
        if (sb.player.phone.isNotEmpty) _kv('Phone', sb.player.phone),
        _kv('Player credit', inr(sb.player.credit)),
        _kv('Game', b.game?.name ?? '—'),
        _kv(
          'Station',
          b.stationLabel.isEmpty ? b.stationTypeName : b.stationLabel,
        ),
        _kv(
          'Slot',
          '${b.dateLabel.isEmpty ? b.date : b.dateLabel} · ${b.timeLabel}',
        ),
        _kv('Duration', '${b.durationHours} h · ${b.players} player(s)'),
        _kv(
          'Seats',
          b.seats.isEmpty
              ? '—'
              : b.seats.map((s) => '${s.code} (${s.label})').join(', '),
        ),
        if (sb.rebookedFrom != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REBOOKED FROM', style: label(11)),
              TextLink(
                'Booking #${sb.rebookedFrom}',
                onTap: () =>
                    context.go(Routes.adminBookingOf(sb.rebookedFrom!)),
              ),
            ],
          ),
      ],
    ),
  );

  Widget _amounts() => AdminCard(
    title: 'Amounts',
    child: Wrap(
      spacing: 32,
      runSpacing: 16,
      children: [
        _kv('Rate', '${inr(b.rate)} / seat / h'),
        _kv('Subtotal', inr(b.subtotal)),
        _kv('Credit applied', inr(b.creditApplied)),
        _kv('Amount due', inr(b.amountDue)),
        _kv('UTR', b.utr.isEmpty ? '—' : b.utr, mono: true),
      ],
    ),
  );

  Widget _timeline() {
    final rows = <(String, DateTime?)>[
      ('Created', b.createdAt),
      ('Lock expires', b.lockExpiresAt),
      ('Proof submitted', b.submittedAt),
      ('AI checked', b.aiCheckedAt),
      ('Verify deadline', b.verifyDeadline),
      ('Confirmed', b.confirmedAt),
      ('Released', b.releasedAt),
    ];
    return AdminCard(
      title: 'Timeline',
      trailing: sb.status == 'pending_human' ? VerifyCountdown(b) : null,
      child: Column(
        children: [
          for (final (k, t) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(
                    t == null
                        ? Icons.radio_button_unchecked_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 16,
                    color: t == null ? Q.border : Q.link,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      k,
                      style: body(14, color: t == null ? Q.text3 : Q.text),
                    ),
                  ),
                  Text(
                    adminDateTime(t),
                    style: body(13, color: Q.text2, weight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _payment() => AdminCard(
    title: 'Payment proof',
    child: Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        ScreenshotThumb(sb.screenshotUrl, width: 160, height: 220),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 200, maxWidth: 360),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI CHECKS', style: label(11)),
              const SizedBox(height: 8),
              AiChecksView(checks: b.aiChecks, message: b.aiMessage),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _aiRaw() {
    final raw = sb.aiRaw;
    return AdminCard(
      title: 'What the AI read',
      child: raw == null || raw.isEmpty
          ? Text('Nothing recorded.', style: body(13, color: Q.text3))
          : Column(
              children: [
                for (final e in raw.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 140,
                          child: Text(
                            e.key,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: Q.text3,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SelectableText(
                            '${e.value ?? '—'}',
                            style: body(13, weight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _review(BuildContext context) => AdminCard(
    title: 'Staff review',
    child: Wrap(
      spacing: 32,
      runSpacing: 16,
      children: [
        _kv('Reviewed by', sb.reviewedBy ?? '—'),
        _kv('Staff note', sb.staffNote.isEmpty ? '—' : sb.staffNote),
      ],
    ),
  );

  Widget _kv(String k, String v, {bool mono = false}) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 320),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(k.toUpperCase(), style: label(11)),
        const SizedBox(height: 3),
        SelectableText(
          v.isEmpty ? '—' : v,
          style: mono
              ? const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: Q.text,
                  fontWeight: FontWeight.w700,
                )
              : body(14, weight: FontWeight.w700),
        ),
      ],
    ),
  );
}
