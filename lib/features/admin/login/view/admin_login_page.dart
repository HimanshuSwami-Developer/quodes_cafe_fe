import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/theme.dart';
import '../../../../theme/widgets.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/login_cubit.dart';
import '../../common/view/admin_ui.dart';

/// Staff sign-in for the web admin panel. On success the router guard
/// moves on to [from] (or the dashboard).
class AdminLoginPage extends StatelessWidget {
  /// [denied] is set when a signed-in player was bounced here.
  const AdminLoginPage({super.key, this.from, this.denied = false});

  /// The admin page the user asked for (resumed after login).
  final String? from;

  /// A non-staff account tried to open the panel.
  final bool denied;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => LoginCubit(ctx.read<AuthRepository>()),
    child: BlocListener<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state.status.isSuccess && state.user != null) {
          // The guard redirects on the new auth state (or flags a player).
          context.read<AuthBloc>().add(AuthLoggedIn(state.user!));
        }
      },
      child: _AdminLoginView(from: from, denied: denied),
    ),
  );
}

class _AdminLoginView extends StatefulWidget {
  const _AdminLoginView({this.from, required this.denied});
  final String? from;
  final bool denied;

  @override
  State<_AdminLoginView> createState() => _AdminLoginViewState();
}

class _AdminLoginViewState extends State<_AdminLoginView> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _show = false;

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  void _submit() => context.read<LoginCubit>().submit(_email.text, _pw.text);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final notStaff =
        auth.status == AuthStatus.authenticated &&
        !(auth.user?.isStaff ?? false);
    final denied = widget.denied || notStaff;
    final login = context.watch<LoginCubit>().state;

    return Scaffold(
      backgroundColor: Q.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Panel(
              padding: const EdgeInsets.all(28),
              radius: 18,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: QLogo(size: 64)),
                    const SizedBox(height: 12),
                    Text(
                      'Quodes Staff',
                      textAlign: TextAlign.center,
                      style: display(24, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      denied
                          ? 'Signed in, but not as staff.'
                          : 'Sign in to verify payments and run the café.',
                      textAlign: TextAlign.center,
                      style: body(14, color: Q.text3),
                    ),
                    const SizedBox(height: 24),
                    if (denied && auth.status == AuthStatus.authenticated)
                      ..._deniedView(context, auth.user?.email ?? '')
                    else
                      ..._form(login),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _deniedView(BuildContext context, String email) => [
    FormErrorBanner(
      "This account isn't staff${email.isEmpty ? '' : ' ($email)'}. "
      'Log out and sign in with a staff account.',
    ),
    AdminButton(
      label: 'Log out',
      icon: Icons.logout_rounded,
      onPressed: () =>
          context.read<AuthBloc>().add(const AuthLogoutRequested()),
    ),
  ];

  List<Widget> _form(LoginState login) => [
    if (login.error != null) FormErrorBanner(login.error),
    AdminField(
      label: 'Email',
      controller: _email,
      hint: 'staff@quodes.gg',
      keyboard: TextInputType.emailAddress,
      autofocus: true,
      onSubmitted: (_) => _submit(),
    ),
    const SizedBox(height: 14),
    const FieldLabel('Password'),
    const SizedBox(height: 6),
    TextField(
      controller: _pw,
      obscureText: !_show,
      autofillHints: const [AutofillHints.password],
      onSubmitted: (_) => _submit(),
      style: body(14),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Password',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        suffixIcon: IconButton(
          tooltip: _show ? 'Hide password' : 'Show password',
          onPressed: () => setState(() => _show = !_show),
          icon: Icon(
            _show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Q.text3,
            size: 20,
          ),
        ),
      ),
    ),
    const SizedBox(height: 22),
    AdminButton(
      label: 'Sign in',
      icon: Icons.login_rounded,
      loading: login.status.isLoading,
      onPressed: _submit,
    ),
    if (widget.from != null && widget.from!.isNotEmpty) ...[
      const SizedBox(height: 12),
      Text(
        'You will continue to ${widget.from}',
        textAlign: TextAlign.center,
        style: body(12, color: Q.text3),
      ),
    ],
  ];
}
