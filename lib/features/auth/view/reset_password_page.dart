import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import '../../../theme/widgets.dart';
import '../bloc/auth_bloc.dart';
import '../../../theme/otp_input.dart';
import '../bloc/reset_password_cubit.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key, required this.sent});
  final CodeSent sent;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => ResetPasswordCubit(ctx.read<AuthRepository>(), sent),
    child: BlocListener<ResetPasswordCubit, ResetPasswordState>(
      listener: (context, state) {
        final msg = state.error ?? state.notice;
        if (msg != null) showToast(context, msg);
        if (!state.status.isSuccess) return;
        if (state.user != null) {
          context.read<AuthBloc>().add(AuthLoggedIn(state.user!));
        } else if (state.loginFailed) {
          context.go(Routes.login);
        }
      },
      child: _ResetPasswordView(sent: sent),
    ),
  );
}

class _ResetPasswordView extends StatefulWidget {
  const _ResetPasswordView({required this.sent});
  final CodeSent sent;
  @override
  State<_ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<_ResetPasswordView> {
  String _code = '';
  final _pw = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _pw.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() => context.read<ResetPasswordCubit>().submit(
    code: _code,
    confirm: _confirm.text,
  );

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ResetPasswordCubit>();
    final state = context.watch<ResetPasswordCubit>().state;

    final rules = state.rules;
    final score = rules.where((r) => r.$2).length;
    const cols = [Q.borderHi, Q.red, Q.amber, Q.link, Q.green];
    final col = cols[score];
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
            const SizedBox(height: 22),
            Text('NEW PASSWORD', style: display(22, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                style: body(15, color: Q.text3),
                children: [
                  const TextSpan(text: 'Enter the code sent to '),
                  TextSpan(
                    text: widget.sent.maskedEmail,
                    style: body(15, color: Q.text, weight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const FieldLabel('Verification code'),
            const SizedBox(height: 8),
            OtpInput(onChanged: (c) => _code = c),
            const SizedBox(height: 4),
            Row(
              children: [
                if (state.resendLeft > 0)
                  Text.rich(
                    TextSpan(
                      style: body(13, color: Q.text3),
                      children: [
                        const TextSpan(text: 'Resend code in '),
                        TextSpan(
                          text: mmss(Duration(seconds: state.resendLeft)),
                          style: body(
                            13,
                            color: Q.text,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  TextLink('Resend code', size: 13, onTap: cubit.resend),
              ],
            ),
            const SizedBox(height: 14),
            QField(
              label: 'New password',
              controller: _pw,
              hint: 'Create a strong password',
              obscure: true,
              autofill: const [AutofillHints.newPassword],
              onChanged: cubit.passwordChanged,
            ),
            const SizedBox(height: 12),
            Semantics(
              label: 'Password strength $score of 4',
              child: Row(
                children: List.generate(
                  4,
                  (i) => Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                      height: 6,
                      decoration: BoxDecoration(
                        color: i < score ? col : Q.borderHi,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: i < score
                            ? [BoxShadow(color: col, blurRadius: 8)]
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: rules
                  .map(
                    (r) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          r.$2
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked,
                          size: 16,
                          color: r.$2 ? Q.green : Q.text3,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          r.$1,
                          style: body(
                            13,
                            color: r.$2 ? Q.green : Q.text3,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            QField(
              label: 'Confirm password',
              controller: _confirm,
              hint: 'Re-enter password',
              obscure: true,
              autofill: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: 26),
            PrimaryButton(
              label: 'RESET & LOG IN',
              loading: state.status.isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
