import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/routes.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import '../../../theme/widgets.dart';
import '../bloc/forgot_password_cubit.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => ForgotPasswordCubit(
      ctx.read<AuthRepository>(),
      ctx.read<CatalogRepository>(),
    ),
    child: BlocListener<ForgotPasswordCubit, ForgotPasswordState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.status.isSuccess && state.sent != null) {
          context.push(Routes.resetPassword, extra: state.sent);
        } else if (state.status.isFailure && state.error != null) {
          showToast(context, state.error!);
        }
      },
      child: const _ForgotPasswordView(),
    ),
  );
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();
  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!reduceMotion(context)) _spin.repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    _email.dispose();
    super.dispose();
  }

  void _submit() => context.read<ForgotPasswordCubit>().submit(_email.text);

  /// Logged-out players can't open the support tab: call the desk instead,
  /// or fall back to the public policies page.
  Future<void> _support(String phone) async {
    if (phone.isNotEmpty && await launchUrl(Uri(scheme: 'tel', path: phone))) {
      return;
    }
    if (mounted) context.push(Routes.policies);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ForgotPasswordCubit>().state;

    return QBackground(
      hero: const QHeroImage(QPhoto.neonSetup, height: 360, opacity: 0.7),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: SquareIconButton(semantic: 'Back to login'),
            ),
            const SizedBox(height: 26),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  children: [
                    RotationTransition(
                      turns: _spin,
                      child: CustomPaint(
                        size: const Size(72, 72),
                        painter: _DashedCircle(),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: Q.pinkBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.key_rounded,
                          color: Q.pinkSoft,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 26),
            Text('LOST YOUR KEY?', style: display(22, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Enter your account email. We’ll send a 6-digit code to reset your password.',
              style: body(15, color: Q.text3, height: 1.55),
            ),
            const SizedBox(height: 26),
            QField(
              label: 'Email',
              controller: _email,
              hint: 'player@email.com',
              keyboard: TextInputType.emailAddress,
              autofill: const [AutofillHints.email],
            ),
            const SizedBox(height: 26),
            PrimaryButton(
              label: 'SEND CODE',
              loading: state.status.isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 26),
            Panel(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Q.link,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'The code expires in 10 minutes. Not in your inbox? Check spam or ping ',
                          style: body(13, color: Q.text2, height: 1.5),
                        ),
                        GestureDetector(
                          onTap: () => _support(state.supportPhone),
                          child: Text(
                            'Support.',
                            style: body(
                              13,
                              color: Q.link,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Remembered it?', style: body(14, color: Q.text3)),
                TextLink('Back to login', onTap: () => popOrGames(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedCircle extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Q.pink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const n = 24;
    final rect = Offset.zero & size;
    for (var i = 0; i < n; i++) {
      final start = i * 2 * 3.14159 / n;
      canvas.drawArc(rect.deflate(1), start, 3.14159 / n, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
