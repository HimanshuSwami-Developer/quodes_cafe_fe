import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/routes.dart';
import '../../../data/models/models.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import '../../../theme/widgets.dart';
import '../bloc/booking_cubit.dart';
import 'widgets/booking_step_view.dart';

class VerifyFailedPage extends StatelessWidget {
  const VerifyFailedPage({super.key});

  @override
  Widget build(BuildContext context) => BookingStepView(
    step: BookingStep.failed,
    builder: (context, booking, s) => _VerifyFailedView(booking: booking, s: s),
  );
}

class _VerifyFailedView extends StatelessWidget {
  const _VerifyFailedView({required this.booking, required this.s});
  final Booking booking;
  final BookingState s;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingCubit>();

    final b = booking;
    final station = b.seats.isEmpty
        ? ''
        : b.seats.first.station.split('-').last;
    final checks = b.aiChecks.where((c) => c.status != 'pending').toList();
    return QBackground(
      hero: const QHeroImage(QPhoto.streaks, height: 320, opacity: 0.7),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 36, 20, 12),
              children: [
                Center(
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: CustomPaint(
                      painter: HexPainter(fill: Q.redBg, stroke: Q.red),
                      child: const Icon(
                        Icons.priority_high_rounded,
                        size: 40,
                        color: Q.red,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'SCAN FAILED',
                  textAlign: TextAlign.center,
                  style: display(26, color: Q.red),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    style: body(14, color: Q.text3, height: 1.5),
                    children: [
                      TextSpan(
                        text:
                            'No worries, Station $station is still locked for ',
                      ),
                      TextSpan(
                        text: mmss(b.lockLeft),
                        style: body(
                          14,
                          color: Q.amber,
                          weight: FontWeight.w800,
                        ),
                      ),
                      const TextSpan(text: '. Fix the issue and resubmit.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (b.aiMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    b.aiMessage,
                    textAlign: TextAlign.center,
                    style: body(13, color: Q.text2),
                  ),
                ],
                const SizedBox(height: 18),
                ...checks.map((c) {
                  final ok = c.status == 'pass';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Panel(
                      color: ok ? Q.surface : Q.redBg,
                      borderColor: ok ? Q.greenBorder : Q.redBorder,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            ok
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: ok ? Q.green : Q.red,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.label,
                                  style: body(14, weight: FontWeight.w800),
                                ),
                                if (c.detail.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    c.detail,
                                    style: body(
                                      13,
                                      color: ok ? Q.text3 : Q.redText,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 6),
                Panel(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.support_agent_rounded,
                        color: Q.link,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Sure you paid right? Send it for manual review, our team responds within 2 hours.',
                          style: body(13, color: Q.text2, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              children: [
                PrimaryButton(
                  label: 'RETRY UPLOAD',
                  onPressed: b.lockLeft == Duration.zero
                      ? null
                      : () => context.pushBooking(b, BookingStep.upload),
                ),
                const SizedBox(height: 6),
                s.action == BookingAction.requestingReview
                    ? const SizedBox(height: 44, child: LoadingView())
                    : TextLink(
                        'Request manual review',
                        onTap: cubit.requestManualReview,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
