import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import '../../../theme/widgets.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../booking_flow/bloc/booking_flow_cubit.dart';
import '../bloc/games_cubit.dart';
import 'widgets/game_card.dart';

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => GamesCubit(ctx.read<CatalogRepository>())..load(),
    child: const _GamesView(),
  );
}

class _GamesView extends StatefulWidget {
  const _GamesView();
  @override
  State<_GamesView> createState() => _GamesViewState();
}

class _GamesViewState extends State<_GamesView> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GamesCubit>();
    final state = context.watch<GamesCubit>().state;
    final user = context.select((AuthBloc a) => a.state.user);
    final cafe = state.cafe;
    final games = state.games;
    final genres = state.genres;
    return QBackground(
      child: state.error != null && games == null
          ? ErrorView(error: state.error!, onRetry: cubit.load)
          : RefreshIndicator(
              onRefresh: cubit.load,
              color: Q.link,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    sliver: SliverList.list(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CustomPaint(
                                painter: HexPainter(
                                  fill: Colors.white,
                                  stroke: Q.link,
                                  strokeWidth: 2,
                                ),
                                child: Center(
                                  child: Text(
                                    'Q',
                                    style: display(17, color: Q.link),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'QUODES',
                                    style: display(18, spacing: 0.12),
                                  ),
                                  if (cafe != null)
                                    Row(
                                      children: [
                                        BlinkDot(
                                          color: cafe.openNow ? Q.green : Q.red,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          cafe.openNow
                                              ? 'OPEN NOW · till ${cafe.closesAt}'
                                              : 'CLOSED · opens ${cafe.opensAt}',
                                          style: label(
                                            11,
                                            color: cafe.openNow
                                                ? Q.green
                                                : Q.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            Semantics(
                              button: true,
                              label: 'Profile',
                              excludeSemantics: true,
                              child: GestureDetector(
                                onTap: () => context.go(Routes.profile),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Q.pinkBg,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Q.pink,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    user?.initials ?? '··',
                                    style: display(15, color: Q.pinkText),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          height: 124,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Q.border),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x402F6BFF),
                                blurRadius: 30,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                QPhoto.controller.asset,
                                fit: BoxFit.cover,
                                alignment: const Alignment(0, 0.6),
                                excludeFromSemantics: true,
                              ),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    stops: [0, 0.55, 1],
                                    colors: [
                                      Color(0xF00A1330),
                                      Color(0x990A1330),
                                      Color(0x0D0A1330),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'PICK YOUR GAME',
                                      style: display(
                                        24,
                                        color: Colors.white,
                                        spacing: 0.03,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Station 5 · Station 4 · Gaming PC · by the hour',
                                      style: body(
                                        13,
                                        color: Q.text2,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Semantics(
                          label: 'Search games',
                          child: TextField(
                            controller: _q,
                            onChanged: cubit.search,
                            style: body(15),
                            textInputAction: TextInputAction.search,
                            decoration: const InputDecoration(
                              hintText: 'Search games',
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: Q.text3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: genres.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, i) => QChip(
                              label: genres[i],
                              height: 40,
                              selected: genres[i] == state.genre,
                              onTap: () => cubit.selectGenre(genres[i]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                  if (games == null)
                    const SliverFillRemaining(child: LoadingView())
                  else if (games.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No games match',
                          style: body(14, color: Q.text3),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      sliver: SliverGrid.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              mainAxisExtent: GameTile.height,
                            ),
                        itemCount: games.length,
                        itemBuilder: (_, i) => GameTile(
                          index: i,
                          game: games[i],
                          onTap: () {
                            context.read<BookingFlowCubit>().start(games[i]);
                            context.push(Routes.station);
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
