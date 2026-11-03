import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import '../../../theme/widgets.dart';
import '../bloc/auth_bloc.dart';
import '../../../theme/otp_input.dart';
import '../bloc/verify_email_cubit.dart';

/// After signup (or an unverified login): enter the 6-digit code we emailed.
class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({super.key, required this.sent});
  final CodeSent sent;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => VerifyEmailCubit(ctx.read<AuthRepository>(), sent),
    child: BlocListener<VerifyEmailCubit, VerifyEmailState>(
      listener: (context, state) {
        if (state.status.isSuccess && state.user != null) {
          context.read<AuthBloc>().add(AuthLoggedIn(state.user!));
        }
        final msg = state.error ?? state.notice;
        if (msg != null) showToast(context, msg);
      },
      child: _VerifyEmailView(sent: sent),
    ),
  );
}

class _VerifyEmailView extends StatefulWidget {
  const _VerifyEmailView({required this.sent});
  final CodeSent sent;
  @override
  State<_VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<_VerifyEmailView> {
  String _code = '';

  void _submit() => context.read<VerifyEmailCubit>().verify(_code);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VerifyEmailCubit>();
    final state = context.watch<VerifyEmailCubit>().state;

    return QBackground(
      hero: const QHeroImage(QPhoto.streaks, height: 320, opacity: 0.8),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: SquareIconButton(semantic: 'Back'),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Q.surfaceHi,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Q.primary),
                ),
                child: const Icon(
                  Icons.mark_email_unread_rounded,
                  color: Q.link,
                  size: 30,
                  semanticLabel: 'Email',
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'CHECK YOUR INBOX',
              style: display(22, weight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                style: body(15, color: Q.text3, height: 1.5),
                children: [
                  const TextSpan(text: 'We sent a 6-digit code to '),
                  TextSpan(
                    text: widget.sent.maskedEmail,
                    style: body(15, color: Q.text, weight: FontWeight.w700),
                  ),
                  const TextSpan(text: '. Enter it to activate your account.'),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const FieldLabel('Verification code'),
            const SizedBox(height: 8),
            OtpInput(
              onChanged: (c) => _code = c,
              onCompleted: (c) {
                _code = c;
                _submit();
              },
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (state.resendLeft > 0)
                  Text(
                    'Resend code in ${mmss(Duration(seconds: state.resendLeft))}',
                    style: body(13, color: Q.text3),
                  )
                else
                  TextLink('Resend code', size: 13, onTap: cubit.resend),
              ],
            ),
            const SizedBox(height: 26),
            PrimaryButton(
              label: 'VERIFY & START',
              loading: state.status.isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            Text(
              'Not in your inbox? Check spam or promotions. The code expires in 10 minutes.',
              textAlign: TextAlign.center,
              style: body(13, color: Q.text3, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
