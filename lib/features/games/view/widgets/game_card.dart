import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../data/models/models.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/game_art.dart';
import '../../../../theme/theme.dart';

/// Game card for the Games grid: full-bleed cover art with a bottom scrim
/// carrying the title and a single line of meta (genre · players · platforms).
class GameTile extends StatefulWidget {
  final Game game;
  final VoidCallback onTap;

  /// Kept for API compatibility with the grid (was used to stagger effects).
  final int index;
  const GameTile({
    super.key,
    required this.game,
    required this.onTap,
    this.index = 0,
  });

  /// Grid row height (portrait poster).
  static const double height = 240;

  @override
  State<GameTile> createState() => _GameTileState();
}

class _GameTileState extends State<GameTile> {
  bool _down = false;

  void _press(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final hue = hexColor(g.hue);
    final deep = hexColor(g.deep, Q.surface);
    final calm = MediaQuery.of(context).disableAnimations;
    final radius = BorderRadius.circular(14);
    final players = g.maxPlayers > 1 ? '1–${g.maxPlayers} players' : '1 player';

    return Semantics(
      button: true,
      label:
          '${g.name}, ${g.genre.toLowerCase()}, up to ${g.maxPlayers} players, '
          '${g.platformNames.join(', ')}',
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => _press(true),
        onTapUp: (_) => _press(false),
        onTapCancel: () => _press(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down && !calm ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x59000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Artwork covers the whole card.
                  ColoredBox(
                    color: deep,
                    child: GameArt.has(g.mono, g.coverUrl)
                        ? GameArt(
                            g.mono,
                            url: g.coverUrl,
                            fit: BoxFit.cover,
                            fallback: _Fallback(game: g, hue: hue, deep: deep),
                          )
                        : _Fallback(game: g, hue: hue, deep: deep),
                  ),
                  // Bottom scrim for legible text.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0, 0.45, 1],
                        colors: [
                          Color(0x00000000),
                          Color(0x1A000000),
                          Color(0xE6050A1C),
                        ],
                      ),
                    ),
                  ),
                  // Genre pill.
                  Positioned(
                    left: 10,
                    top: 10,
                    child: _Pill(text: g.genre.toUpperCase()),
                  ),
                  // Title + meta.
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          g.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: display(
                            15,
                            color: Colors.white,
                          ).copyWith(height: 1.2),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.group_rounded,
                              size: 13,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              players,
                              style: body(
                                11,
                                color: Colors.white.withValues(alpha: 0.75),
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (g.platformNames.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            g.platformNames.join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: body(
                              11,
                              color: Colors.white.withValues(alpha: 0.55),
                              weight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0x99050A1C),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
    ),
    child: Text(
      text,
      style: body(
        9,
        color: Colors.white,
        weight: FontWeight.w700,
        spacing: 0.8,
      ),
    ),
  );
}

/// Games added in the admin panel have no artwork: painted pattern + code.
class _Fallback extends StatelessWidget {
  const _Fallback({required this.game, required this.hue, required this.deep});
  final Game game;
  final Color hue, deep;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      CustomPaint(
        painter: _MotifPainter(hue: hue, deep: deep, seed: game.mono),
      ),
      Center(
        child: Text(
          game.mono,
          style: display(
            30,
            color: Colors.white,
            spacing: 0.06,
          ).copyWith(shadows: [Shadow(color: hue, blurRadius: 18)]),
        ),
      ),
    ],
  );
}

class _MotifPainter extends CustomPainter {
  final Color hue, deep;
  final String seed;
  _MotifPainter({required this.hue, required this.deep, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final dark = Color.lerp(
      deep,
      Q.bg,
      deep.computeLuminance() > 0.5 ? 0.85 : 0.2,
    )!;
    canvas.drawRect(Offset.zero & size, Paint()..color = dark);
    final r = math.Random(seed.hashCode);
    final stripe = Paint()..color = hue.withValues(alpha: 0.12);
    for (var i = 0; i < 4; i++) {
      final x = r.nextDouble() * size.width;
      canvas.drawRect(
        Rect.fromLTWH(x, 0, 14 + r.nextDouble() * 18, size.height),
        stripe,
      );
    }
    final ring = Paint()
      ..color = hue.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final c = Offset(
      size.width * (0.3 + r.nextDouble() * 0.4),
      size.height * 0.5,
    );
    canvas.drawCircle(c, size.height * 0.32, ring);
    canvas.drawRect(
      Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
      ring..color = hue.withValues(alpha: 0.25),
    );
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [hue.withValues(alpha: 0.45), hue.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: c, radius: size.height * 0.6));
    canvas.drawCircle(c, size.height * 0.6, glow);
  }

  @override
  bool shouldRepaint(covariant _MotifPainter old) =>
      old.hue != hue || old.seed != seed;
}
