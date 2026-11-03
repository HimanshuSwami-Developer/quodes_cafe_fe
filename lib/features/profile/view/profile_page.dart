import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/routes.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import '../../../theme/widgets.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/profile_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) {
      ctx.read<AuthBloc>().add(const AuthUserRefreshRequested());
      return ProfileCubit(
        ctx.read<AuthRepository>(),
        ctx.read<BookingRepository>(),
      )..load();
    },
    child: BlocListener<ProfileCubit, ProfileState>(
      listenWhen: (a, b) => a.saveStatus != b.saveStatus,
      listener: (context, state) {
        if (state.saveStatus.isSuccess) {
          context.read<AuthBloc>().add(const AuthUserRefreshRequested());
          showToast(context, 'Profile saved');
        } else if (state.saveStatus.isFailure && state.error != null) {
          showToast(context, state.error!.message);
        }
      },
      child: const _ProfileView(),
    ),
  );
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  Future<void> _refresh(BuildContext context) async {
    context.read<AuthBloc>().add(const AuthUserRefreshRequested());
    await context.read<ProfileCubit>().load();
  }

  Future<void> _edit(BuildContext context, User u) async {
    final tag = TextEditingController(text: u.gamertag);
    final name = TextEditingController(text: u.fullName);
    final phone = TextEditingController(text: u.phone);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Q.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(c).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('EDIT PROFILE', style: display(18)),
            const SizedBox(height: 14),
            QField(label: 'Gamertag', controller: tag),
            const SizedBox(height: 12),
            QField(label: 'Full name', controller: name),
            const SizedBox(height: 12),
            QField(
              label: 'Phone',
              controller: phone,
              keyboard: TextInputType.phone,
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'SAVE',
              bob: false,
              onPressed: () => Navigator.pop(c, true),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !context.mounted) return;
    await context.read<ProfileCubit>().updateMe(
      gamertag: tag.text,
      fullName: name.text,
      phone: phone.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileCubit>();
    final state = context.watch<ProfileCubit>().state;
    final u = context.select((AuthBloc a) => a.state.user);
    final active = state.activeBookings;
    return QBackground(
      hero: const QHeroImage(
        QPhoto.neonSetup,
        height: 300,
        focus: (50, 45),
        opacity: 0.6,
      ),
      child: u == null && state.error != null
          ? ErrorView(error: state.error!, onRetry: cubit.load)
          : u == null
          ? const LoadingView()
          : RefreshIndicator(
              onRefresh: () => _refresh(context),
              color: Q.link,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                children: [
                  Text('PLAYER PROFILE', style: display(20)),
                  const SizedBox(height: 16),
                  Panel(
                    radius: 18,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: CustomPaint(
                            painter: HexPainter(fill: Q.pinkBg, stroke: Q.pink),
                            child: Center(
                              child: Text(
                                u.initials,
                                style: display(20, color: Q.pinkText),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.gamertag,
                                style: display(18, color: Q.link),
                              ),
                              Text(
                                u.fullName,
                                style: body(15, weight: FontWeight.w700),
                              ),
                              Text(
                                '${u.email}${u.phone.isEmpty ? '' : ' · ${u.phone}'}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: body(12, color: Q.text3),
                              ),
                            ],
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: 'Edit profile',
                          excludeSemantics: true,
                          child: IconButton(
                            onPressed: () => _edit(context, u),
                            iconSize: 20,
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Q.text2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _stat(
                        u.hoursPlayed == u.hoursPlayed.roundToDouble()
                            ? u.hoursPlayed.toStringAsFixed(0)
                            : u.hoursPlayed.toStringAsFixed(1),
                        'HOURS PLAYED',
                        Q.link,
                      ),
                      const SizedBox(width: 8),
                      _stat('${u.sessions}', 'SESSIONS', Q.pinkText),
                      const SizedBox(width: 8),
                      _stat('₹${rupees(u.credit)}', 'GAME CREDIT', Q.green),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (active == null)
                    const SizedBox(height: 80, child: LoadingView())
                  else ...[
                    if (active.isNotEmpty) ...[
                      Text('ACTIVE BOOKINGS', style: label(12)),
                      const SizedBox(height: 8),
                    ],
                    ...active.map((b) => _bookingCard(context, b)),
                  ],
                  const SizedBox(height: 8),
                  _link(
                    Icons.description_outlined,
                    'Policies',
                    () => context.push(Routes.policies),
                  ),
                  _link(
                    Icons.help_outline_rounded,
                    'Help & FAQ',
                    () => context.go(Routes.help),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: Q.redBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Q.redBorder),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => context.read<AuthBloc>().add(
                        const AuthLogoutRequested(),
                      ),
                      child: SizedBox(
                        height: 52,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.logout_rounded,
                              color: Q.redText,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Log out',
                              style: body(
                                15,
                                color: Q.redText,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _stat(String v, String l, Color c) => Expanded(
    child: Panel(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          FittedBox(
            child: Text(v, style: display(22, color: c, spacing: 0)),
          ),
          const SizedBox(height: 4),
          Text(l, textAlign: TextAlign.center, style: label(10)),
        ],
      ),
    ),
  );

  Widget _bookingCard(BuildContext context, Booking b) {
    final (Color c, Color bg) = switch (b.status) {
      'confirmed' => (Q.green, Q.greenBg),
      'ai_failed' => (Q.red, Q.redBg),
      'locked' => (Q.link, Q.surfaceHi),
      _ => (Q.amber, Q.amberBg),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Q.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.goBooking(b),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(b.shortGame, style: display(12, color: c)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${b.dateLabel} · ${b.timeLabel}',
                        style: body(14, weight: FontWeight.w800),
                      ),
                      Text(
                        '${b.stationLabel} · ${b.statusLabel}',
                        style: body(12, color: c, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Q.text3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _link(IconData i, String t, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: Q.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Q.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(i, color: Q.link, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(t, style: body(15, weight: FontWeight.w700)),
              ),
              const Icon(Icons.chevron_right_rounded, color: Q.text3),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    ),
  );
}
