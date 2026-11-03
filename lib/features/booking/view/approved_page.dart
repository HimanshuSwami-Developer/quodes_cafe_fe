import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/routes.dart';
import '../../../data/models/models.dart';
import '../../../theme/colors.dart';
import '../../../theme/game_art.dart';
import '../../../theme/theme.dart';
import '../../../theme/widgets.dart';
import '../bloc/booking_cubit.dart';
import 'widgets/booking_step_view.dart';

class ApprovedPage extends StatelessWidget {
  const ApprovedPage({super.key});

  @override
  Widget build(BuildContext context) => BookingStepView(
    step: BookingStep.approved,
    builder: (context, booking, s) => _ApprovedView(booking: booking, s: s),
  );
}

class _ApprovedView extends StatefulWidget {
  const _ApprovedView({required this.booking, required this.s});
  final Booking booking;
  final BookingState s;
  @override
  State<_ApprovedView> createState() => _ApprovedViewState();
}

class _ApprovedViewState extends State<_ApprovedView>
    with TickerProviderStateMixin {
  late final AnimationController _fall = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _pop.value = 1;
    } else {
      _fall.repeat();
    }
  }

  @override
  void dispose() {
    _fall.dispose();
    _pop.dispose();
    super.dispose();
  }

  Future<void> _calendar() async {
    final b = widget.booking;
    final date = DateTime.tryParse(b.date);
    if (date == null) return;
    String f(DateTime d) =>
        '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}T${d.hour.toString().padLeft(2, '0')}0000';
    final start = DateTime(date.year, date.month, date.day, b.startHour);
    final end = start.add(Duration(hours: b.durationHours));
    final uri = Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': 'Quodes · ${b.game?.name ?? 'Gaming'}',
      'dates': '${f(start)}/${f(end)}',
      'details': '${b.stationLabel} · ${b.players} players · Booking ${b.code}',
    });
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _invite() async {
    final b = widget.booking;
    final text = Uri.encodeComponent(
      'Squad up! ${b.game?.name ?? ''} at Quodes, ${b.dateLabel} ${b.timeLabel}, ${b.stationLabel}.',
    );
    final ok = await launchUrl(
      Uri.parse('https://wa.me/?text=$text'),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) showToast(context, 'Couldn’t open a share app');
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    final b = booking;
    const cols = [Q.primary, Q.pink, Q.cyan, Q.amber];
    return QBackground(
      hero: const QHeroImage(
        QPhoto.room,
        height: 360,
        focus: (50, 40),
        opacity: 0.5,
        fadeTop: 0.3,
        fadeMid: 0.62,
      ),
      grid: true,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _fall,
                builder: (_, _) => CustomPaint(
                  painter: _Confetti(
                    _fall.value,
                    cols,
                    enabled: !reduceMotion(context),
                  ),
                ),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            children: [
              Center(
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _pop,
                    curve: Curves.elasticOut,
                  ),
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: CustomPaint(
                      painter: HexPainter(fill: Q.green, stroke: Q.green),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'GG! YOU’RE IN',
                textAlign: TextAlign.center,
                style: display(30, color: Q.green, spacing: 0.08),
              ),
              const SizedBox(height: 8),
              Text(
                'Thanks for booking with Quodes. Our team verified your payment and your session is confirmed.',
                textAlign: TextAlign.center,
                style: body(15, color: Q.text2, height: 1.5),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Q.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Q.greenBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      color: Q.greenBg,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'BOOKING ID',
                              style: label(11, color: Q.green),
                            ),
                          ),
                          Text(
                            b.code,
                            style: display(13, color: Q.green, spacing: 0.06),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F2A12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Q.greenDeep),
                            ),
                            child: GameArt.has(b.game?.mono ?? '')
                                ? SizedBox.expand(child: GameArt(b.game!.mono))
                                : Text(
                                    b.game?.mono ?? '',
                                    style: display(14, color: Q.green),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${b.dateLabel} · ${b.timeLabel}',
                                  style: body(16, weight: FontWeight.w700),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${b.stationLabel} · ${b.players} ${b.players == 1 ? 'player' : 'players'}',
                                  style: body(13, color: Q.text3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Q.borderHi)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              b.creditApplied > 0 && b.amountDue == 0
                                  ? 'Paid with credit'
                                  : 'Paid via UPI',
                              style: body(14, color: Q.text3),
                            ),
                          ),
                          Text('₹${rupees(b.total)}', style: display(15)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: 'Add to calendar',
                      icon: Icons.event_rounded,
                      onPressed: _calendar,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GhostButton(
                      label: 'Invite squad',
                      icon: Icons.share_rounded,
                      onPressed: _invite,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'BACK TO GAMES',
                onPressed: () => context.go(Routes.games),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Arrive 10 min early · Need to reschedule?',
                    style: body(13, color: Q.text3),
                  ),
                  TextLink(
                    'Support',
                    size: 13,
                    onTap: () => context.goSupport(bookingCode: b.code),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Confetti extends CustomPainter {
  final double t;
  final List<Color> cols;
  final bool enabled;
  _Confetti(this.t, this.cols, {required this.enabled});
  @override
  void paint(Canvas canvas, Size size) {
    if (!enabled) return;
    for (var i = 0; i < 14; i++) {
      final speed = 1 + (i % 5) * 0.15;
      final phase = ((t * speed) + i * 0.09) % 1.0;
      final x = ((i * 37) % 100) / 100 * size.width;
      final y = -40 + phase * 460;
      final s = 6.0 + (i % 3) * 2;
      final c = cols[i % 4];
      final opacity = phase < 0.1 ? phase * 10 : 1 - phase;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(phase * 3 * math.pi);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: s, height: s),
        Paint()..color = c.withValues(alpha: opacity.clamp(0, 1)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _Confetti old) => old.t != t;
}
