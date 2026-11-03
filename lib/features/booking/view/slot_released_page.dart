import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/routes.dart';
import '../../../data/models/models.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import '../../../theme/widgets.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../booking_flow/bloc/booking_flow_cubit.dart';
import '../../booking_flow/bloc/booking_flow_restore.dart';
import '../bloc/booking_cubit.dart';
import 'hold_page.dart' show RingPainter;
import 'widgets/booking_step_view.dart';

class SlotReleasedPage extends StatelessWidget {
  const SlotReleasedPage({super.key});

  @override
  Widget build(BuildContext context) => BookingStepView(
    step: BookingStep.released,
    builder: (context, booking, s) => _SlotReleasedView(booking: booking, s: s),
  );
}

class _SlotReleasedView extends StatelessWidget {
  const _SlotReleasedView({required this.booking, required this.s});
  final Booking booking;
  final BookingState s;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return QBackground(
      hero: const QHeroImage(QPhoto.synthwave, height: 320, opacity: 0.45),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 36, 20, 12),
              children: [
                Center(
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(96, 96),
                          painter: RingPainter(
                            1,
                            track: Q.surfaceLo,
                            fill: Q.muted,
                          ),
                        ),
                        const Icon(
                          Icons.lock_open_rounded,
                          size: 34,
                          color: Q.muted,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'SLOT RELEASED',
                  textAlign: TextAlign.center,
                  style: display(26),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    style: body(14, color: Q.text3, height: 1.5),
                    children: [
                      const TextSpan(
                        text:
                            'Verification wasn’t completed within 2 hours, so ',
                      ),
                      TextSpan(
                        text:
                            '${b.stationLabel}, ${b.dateLabel} ${b.timeLabel}',
                        style: body(14, color: Q.text, weight: FontWeight.w800),
                      ),
                      const TextSpan(text: ' is open to other players again.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: Q.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Q.greenBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Container(
                        color: Q.greenBg,
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_user_rounded,
                              color: Q.green,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Your ₹${rupees(b.amountDue)} is safe',
                              style: body(
                                15,
                                color: Q.green,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            _row('UTR', b.utr.isEmpty ? '—' : b.utr),
                            _row('Status', 'Saved as game credit'),
                            _row(
                              'Released',
                              b.releasedAt == null
                                  ? '—'
                                  : DateFormat(
                                      'd MMM, h:mm a',
                                    ).format(b.releasedAt!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Panel(
                  color: Q.surfaceHi,
                  borderColor: Q.primaryMid,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.bolt_rounded, color: Q.link, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: body(13, color: Q.text2, height: 1.5),
                            children: [
                              TextSpan(
                                text: 'Quick respawn: ',
                                style: body(13, weight: FontWeight.w800),
                              ),
                              const TextSpan(
                                text:
                                    'if the same station and time are still free, rebook now with your credit, no new payment.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                PrimaryButton(
                  label: 'REBOOK WITH CREDIT',
                  loading: s.action == BookingAction.rebooking,
                  onPressed: () => _rebook(context),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GhostButton(
                        label: 'Pick another slot',
                        onPressed: () {
                          context.read<BookingFlowCubit>().restoreFrom(b);
                          context.push(Routes.slots);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GhostButton(
                        label: 'Request refund',
                        onPressed: () => context.goSupport(
                          topic: 'Refund',
                          bookingCode: b.code,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rebook(BuildContext context) async {
    final nb = await context.read<BookingCubit>().rebookWithCredit();
    if (nb == null || !context.mounted) return;
    context.read<AuthBloc>().add(const AuthUserRefreshRequested());
    context.goBooking(nb);
  }

  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(k, style: body(14, color: Q.text3)),
        ),
        Text(v, style: body(14, weight: FontWeight.w800)),
      ],
    ),
  );
}
