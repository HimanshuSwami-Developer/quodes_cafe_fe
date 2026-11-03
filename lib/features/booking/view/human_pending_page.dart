import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../data/models/models.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import '../../../theme/widgets.dart';
import '../bloc/booking_cubit.dart';
import 'widgets/booking_step_view.dart';

class HumanPendingPage extends StatelessWidget {
  const HumanPendingPage({super.key});

  @override
  Widget build(BuildContext context) => BookingStepView(
    step: BookingStep.pending,
    builder: (context, booking, s) => _HumanPendingView(booking: booking, s: s),
  );
}

class _HumanPendingView extends StatefulWidget {
  const _HumanPendingView({required this.booking, required this.s});
  final Booking booking;
  final BookingState s;
  @override
  State<_HumanPendingView> createState() => _HumanPendingViewState();
}

class _HumanPendingViewState extends State<_HumanPendingView> {
  bool _notify = true;

  Future<void> _check() async {
    await context.read<BookingCubit>().refresh();
    if (!mounted) return;
    if (widget.booking.status == 'pending_human') {
      showToast(context, 'Still verifying. Hang tight!');
    }
  }

  String _t(DateTime? d) => d == null ? '' : DateFormat('h:mm a').format(d);

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final s = widget.s;

    final b = booking;
    final total = (b.verifyDeadline != null && b.aiCheckedAt != null)
        ? b.verifyDeadline!.difference(b.aiCheckedAt!)
        : const Duration(hours: 2);
    final left = b.verifyLeft;
    final frac = total.inSeconds == 0
        ? 0.0
        : (left.inSeconds / total.inSeconds).clamp(0.0, 1.0);
    final aiPassed =
        b.aiChecks.isNotEmpty && b.aiChecks.every((c) => c.status == 'pass');
    return QBackground(
      hero: const QHeroImage(
        QPhoto.synthwave,
        height: 300,
        focus: (50, 55),
        opacity: 0.45,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        children: [
          Row(
            children: [
              SquareIconButton(
                icon: Icons.close_rounded,
                semantic: 'Close',
                onTap: () => context.go(Routes.games),
              ),
              const SizedBox(width: 12),
              Text('BOOKING STATUS', style: display(20)),
            ],
          ),
          const SizedBox(height: 16),
          Panel(
            radius: 18,
            color: Q.surface,
            borderColor: Q.amberBorder,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Q.amberBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Q.amberBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BlinkDot(color: Q.amber),
                      const SizedBox(width: 6),
                      Text(
                        'PROVISIONALLY BOOKED',
                        style: label(11, color: Q.amber),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${b.stationLabel} is held while our team verifies',
                  style: body(18, weight: FontWeight.w800, height: 1.3),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('VERIFICATION DEADLINE', style: label(11)),
                          const SizedBox(height: 2),
                          Semantics(
                            label: 'Time remaining ${hhmmss(left)}',
                            child: Text(
                              hhmmss(left),
                              style: display(30, color: Q.amber, spacing: 0.02),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'by ${_t(b.verifyDeadline)}',
                      style: body(13, color: Q.text3, weight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Semantics(
                  label: 'Time remaining',
                  value: '${(frac * 100).round()}%',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: frac,
                      minHeight: 8,
                      backgroundColor: Q.amberBorder,
                      color: Q.amber,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _step(
            done: true,
            title: 'Payment submitted',
            sub:
                '${_t(b.submittedAt)} · Screenshot${b.utr.isNotEmpty ? ' + UTR' : ''}',
          ),
          _step(
            done: aiPassed,
            title: aiPassed ? 'AI check passed' : 'Sent for manual review',
            sub: aiPassed
                ? '${_t(b.aiCheckedAt)} · Amount, payee, UTR matched'
                : '${_t(b.aiCheckedAt)} · ${b.aiMessage.isEmpty ? 'A person will check it' : b.aiMessage}',
          ),
          _step(
            active: true,
            title: 'Team verification · In progress',
            sub: 'A person confirms it in our bank records, within 2 hours',
          ),
          _step(
            last: true,
            title: 'Session confirmed',
            sub: '${b.dateLabel} · ${b.timeLabel} · ${b.stationLabel}',
          ),
          const SizedBox(height: 8),
          Panel(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined, color: Q.link, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: body(13, color: Q.text2, height: 1.5),
                      children: [
                        TextSpan(
                          text: 'Not verified in 2 hours? The slot is released',
                          style: body(13, weight: FontWeight.w800),
                        ),
                        const TextSpan(
                          text:
                              ' for other players. Your payment stays safe as credit or gets refunded.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _notify,
            onChanged: (v) => setState(() => _notify = v ?? true),
            activeColor: Q.primary,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Notify me when it’s confirmed',
              style: body(14, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GhostButton(
                  label: 'Back to games',
                  height: 54,
                  onPressed: () => context.go(Routes.games),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: 'CHECK STATUS',
                  icon: Icons.refresh_rounded,
                  bob: false,
                  loading: s.loading,
                  onPressed: _check,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _step({
    bool done = false,
    bool active = false,
    bool last = false,
    required String title,
    required String sub,
  }) {
    final color = done
        ? Q.green
        : active
        ? Q.amber
        : Q.borderHi;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: done ? Q.green : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: done
                      ? const Icon(Icons.check_rounded, size: 15, color: Q.bg)
                      : active
                      ? const BlinkDot(color: Q.amber, size: 8)
                      : null,
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: done ? Q.greenBorder : Q.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: body(
                      14,
                      color: done || active ? Q.text : Q.text3,
                      weight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(sub, style: body(12, color: Q.text3, height: 1.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
