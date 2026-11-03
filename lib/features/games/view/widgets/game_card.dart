import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../data/models/models.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/game_art.dart';
import '../../../../theme/theme.dart';

/// Game card for the Games grid: neon frame in the game's colour, HUD corner
/// brackets, scanlines over the artwork, genre + player badges, a play button
/// and full platform names.
class GameTile extends StatefulWidget {
  final Game game;
  final VoidCallback onTap;

  /// Staggers the shine sweep across tiles.
  final int index;
  const GameTile({
    super.key,
    required this.game,
    required this.onTap,
    this.index = 0,
  });

  /// Grid row height (art 128 + info panel).
  static const double height = 252;
  static const double _art = 128;

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
    final radius = BorderRadius.circular(18);

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
          scale: _down && !calm ? 0.96 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: hue.withValues(alpha: _down ? 0.95 : 0.55),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: hue.withValues(alpha: _down ? 0.55 : 0.28),
                  blurRadius: _down ? 26 : 16,
                  spreadRadius: _down ? 1 : -2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.5),
              child: Stack(
                children: [
                  // Info panel background: dark, tinted with the game colour.
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.alphaBlend(
                              hue.withValues(alpha: 0.22),
                              Q.surface,
                            ),
                            Color.alphaBlend(
                              hue.withValues(alpha: 0.08),
                              const Color(0xFF0B1434),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Artwork band.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: GameTile._art,
                    child: ColoredBox(
                      color: deep,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (GameArt.has(g.mono, g.coverUrl))
                            GameArt(
                              g.mono,
                              url: g.coverUrl,
                              fallback: _Fallback(
                                game: g,
                                hue: hue,
                                deep: deep,
                              ),
                            )
                          else
                            _Fallback(game: g, hue: hue, deep: deep),
                          const CustomPaint(painter: _Scanlines()),
                          // Fade the art into the info panel.
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0, 0.55, 1],
                                colors: [
                                  Colors.transparent,
                                  Colors.transparent,
                                  Color.alphaBlend(
                                    hue.withValues(alpha: 0.22),
                                    Q.surface,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          CustomPaint(painter: _HudCorners(hue)),
                          _Shine(
                            delay: Duration(milliseconds: 600 * widget.index),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Genre tag.
                  Positioned(
                    left: 10,
                    top: 10,
                    child: _Badge(
                      icon: _genreIcon(g.genre),
                      text: g.genre,
                      color: hue,
                    ),
                  ),
                  // Players.
                  Positioned(
                    right: 10,
                    top: 10,
                    child: _Badge(
                      icon: Icons.group_rounded,
                      text: g.maxPlayers > 1 ? '1–${g.maxPlayers}' : '1',
                      color: hue,
                      compact: true,
                    ),
                  ),
                  // Play button on the seam between art and info.
                  Positioned(
                    right: 10,
                    top: GameTile._art - 20,
                    child: _PlayButton(hue: hue, active: _down),
                  ),
                  // Name + platforms.
                  Positioned(
                    left: 12,
                    right: 12,
                    top: GameTile._art + 6,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 40),
                          child: Text(
                            g.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                display(
                                  16,
                                  color: Colors.white,
                                  spacing: 0.01,
                                ).copyWith(
                                  height: 1.15,
                                  shadows: [
                                    Shadow(
                                      color: hue.withValues(alpha: 0.6),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                          ),
                        ),
                        const Spacer(),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (var i = 0; i < g.platformNames.length; i++)
                              _PlatformChip(
                                name: g.platformNames[i],
                                isPc:
                                    i < g.platforms.length &&
                                    g.platforms[i] == 'PC',
                                hue: hue,
                              ),
                          ],
                        ),
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

IconData _genreIcon(String genre) => switch (genre.toUpperCase()) {
  'SHOOTER' => Icons.gps_fixed_rounded,
  'SPORTS' => Icons.sports_soccer_rounded,
  'RACING' => Icons.sports_motorsports_rounded,
  'FIGHTING' => Icons.sports_mma_rounded,
  'OPEN WORLD' => Icons.public_rounded,
  'ACTION' => Icons.bolt_rounded,
  _ => Icons.sports_esports_rounded,
};

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.text,
    required this.color,
    this.compact = false,
  });
  final IconData icon;
  final String text;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    height: 22,
    padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 7),
    decoration: BoxDecoration(
      color: const Color(0xD90A1330),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.7)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _bright(color)),
        const SizedBox(width: 4),
        Text(
          text,
          style: body(10, color: Q.text, weight: FontWeight.w800, spacing: 0.7),
        ),
      ],
    ),
  );
}

class _PlatformChip extends StatelessWidget {
  const _PlatformChip({
    required this.name,
    required this.isPc,
    required this.hue,
  });
  final String name;
  final bool isPc;
  final Color hue;

  @override
  Widget build(BuildContext context) => Container(
    height: 20,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    decoration: BoxDecoration(
      color: const Color(0x660A1330),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: Q.borderHi),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPc ? Icons.desktop_windows_rounded : Icons.sports_esports_rounded,
          size: 11,
          color: _bright(hue),
        ),
        const SizedBox(width: 4),
        Text(
          name,
          style: body(
            10,
            color: Q.text2,
            weight: FontWeight.w700,
            spacing: 0.2,
          ),
        ),
      ],
    ),
  );
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.hue, required this.active});
  final Color hue;
  final bool active;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 160),
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: active ? _bright(hue) : hue,
      border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2),
      boxShadow: [
        BoxShadow(
          color: hue.withValues(alpha: 0.7),
          blurRadius: active ? 20 : 12,
        ),
      ],
    ),
    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
  );
}

/// Lighter version of a game colour so icons stay readable on dark badges.
Color _bright(Color c) {
  final h = HSLColor.fromColor(c);
  return h.withLightness(math.max(h.lightness, 0.62)).toColor();
}

/// Corner brackets like a HUD target frame.
class _HudCorners extends CustomPainter {
  const _HudCorners(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    const inset = 6.0, len = 12.0;
    final r = Rect.fromLTRB(
      inset,
      inset,
      size.width - inset,
      size.height - inset,
    );
    for (final (corner, dx, dy) in [
      (r.topLeft, 1.0, 1.0),
      (r.topRight, -1.0, 1.0),
      (r.bottomLeft, 1.0, -1.0),
      (r.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawLine(corner, corner.translate(len * dx, 0), p);
      canvas.drawLine(corner, corner.translate(0, len * dy), p);
    }
  }

  @override
  bool shouldRepaint(covariant _HudCorners old) => old.color != color;
}

/// Faint CRT scanlines.
class _Scanlines extends CustomPainter {
  const _Scanlines();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0x14000000);
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), p);
    }
  }

  @override
  bool shouldRepaint(covariant _Scanlines old) => false;
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

/// The design's light sweep across a tile (`shine` keyframes, 4.5s loop).
class _Shine extends StatefulWidget {
  const _Shine({required this.delay});
  final Duration delay;
  @override
  State<_Shine> createState() => _ShineState();
}

class _ShineState extends State<_Shine> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
    } else if (!_c.isAnimating) {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.repeat();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        // Sweep across during the first 60% of the loop, then rest.
        final t = Curves.easeInOut.transform((_c.value / 0.6).clamp(0, 1));
        return FractionallySizedBox(
          widthFactor: 0.4,
          alignment: Alignment(-3 + 6 * t, 0),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0x00FFFFFF),
                  Color(0x1FFFFFFF),
                  Color(0x00FFFFFF),
                ],
              ),
            ),
          ),
        );
      },
    ),
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
