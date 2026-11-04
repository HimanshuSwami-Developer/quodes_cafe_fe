import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../theme/colors.dart';
import '../../../theme/game_art.dart';
import '../../../theme/theme.dart';
import '../../../theme/widgets.dart';
import '../bloc/booking_flow_cubit.dart';
import '../bloc/station_cubit.dart';

class StationPage extends StatelessWidget {
  const StationPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => StationCubit(
      ctx.read<CatalogRepository>(),
      ctx.read<BookingFlowCubit>(),
    )..load(),
    child: BlocListener<StationCubit, StationState>(
      listenWhen: (a, b) =>
          b.notice != null || (b.error != null && a.error != b.error),
      listener: (context, state) {
        final msg = state.notice ?? state.error?.message;
        if (msg != null) showToast(context, msg);
      },
      child: const _StationView(),
    ),
  );
}

int _maxPlayers(Game? g) =>
    g == null || g.maxPlayers > BookingFlowCubit.maxPlayers
    ? BookingFlowCubit.maxPlayers
    : g.maxPlayers;

class _StationView extends StatelessWidget {
  const _StationView();

  void _toggle(BuildContext context, Seat seat, String station, int max) {
    if (!context.read<BookingFlowCubit>().toggleSeat(seat, station)) {
      showToast(context, 'Max $max players per booking');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StationCubit>();
    final state = context.watch<StationCubit>().state;
    final flow = context.watch<BookingFlowCubit>().state;
    final g = flow.game;
    final max = _maxPlayers(g);
    final sel = flow.seats;
    if (state.status.isFailure && state.types == null) {
      return QBackground(
        hero: const QHeroImage(
          QPhoto.room,
          height: 300,
          focus: (60, 50),
          opacity: 0.55,
          fadeTop: 0.3,
          fadeMid: 0.62,
        ),
        child: ErrorView(error: state.error!, onRetry: cubit.load),
      );
    }
    final types = state.types;
    final t = state.type;
    if (types == null || t == null) {
      return const QBackground(
        hero: QHeroImage(
          QPhoto.room,
          height: 300,
          focus: (60, 50),
          opacity: 0.55,
          fadeTop: 0.3,
          fadeMid: 0.62,
        ),
        child: LoadingView(),
      );
    }
    final groups = <String, int>{};
    for (final s in sel.map((x) => x.station)) {
      groups[s] = (groups[s] ?? 0) + 1;
    }
    final summary = sel.isEmpty
        ? 'No seats selected'
        : groups.entries
              .map(
                (e) => e.key + (t.seatsPerStation > 1 ? ' × ${e.value}' : ''),
              )
              .join(' · ');

    return QBackground(
      hero: const QHeroImage(
        QPhoto.room,
        height: 300,
        focus: (60, 50),
        opacity: 0.55,
        fadeTop: 0.3,
        fadeMid: 0.62,
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              children: [
                const Row(
                  children: [
                    SquareIconButton(semantic: 'Back to games'),
                    Spacer(),
                    StepDots(step: 2),
                  ],
                ),
                const SizedBox(height: 14),
                if (g != null) _GameBanner(game: g),
                const SizedBox(height: 14),
                Semantics(
                  label: 'Station type',
                  child: Row(
                    children: types.map((x) {
                      final on = x.code == t.code;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: x == types.last ? 0 : 8,
                          ),
                          child: Semantics(
                            inMutuallyExclusiveGroup: true,
                            checked: on,
                            button: true,
                            child: GestureDetector(
                              onTap: () => cubit.selectType(x),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: on
                                      ? Q.surfaceHi
                                      : const Color(0xE0111C42),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: on ? Q.primary : Q.borderHi,
                                    width: 1.5,
                                  ),
                                  boxShadow: on
                                      ? const [
                                          BoxShadow(
                                            color: Color(0x662F6BFF),
                                            blurRadius: 18,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Opacity(
                                  opacity: x.enabled ? 1 : 0.45,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        x.name,
                                        style: display(
                                          17,
                                          color: on ? Q.link : Q.text,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        x.enabled
                                            ? '${x.freeSeats}/${x.totalSeats} seats free'
                                            : 'Not on ${x.name}',
                                        style: body(
                                          11,
                                          color: Q.text3,
                                          weight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    style: body(13, color: Q.text3),
                    children: [
                      TextSpan(text: '${t.spec} · '),
                      TextSpan(
                        text: '₹${rupees(t.hourlyRate)}/hr per seat',
                        style: body(13, color: Q.text, weight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Panel(
                  radius: 18,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'PICK YOUR SEATS',
                              style: display(15, spacing: 0.06),
                            ),
                          ),
                          Text(
                            t.seatsPerStation > 1
                                ? '${t.seatsPerStation} players per station'
                                : '1 player per PC',
                            style: body(
                              12,
                              color: Q.text3,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (state.mapLoading || state.map == null)
                        const SizedBox(height: 160, child: LoadingView())
                      else
                        _SeatGrid(
                          map: state.map!,
                          selected: flow.seatIds.toSet(),
                          onTap: (seat, station) =>
                              _toggle(context, seat, station, max),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Q.borderHi)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'COUNTER · ENTRANCE',
                              style: label(10, color: Q.muted),
                            ),
                          ),
                          const Expanded(child: Divider(color: Q.borderHi)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _legend(Q.greenBg, Q.green, 'Free'),
                          const SizedBox(width: 16),
                          _legend(Q.primary, Q.primary, 'Yours'),
                          const SizedBox(width: 16),
                          _legend(Q.surfaceLo, Q.borderHi, 'Booked'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: const BoxDecoration(
              color: Color(0xF00A1330),
              border: Border(top: BorderSide(color: Q.border)),
            ),
            child: Column(
              children: [
                Semantics(
                  liveRegion: true,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          summary,
                          overflow: TextOverflow.ellipsis,
                          style: body(14, weight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${sel.length} / $max players',
                        style: body(
                          13,
                          color: Q.text3,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                sel.isEmpty
                    ? Container(
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Q.borderHi),
                        ),
                        child: Text(
                          'TAP A SEAT TO CONTINUE',
                          style: display(14, color: Q.text3, spacing: 0.1),
                        ),
                      )
                    : PrimaryButton(
                        label:
                            'SEE AVAILABILITY · ${sel.length} ${sel.length == 1 ? 'SEAT' : 'SEATS'}',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () => context.push(Routes.availability),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color bg, Color border, String text) => Row(
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: border),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        text,
        style: body(12, color: Q.text3, weight: FontWeight.w700),
      ),
    ],
  );
}

class _SeatGrid extends StatelessWidget {
  final SeatMap map;
  final Set<int> selected;
  final void Function(Seat, String) onTap;
  const _SeatGrid({
    required this.map,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cols = map.cols.clamp(1, 5);
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 8.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: map.stations.map((p) {
            final freeCount = p.seats.where((s) => !s.busy).length;
            final mine = p.seats.any((s) => selected.contains(s.id));
            final full = freeCount == 0;
            return Semantics(
              label:
                  '${p.code}${full ? ', fully booked' : ', $freeCount of ${p.seats.length} seats free'}',
              child: Container(
                width: w,
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
                decoration: BoxDecoration(
                  color: mine
                      ? const Color(0x242F6BFF)
                      : full
                      ? const Color(0x990A1330)
                      : Q.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: mine ? Q.primary : Q.border),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: full
                            ? Q.borderHi
                            : mine
                            ? Q.link
                            : Q.cyan,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: full
                            ? null
                            : const [
                                BoxShadow(
                                  color: Color(0xB33FD0FF),
                                  blurRadius: 10,
                                ),
                              ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      p.code,
                      style: body(
                        11,
                        color: full ? Q.muted : Q.text,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: p.seats.map((s) {
                        final on = selected.contains(s.id);
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: s == p.seats.last ? 0 : 4,
                            ),
                            child: Semantics(
                              button: true,
                              enabled: !s.busy,
                              selected: on,
                              label:
                                  '${p.code} seat ${s.label}${s.busy
                                      ? ', booked'
                                      : on
                                      ? ', selected'
                                      : ', free'}',
                              excludeSemantics: true,
                              child: GestureDetector(
                                onTap: s.busy ? null : () => onTap(s, p.code),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: s.busy
                                        ? Q.surfaceLo
                                        : on
                                        ? Q.primary
                                        : Q.greenBg,
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                      color: s.busy
                                          ? Q.borderHi
                                          : on
                                          ? Q.primary
                                          : Q.green,
                                    ),
                                    boxShadow: on
                                        ? const [
                                            BoxShadow(
                                              color: Color(0x992F6BFF),
                                              blurRadius: 14,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    s.label,
                                    style: body(
                                      12,
                                      color: s.busy
                                          ? Q.muted
                                          : on
                                          ? Colors.white
                                          : Q.greenText,
                                      weight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Selected game's cover art across the top of the booking screen.
class _GameBanner extends StatelessWidget {
  const _GameBanner({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    final g = game;
    final hue = hexColor(g.hue);
    final deep = hexColor(g.deep, Q.surface);
    final fallback = ColoredBox(
      color: Color.alphaBlend(hue.withValues(alpha: 0.25), deep),
      child: Center(
        child: Text(g.mono, style: display(28, color: Colors.white)),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 170,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: deep,
              child: GameArt.has(g.mono, g.bannerUrl ?? g.coverUrl)
                  ? GameArt(
                      g.mono,
                      url: g.bannerUrl ?? g.coverUrl,
                      fallback: fallback,
                    )
                  : fallback,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.3, 1],
                  colors: [Color(0x00000000), Color(0xE6050A1C)],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${g.genre} · UP TO ${g.maxPlayers} PLAYERS',
                          style: label(11, color: Colors.white70),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          g.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: body(
                            18,
                            color: Colors.white,
                            weight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextLink('Change', onTap: () => popOrGames(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
