import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/routes.dart';
import '../../../data/models/models.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import '../../../theme/widgets.dart';
import '../bloc/booking_cubit.dart';
import 'widgets/booking_step_view.dart';

class PayPage extends StatelessWidget {
  const PayPage({super.key});

  @override
  Widget build(BuildContext context) => BookingStepView(
    step: BookingStep.pay,
    builder: (context, booking, s) => _PayView(booking: booking, s: s),
  );
}

class _PayView extends StatefulWidget {
  const _PayView({required this.booking, required this.s});
  final Booking booking;
  final BookingState s;
  @override
  State<_PayView> createState() => _PayViewState();
}

class _PayViewState extends State<_PayView> {
  bool _copied = false;

  Future<void> _openUpi(Booking booking) async {
    final uri = Uri.tryParse(booking.upiUri);
    var ok = false;
    if (uri != null) {
      try {
        ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
    if (!mounted) return;
    if (!ok) {
      showToast(context, 'No UPI app found. Scan the QR from another phone.');
    } else {
      context.pushBooking(booking, BookingStep.upload);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    final b = booking;
    return QBackground(
      hero: const QHeroImage(
        QPhoto.streaks,
        height: 320,
        focus: (50, 40),
        opacity: 0.8,
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              children: [
                Row(
                  children: [
                    const SquareIconButton(semantic: 'Back'),
                    const SizedBox(width: 12),
                    Expanded(child: Text('PAY WITH UPI', style: display(20))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Q.amberBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Q.amberBorder),
                      ),
                      child: Row(
                        children: [
                          const BlinkDot(color: Q.amber),
                          const SizedBox(width: 6),
                          Text(
                            mmss(b.lockLeft),
                            style: display(14, color: Q.amber),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Panel(
                  radius: 20,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Text('AMOUNT TO PAY', style: label(11)),
                      const SizedBox(height: 4),
                      Text(
                        '₹${rupees(b.amountDue)}',
                        style: display(34, spacing: 0),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Color(0x592F6BFF), blurRadius: 24),
                          ],
                        ),
                        child: Semantics(
                          label: 'UPI payment QR code',
                          child: b.upiUri.isEmpty
                              ? const SizedBox(width: 200, height: 200)
                              : QrImageView(
                                  data: b.upiUri,
                                  size: 200,
                                  padding: EdgeInsets.zero,
                                  backgroundColor: Colors.white,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: Q.bg,
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: Q.bg,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.only(left: 14),
                        decoration: BoxDecoration(
                          color: Q.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Q.borderHi),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                b.upiId,
                                overflow: TextOverflow.ellipsis,
                                style: body(15, weight: FontWeight.w800),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: b.upiId),
                                );
                                if (mounted) setState(() => _copied = true);
                              },
                              style: TextButton.styleFrom(
                                minimumSize: const Size(64, 44),
                              ),
                              child: Text(
                                _copied ? 'Copied' : 'Copy',
                                style: body(
                                  13,
                                  color: Q.link,
                                  weight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Scan with any UPI app, or tap below to pay on this phone',
                        textAlign: TextAlign.center,
                        style: body(13, color: Q.text3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ...[
                  ('01', 'Pay the exact amount'),
                  ('02', 'Screenshot the success screen'),
                  ('03', 'Upload it here to verify'),
                ].map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Q.pinkBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            s.$1,
                            style: display(12, color: Q.pinkText),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          s.$2,
                          style: body(
                            14,
                            color: Q.text2,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
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
                  label: 'OPEN IN UPI APP',
                  icon: Icons.open_in_new_rounded,
                  onPressed: () => _openUpi(b),
                ),
                const SizedBox(height: 6),
                TextLink(
                  'I’ve paid · Upload screenshot',
                  onTap: () => context.pushBooking(b, BookingStep.upload),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
