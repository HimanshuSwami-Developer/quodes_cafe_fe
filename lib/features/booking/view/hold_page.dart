import 'dart:math' as math;

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

class HoldPage extends StatelessWidget {
  const HoldPage({super.key});

  @override
  Widget build(BuildContext context) => BookingStepView(
    step: BookingStep.hold,
    builder: (context, booking, s) => _HoldView(booking: booking, s: s),
  );
}

class _HoldView extends StatelessWidget {
  const _HoldView({required this.booking, required this.s});
  final Booking booking;
  final BookingState s;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingCubit>();

    final b = booking;
    final total = (b.lockExpiresAt != null && b.createdAt != null)
        ? b.lockExpiresAt!.difference(b.createdAt!)
        : const Duration(minutes: 10);
    final left = b.lockLeft;
    final frac = total.inSeconds == 0 ? 0.0 : left.inSeconds / total.inSeconds;
    return QBackground(
      hero: const QHeroImage(
        QPhoto.synthwave,
        height: 340,
        focus: (50, 55),
        opacity: 0.6,
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              children: [
                const Row(
                  children: [
                    SquareIconButton(semantic: 'Back'),
                    Spacer(),
                    StepDots(step: 4),
                  ],
                ),
                const SizedBox(height: 18),
                Center(
                  child: SizedBox(
                    width: 132,
                    height: 132,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(132, 132),
                          painter: RingPainter(frac),
                        ),
                        Semantics(
                          label: 'Time left ${mmss(left)}',
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                mmss(left),
                                style: display(
                                  30,
                                  color: Q.amber,
                                  spacing: 0.02,
                                ),
                              ),
                              Text(
                                'LEFT',
                                style: label(11, color: Q.amberText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'SLOT LOCKED',
                  textAlign: TextAlign.center,
                  style: display(24),
                ),
                const SizedBox(height: 6),
                Text(
                  '${b.stationLabel} is reserved for you while you pay. Not paid in ${total.inMinutes} minutes? It unlocks for other players.',
                  textAlign: TextAlign.center,
                  style: body(14, color: Q.text3, height: 1.5),
                ),
                const SizedBox(height: 18),
                Panel(
                  radius: 18,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 3.2,
                          mainAxisSpacing: 8,
                          children: [
                            KV('GAME', b.game?.name ?? ''),
                            KV('STATION', b.stationLabel),
                            KV('DATE', b.dateLabel),
                            KV('TIME', b.timeLabel),
                            KV('PLAYERS', '${b.players}'),
                            KV(
                              'DURATION',
                              '${b.durationHours} ${b.durationHours == 1 ? 'hour' : 'hours'}',
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Q.borderHi,
                              style: BorderStyle.solid,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            _row(
                              '₹${rupees(b.rate)} × ${b.players} × ${b.durationHours} hr',
                              '₹${rupees(b.subtotal)}',
                              body(14, color: Q.text3),
                            ),
                            if (b.creditApplied > 0) ...[
                              const SizedBox(height: 6),
                              _row(
                                'Game credit',
                                '−₹${rupees(b.creditApplied)}',
                                body(14, color: Q.green),
                              ),
                            ],
                            const SizedBox(height: 8),
                            _row(
                              'Total',
                              '₹${rupees(b.amountDue)}',
                              display(18),
                            ),
                          ],
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
                  label: 'PAY ₹${rupees(b.amountDue)}',
                  onPressed: left == Duration.zero
                      ? null
                      : () => context.pushBooking(b, BookingStep.pay),
                ),
                const SizedBox(height: 6),
                s.action == BookingAction.cancelling
                    ? const SizedBox(height: 44, child: LoadingView())
                    : TextLink('Unlock slot', onTap: cubit.cancel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String a, String b, TextStyle s) => Row(
    children: [
      Expanded(child: Text(a, style: s)),
      Text(b, style: s),
    ],
  );
}

class RingPainter extends CustomPainter {
  final double frac;
  final Color track, fill;
  RingPainter(this.frac, {this.track = Q.amberBorder, this.fill = Q.amber});
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 10;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, p..color = track);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * frac.clamp(0, 1),
      false,
      p..color = fill,
    );
  }

  @override
  bool shouldRepaint(covariant RingPainter old) => old.frac != frac;
}
