import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_exception.dart';
import '../core/router/routes.dart';
import 'colors.dart';
import 'hero_image.dart';
import 'theme.dart';

export 'hero_image.dart';

/// Back that never strands the player: pop if possible, else go to Games.
void popOrGames(BuildContext context) =>
    context.canPop() ? context.pop() : context.go(Routes.games);

bool reduceMotion(BuildContext c) => MediaQuery.of(c).disableAnimations;

String mmss(Duration d) {
  final s = d.inSeconds.clamp(0, 1 << 31);
  return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

String hhmmss(Duration d) {
  final s = d.inSeconds.clamp(0, 1 << 31);
  String p(int n) => n.toString().padLeft(2, '0');
  return '${p(s ~/ 3600)}:${p((s % 3600) ~/ 60)}:${p(s % 60)}';
}

void showError(BuildContext context, Object e) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(e is ApiException ? e.message : '$e')),
    );
}

void showToast(BuildContext context, String msg) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

/// Navy screen with the blue/pink radial glows and the 32px grid.
class QBackground extends StatelessWidget {
  final Widget child;
  final bool grid;
  final Widget? bottom;

  /// Photo band at the top of the screen (see the per-page specs in
  /// theme/hero_image.dart, taken from the design canvas).
  final QHeroImage? hero;
  const QBackground({
    super.key,
    required this.child,
    this.grid = false,
    this.bottom,
    this.hero,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Q.bg,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: bottom,
      body: Stack(
        fit: StackFit.expand, // backdrop always covers the whole screen
        children: [
          const Positioned.fill(child: _Glows()),
          if (hero != null) QHeroLayer(hero!),
          if (grid)
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          SafeArea(bottom: bottom == null, child: child),
        ],
      ),
    );
  }
}

class _Glows extends StatelessWidget {
  const _Glows();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-1, -1),
              radius: 1.3,
              colors: [Color(0x4D2F6BFF), Color(0x002F6BFF)],
              stops: [0, 0.62],
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(1, 1),
              radius: 1.1,
              colors: [Color(0x3DFF4D9D), Color(0x00FF4D9D)],
              stops: [0, 0.62],
            ),
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x122F6BFF)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The bobbing blue "arcade" CTA with a hard bottom shadow.
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final Color color;
  final Color shadow;
  final bool bob;
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.color = Q.primary,
    this.shadow = Q.primaryShadow,
    this.bob = true,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.bob && !reduceMotion(context)) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset: Offset(
          0,
          enabled ? -2 * Curves.easeInOut.transform(_c.value) : 0,
        ),
        child: child,
      ),
      child: Semantics(
        button: true,
        enabled: enabled,
        label: widget.label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: enabled ? widget.onPressed : null,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: enabled ? widget.color : Q.surfaceLo,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: enabled ? widget.shadow : Q.border,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: widget.loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          widget.label,
                          overflow: TextOverflow.ellipsis,
                          style: display(
                            15,
                            color: enabled ? Colors.white : Q.text3,
                            weight: FontWeight.w700,
                            spacing: 0.1,
                          ),
                        ),
                      ),
                      if (widget.icon != null) ...[
                        const SizedBox(width: 10),
                        Icon(
                          widget.icon,
                          size: 18,
                          color: enabled ? Colors.white : Q.text3,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Outlined surface button (secondary actions).
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final double height;
  const GhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color = Q.text,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Q.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Q.borderHi),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: SizedBox(
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: body(14, color: color, weight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TextLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double size;
  const TextLink(this.label, {super.key, required this.onTap, this.size = 14});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: body(size, color: Q.link, weight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

/// 44px rounded-square icon button used for back / close.
class SquareIconButton extends StatelessWidget {
  final IconData icon;
  final String semantic;
  final VoidCallback? onTap;
  const SquareIconButton({
    super.key,
    this.icon = Icons.chevron_left_rounded,
    required this.semantic,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantic,
      excludeSemantics: true,
      child: Material(
        color: Q.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Q.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap ?? () => popOrGames(context),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: Q.text, size: 24),
          ),
        ),
      ),
    );
  }
}

class StepDots extends StatelessWidget {
  final int step; // 1-based
  final int total;
  const StepDots({super.key, required this.step, this.total = 4});
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step $step of $total',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(total, (i) {
          final on = i < step;
          return Container(
            margin: const EdgeInsets.only(left: 6),
            width: i == step - 1 ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: on ? Q.primary : Q.border,
              borderRadius: BorderRadius.circular(4),
              boxShadow: i == step - 1
                  ? const [BoxShadow(color: Color(0x992F6BFF), blurRadius: 8)]
                  : null,
            ),
          );
        }),
      ),
    );
  }
}

/// Toggle pill used for genres, topics, durations, days.
class QChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selBg, selFg, selBorder;
  final double height;
  final bool glow;
  const QChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selBg = Q.primary,
    this.selFg = Colors.white,
    this.selBorder = Q.primary,
    this.height = 44,
    this.glow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? selBg : Q.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? selBorder : Q.borderHi),
            boxShadow: selected && glow
                ? [
                    BoxShadow(
                      color: selBorder.withValues(alpha: 0.45),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: body(
              14,
              color: selected ? selFg : Q.text2,
              weight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: body(13, color: Q.text2, weight: FontWeight.w600, spacing: 1.04),
  );
}

class QField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboard;
  final Widget? suffix;
  final Widget? labelTrailing;
  final Iterable<String>? autofill;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  const QField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.keyboard,
    this.suffix,
    this.labelTrailing,
    this.autofill,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: FieldLabel(label)),
            ?labelTrailing,
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          autofillHints: autofill,
          onChanged: onChanged,
          maxLines: maxLines,
          style: body(15),
          decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
        ),
      ],
    );
  }
}

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color borderColor;
  final double radius;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = Q.surface,
    this.borderColor = Q.border,
    this.radius = 14,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
    ),
    child: child,
  );
}

/// Blinking dot used by "LIVE" and "OPEN NOW".
class BlinkDot extends StatefulWidget {
  final Color color;
  final double size;
  const BlinkDot({super.key, this.color = Q.green, this.size = 7});
  @override
  State<BlinkDot> createState() => _BlinkDotState();
}

class _BlinkDotState extends State<BlinkDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!reduceMotion(context)) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 1.0, end: 0.3).animate(_c),
    child: Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    ),
  );
}

/// Hexagon logo mark.
class QLogo extends StatelessWidget {
  final double size;
  const QLogo({super.key, this.size = 84});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Quodes Gaming logo',
    child: SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: HexPainter(
          fill: Colors.white,
          stroke: Q.link,
          inner: Q.pinkSoft,
        ),
        child: Center(
          child: Text(
            'Q',
            style: display(size * 0.36, color: Q.link, weight: FontWeight.w700),
          ),
        ),
      ),
    ),
  );
}

class HexPainter extends CustomPainter {
  final Color fill, stroke;
  final Color? inner;
  final double strokeWidth;
  HexPainter({
    required this.fill,
    required this.stroke,
    this.inner,
    this.strokeWidth = 2.5,
  });

  Path hex(Size s, double inset) {
    final w = s.width, h = s.height;
    final cx = w / 2;
    final r = w / 2 - inset;
    final p = Path();
    for (var i = 0; i < 6; i++) {
      final a = -math.pi / 2 + i * math.pi / 3;
      final pt = Offset(cx + r * math.cos(a), h / 2 + r * math.sin(a));
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outer = hex(size, size.width * 0.05);
    canvas.drawPath(outer, Paint()..color = fill);
    canvas.drawPath(
      outer,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    if (inner != null) {
      canvas.drawPath(
        hex(size, size.width * 0.18),
        Paint()
          ..color = inner!.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HexPainter old) =>
      old.fill != fill || old.stroke != stroke;
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: Q.link));
}

class ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Q.text3, size: 36),
          const SizedBox(height: 12),
          Text(
            error is ApiException ? (error as ApiException).message : '$error',
            textAlign: TextAlign.center,
            style: body(14, color: Q.text2),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 160,
            child: GhostButton(label: 'Retry', onPressed: onRetry),
          ),
        ],
      ),
    ),
  );
}

/// Shared top-level navigation for Games/Help/Support/Profile.
/// Tabs of the main shell, in branch order (see core/router/app_router.dart).
enum NavTab { games, help, support, profile }

/// Bottom tab bar. Driven by go_router's StatefulNavigationShell.
class QBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;
  const QBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    Widget item(NavTab t, IconData icon, String text) {
      final on = t.index == currentIndex;
      return Expanded(
        child: Semantics(
          selected: on,
          button: true,
          label: text,
          excludeSemantics: true,
          child: InkWell(
            onTap: () => onSelect(t.index),
            child: SizedBox(
              height: 56,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22, color: on ? Q.link : Q.text3),
                  const SizedBox(height: 3),
                  Text(
                    text,
                    style: body(
                      11,
                      color: on ? Q.link : Q.text3,
                      weight: on ? FontWeight.w700 : FontWeight.w600,
                      spacing: 0.66,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Q.surface,
        border: Border(top: BorderSide(color: Q.border)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            item(NavTab.games, Icons.sports_esports_outlined, 'GAMES'),
            item(NavTab.help, Icons.help_outline_rounded, 'HELP'),
            item(NavTab.support, Icons.headset_mic_outlined, 'SUPPORT'),
            item(NavTab.profile, Icons.person_outline_rounded, 'PROFILE'),
          ],
        ),
      ),
    );
  }
}

/// Header row: back button + title (+ optional trailing).
class QHeader extends StatelessWidget {
  final String? title;
  final Widget? trailing;
  final VoidCallback? onBack;
  final String backLabel;
  final IconData backIcon;
  const QHeader({
    super.key,
    this.title,
    this.trailing,
    this.onBack,
    this.backLabel = 'Back',
    this.backIcon = Icons.chevron_left_rounded,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SquareIconButton(icon: backIcon, semantic: backLabel, onTap: onBack),
      const SizedBox(width: 12),
      if (title != null)
        Expanded(
          child: Text(title!, style: display(20, weight: FontWeight.w700)),
        )
      else
        const Spacer(),
      ?trailing,
    ],
  );
}

/// Small "key / value" tile used in summaries.
class KV extends StatelessWidget {
  final String k, v;
  const KV(this.k, this.v, {super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(k, style: label(11)),
      const SizedBox(height: 3),
      Text(v, style: body(15, weight: FontWeight.w700)),
    ],
  );
}
