import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import '../../../theme/widgets.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/register_cubit.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => RegisterCubit(ctx.read<AuthRepository>()),
    child: BlocListener<RegisterCubit, RegisterState>(
      listener: (context, state) {
        if (state.status.isSuccess) {
          if (state.codeSent != null) {
            context.go(Routes.verifyEmail, extra: state.codeSent);
          } else if (state.user != null) {
            context.read<AuthBloc>().add(AuthLoggedIn(state.user!));
          }
        } else if (state.status.isFailure && state.error != null) {
          showToast(context, state.error!);
        }
      },
      child: const _RegisterView(),
    ),
  );
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();
  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _tag = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pw = TextEditingController();

  @override
  void dispose() {
    for (final c in [_tag, _name, _email, _phone, _pw]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() => context.read<RegisterCubit>().submit(
    gamertag: _tag.text,
    fullName: _name.text,
    email: _email.text,
    phone: _phone.text,
    password: _pw.text,
  );

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RegisterCubit>().state;

    return QBackground(
      hero: const QHeroImage(
        QPhoto.room,
        height: 360,
        focus: (50, 45),
        opacity: 0.6,
        fadeTop: 0.3,
        fadeMid: 0.62,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: const SquareIconButton(semantic: 'Back to login'),
              ),
              const SizedBox(height: 24),
              Text('NEW PLAYER', style: display(22, weight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Create your account to book stations by the hour.',
                style: body(15, color: Q.text3, height: 1.5),
              ),
              const SizedBox(height: 24),
              QField(
                label: 'Gamertag',
                controller: _tag,
                hint: 'e.g. NightOwl',
                autofill: const [AutofillHints.nickname],
              ),
              const SizedBox(height: 16),
              QField(
                label: 'Full name',
                controller: _name,
                hint: 'Your name',
                autofill: const [AutofillHints.name],
              ),
              const SizedBox(height: 16),
              QField(
                label: 'Email',
                controller: _email,
                hint: 'player@email.com',
                keyboard: TextInputType.emailAddress,
                autofill: const [AutofillHints.email],
              ),
              const SizedBox(height: 16),
              QField(
                label: 'Phone',
                controller: _phone,
                hint: '+91',
                keyboard: TextInputType.phone,
                autofill: const [AutofillHints.telephoneNumber],
              ),
              const SizedBox(height: 16),
              QField(
                label: 'Password',
                controller: _pw,
                hint: 'Create a strong password',
                obscure: true,
                autofill: const [AutofillHints.newPassword],
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'CREATE ACCOUNT',
                loading: state.status.isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already playing?', style: body(14, color: Q.text3)),
                  TextLink('Log in', onTap: () => popOrGames(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
