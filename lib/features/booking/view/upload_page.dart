import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/router/routes.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/models.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import '../../../theme/widgets.dart';
import '../bloc/booking_cubit.dart';
import 'widgets/booking_step_view.dart';

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) => BookingStepView(
    step: BookingStep.upload,
    builder: (context, booking, s) => _UploadView(booking: booking, s: s),
  );
}

class _UploadView extends StatefulWidget {
  const _UploadView({required this.booking, required this.s});
  final Booking booking;
  final BookingState s;
  @override
  State<_UploadView> createState() => _UploadViewState();
}

class _UploadViewState extends State<_UploadView> {
  XFile? _file;
  Uint8List? _bytes; // preview; Image.file doesn't exist on the web
  int _size = 0;
  late final _utr = TextEditingController(text: widget.booking.utr);

  @override
  void dispose() {
    _utr.dispose();
    super.dispose();
  }

  Future<void> _choose() async {
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        imageQuality: 90,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      final size = bytes.length;
      if (size > Validators.maxScreenshotBytes) {
        if (mounted) showToast(context, 'Screenshot must be under 5 MB');
        return;
      }
      setState(() {
        _file = x;
        _bytes = bytes;
        _size = size;
      });
    } catch (e) {
      if (mounted) showError(context, 'Couldn’t open your photos: $e');
    }
  }

  void _submit() {
    final utr = _utr.text.trim();
    if (!Validators.isValidUtr(utr)) {
      showToast(context, 'UTR is the 12-digit reference number');
      return;
    }
    // Success moves the booking to `scanning`; BookingStepView routes on.
    context.read<BookingCubit>().uploadProof(_file!, utr: utr);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;

    final f = _file;
    return QBackground(
      hero: const QHeroImage(
        QPhoto.streaks,
        height: 300,
        focus: (40, 50),
        opacity: 0.75,
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
                    Text('UPLOAD PROOF', style: display(20)),
                  ],
                ),
                const SizedBox(height: 16),
                if (f == null)
                  Semantics(
                    button: true,
                    label: 'Choose payment screenshot',
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: _choose,
                      child: CustomPaint(
                        painter: _DashedBorder(),
                        child: Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: Q.surfaceHi,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.upload_rounded,
                                  color: Q.link,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'DROP SCREENSHOT',
                                style: display(16, spacing: 0.08),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'PNG or JPG · up to 5 MB',
                                style: body(13, color: Q.text3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Panel(
                    radius: 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Semantics(
                            label: 'Screenshot preview',
                            image: true,
                            child: Image.memory(
                              _bytes!,
                              width: 84,
                              height: 140,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                f.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: body(14, weight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(_size / (1024 * 1024)).toStringAsFixed(1)} MB · Ready',
                                style: body(
                                  12,
                                  color: Q.green,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: const LinearProgressIndicator(
                                  value: 1,
                                  minHeight: 6,
                                  backgroundColor: Q.border,
                                  color: Q.green,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: GhostButton(
                                      label: 'Replace',
                                      height: 44,
                                      onPressed: _choose,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: GhostButton(
                                      label: 'Remove',
                                      height: 44,
                                      color: Q.redText,
                                      onPressed: () => setState(() {
                                        _file = null;
                                        _bytes = null;
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const FieldLabel('UPI transaction ID / UTR'),
                    const SizedBox(width: 6),
                    Text('(optional)', style: body(12, color: Q.text3)),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _utr,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  style: body(15, weight: FontWeight.w700),
                  decoration: const InputDecoration(
                    hintText: '12-digit reference number',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Speeds up verification if the screenshot is unclear.',
                  style: body(12, color: Q.text3),
                ),
                const SizedBox(height: 18),
                Text('SCREENSHOT MUST SHOW', style: display(14, spacing: 0.06)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      [
                            'Amount paid',
                            '“Success” status',
                            'UTR / Txn ID',
                            'Date & time',
                          ]
                          .map(
                            (t) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Q.greenBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Q.greenBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: Q.green,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    t,
                                    style: body(
                                      13,
                                      color: Q.greenText,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: f == null
                ? SizedBox(
                    height: 54,
                    child: Center(
                      child: Text(
                        'Add a screenshot to continue',
                        style: body(
                          14,
                          color: Q.text3,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                : PrimaryButton(
                    label: 'SUBMIT FOR SCAN',
                    loading: s.action == BookingAction.uploading,
                    onPressed: _submit,
                  ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(18),
    );
    canvas.drawRRect(rrect, Paint()..color = const Color(0x99111C42));
    final path = Path()..addRRect(rrect);
    final p = Paint()
      ..color = Q.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 14) {
        canvas.drawPath(m.extractPath(d, d + 7), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
