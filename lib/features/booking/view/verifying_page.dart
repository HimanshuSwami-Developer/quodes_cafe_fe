import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/routes.dart';
import '../../../data/models/models.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import '../../../theme/widgets.dart';
import '../bloc/booking_cubit.dart';
import 'widgets/booking_step_view.dart';

class VerifyingPage extends StatelessWidget {
  const VerifyingPage({super.key});

  @override
  Widget build(BuildContext context) => BookingStepView(
    step: BookingStep.verifying,
    stayOn: const {'pending_human', 'ai_failed'},
    builder: (context, booking, s) => _VerifyingView(booking: booking, s: s),
  );
}

class _VerifyingView extends StatefulWidget {
  const _VerifyingView({required this.booking, required this.s});
  final Booking booking;
  final BookingState s;
  @override
  State<_VerifyingView> createState() => _VerifyingViewState();
}

class _VerifyingViewState extends State<_VerifyingView>
    with SingleTickerProviderStateMixin {
  int _revealed = 0;
  Timer? _reveal;
  bool _left = false;
  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  static const _fallback = [
    ('Reading screenshot', 'Text and amounts extracted'),
    ('Amount matches', 'Checking the amount paid'),
    ('Payee UPI ID matches', 'Checking who was paid'),
    ('UTR not used before', 'Duplicate-proof check'),
    ('Paid within lock window', 'Timestamp vs. slot lock'),
  ];

  @override
  void initState() {
    super.initState();
    _reveal = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted) return;
      final booking = widget.booking;
      final done = booking.status != 'scanning';
      final n = _checksOf(booking).length;
      // While the AI is still running, hold the reveal one step short so the
      // last item keeps "working"; once a verdict arrives, play it out.
      if (_revealed < (done ? n : n - 1)) setState(() => _revealed++);
      if (done && _revealed >= n) _finish(booking);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!reduceMotion(context)) _scan.repeat(reverse: true);
  }

  @override
  void dispose() {
    _reveal?.cancel();
    _scan.dispose();
    super.dispose();
  }

  List<AiCheck> _checksOf(Booking booking) => booking.aiChecks.isNotEmpty
      ? booking.aiChecks
      : _fallback
            .map(
              (e) => AiCheck.fromJson({
                'label': e.$1,
                'detail': e.$2,
                'status': 'pending',
              }),
            )
            .toList();

  /// A failed scan plays out its checks, then moves to the failure screen.
  void _finish(Booking booking) {
    if (_left || booking.status != 'ai_failed') return;
    _left = true;
    _reveal?.cancel();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) context.goBooking(widget.booking);
    });
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    final checks = _checksOf(booking);
    final passed =
        booking.status == 'pending_human' && _revealed >= checks.length;
    final failed = booking.status == 'ai_failed' && _revealed >= checks.length;
    final heading = passed
        ? 'AI CHECK PASSED'
        : failed
        ? 'CHECK FAILED'
        : 'SCANNING PAYMENT…';
    final station = booking.seats.isEmpty
        ? ''
        : booking.seats.first.station.split('-').last;
    return QBackground(
      hero: const QHeroImage(
        QPhoto.streaks,
        height: 360,
        focus: (60, 50),
        opacity: 0.85,
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 12),
              children: [
                Center(child: _scanner(passed)),
                const SizedBox(height: 22),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    heading,
                    textAlign: TextAlign.center,
                    style: display(
                      24,
                      color: passed
                          ? Q.green
                          : failed
                          ? Q.red
                          : Q.text,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Our AI is reading your screenshot and matching it to your booking. Station $station stays locked meanwhile.',
                  textAlign: TextAlign.center,
                  style: body(14, color: Q.text3, height: 1.5),
                ),
                const SizedBox(height: 20),
                Panel(
                  radius: 16,
                  child: Column(
                    children: List.generate(checks.length, (k) {
                      final c = checks[k];
                      final shown = k < _revealed;
                      final active = k == _revealed && !passed && !failed;
                      final st = shown ? c.status : 'pending';
                      Widget icon;
                      if (shown && st == 'pass') {
                        icon = const _Dot(
                          color: Q.green,
                          child: Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Q.bg,
                          ),
                        );
                      } else if (shown && st == 'fail') {
                        icon = const _Dot(
                          color: Q.red,
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Q.bg,
                          ),
                        );
                      } else if (active) {
                        icon = const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Q.link,
                          ),
                        );
                      } else {
                        icon = Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Q.borderHi, width: 2),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            icon,
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.label,
                                    style: body(
                                      14,
                                      color: shown || active ? Q.text : Q.text3,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                  if (c.detail.isNotEmpty)
                                    Text(
                                      c.detail,
                                      style: body(12, color: Q.text3),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: passed
                ? PrimaryButton(
                    label: 'CONTINUE',
                    onPressed: () => context.goBooking(booking),
                  )
                : SizedBox(
                    height: 54,
                    child: Center(
                      child: Text(
                        'Usually under 30 seconds. You can leave, we’ll keep checking.',
                        textAlign: TextAlign.center,
                        style: body(13, color: Q.text3),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _scanner(bool passed) => SizedBox(
    width: 150,
    height: 200,
    child: Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Q.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: passed ? Q.green : Q.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: (passed ? Q.green : Q.primary).withValues(alpha: 0.35),
                blurRadius: 24,
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Icon(
                  passed ? Icons.verified_rounded : Icons.receipt_long_rounded,
                  size: 40,
                  color: passed ? Q.green : Q.link,
                ),
              ),
              const SizedBox(height: 16),
              for (final w in [0.9, 0.6, 0.75, 0.5, 0.8])
                Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  height: 7,
                  width: 110 * w,
                  decoration: BoxDecoration(
                    color: Q.borderHi,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ),
        if (!passed)
          AnimatedBuilder(
            animation: _scan,
            builder: (_, _) => Positioned(
              left: 6,
              right: 6,
              top: 10 + 170 * _scan.value,
              child: Container(
                height: 3,
                decoration: const BoxDecoration(
                  color: Q.cyan,
                  boxShadow: [BoxShadow(color: Q.cyan, blurRadius: 12)],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _Dot extends StatelessWidget {
  final Color color;
  final Widget child;
  const _Dot({required this.color, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: child,
  );
}
