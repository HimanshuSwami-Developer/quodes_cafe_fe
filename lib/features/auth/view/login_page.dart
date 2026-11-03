import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import '../../../theme/widgets.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/login_cubit.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key, this.expired = false});

  /// Arrived here because the session died (refresh token rejected).
  final bool expired;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => LoginCubit(ctx.read<AuthRepository>()),
    child: BlocListener<LoginCubit, LoginState>(
      listener: (context, state) {
        final sent = state.verificationRequired;
        if (sent != null) {
          if (state.error != null) showToast(context, state.error!);
          context.push(Routes.verifyEmail, extra: sent);
        } else if (state.status.isSuccess && state.user != null) {
          // The router redirects away from login on the new auth state.
          context.read<AuthBloc>().add(AuthLoggedIn(state.user!));
        } else if (state.status.isFailure && state.error != null) {
          showToast(context, state.error!);
        }
      },
      child: _LoginView(expired: expired),
    ),
  );
}

class _LoginView extends StatefulWidget {
  const _LoginView({required this.expired});
  final bool expired;
  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _show = false;
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void initState() {
    super.initState();
    if (widget.expired) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => showToast(context, 'Your session expired. Log in again.'),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!reduceMotion(context)) _float.repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  void _submit() => context.read<LoginCubit>().submit(_email.text, _pw.text);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LoginCubit>().state;

    return QBackground(
      hero: const QHeroImage(
        QPhoto.room,
        height: 400,
        focus: (50, 45),
        fadeTop: 0.3,
        fadeMid: 0.62,
      ),
      grid: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: AnimatedBuilder(
                  animation: _float,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(
                      0,
                      -8 * Curves.easeInOut.transform(_float.value),
                    ),
                    child: Transform.rotate(
                      angle: 0.07 * _float.value,
                      child: child,
                    ),
                  ),
                  child: const QLogo(),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'QUODES',
                textAlign: TextAlign.center,
                style: display(30, weight: FontWeight.w700, spacing: 0.12),
              ),
              Text(
                'GAMING',
                textAlign: TextAlign.center,
                style: display(
                  12,
                  color: Q.link,
                  weight: FontWeight.w700,
                  spacing: 0.5,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Welcome back, player',
                style: body(26, weight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Log in to lock your station and jump in.',
                style: body(15, color: Q.text3),
              ),
              const SizedBox(height: 28),
              QField(
                label: 'Email',
                controller: _email,
                hint: 'player@email.com',
                keyboard: TextInputType.emailAddress,
                autofill: const [AutofillHints.email],
              ),
              const SizedBox(height: 16),
              QField(
                label: 'Password',
                controller: _pw,
                hint: 'Enter password',
                obscure: !_show,
                autofill: const [AutofillHints.password],
                labelTrailing: TextLink(
                  'Forgot password?',
                  onTap: () => context.push(Routes.forgotPassword),
                ),
                suffix: Semantics(
                  button: true,
                  label: _show ? 'Hide password' : 'Show password',
                  excludeSemantics: true,
                  child: TextButton(
                    onPressed: () => setState(() => _show = !_show),
                    child: Text(
                      _show ? 'Hide' : 'Show',
                      style: body(13, color: Q.link, weight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'PRESS START',
                icon: Icons.play_arrow_rounded,
                loading: state.status.isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('New player?', style: body(14, color: Q.text3)),
                  TextLink(
                    'Create account',
                    onTap: () => context.push(Routes.register),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'By continuing you agree to our',
                      style: body(12, color: Q.text3),
                    ),
                  ),
                  TextLink(
                    'house rules & privacy',
                    size: 12,
                    onTap: () => context.push(Routes.policies),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
