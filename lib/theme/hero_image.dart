import 'package:flutter/material.dart';

import 'colors.dart';

/// Background photos from the Quodes design canvas.
enum QPhoto {
  room('assets/images/bg_room.jpg'),
  controller('assets/images/bg_controller.jpg'),
  neonSetup('assets/images/bg_neon_setup.jpg'),
  synthwave('assets/images/bg_synthwave.jpg'),
  streaks('assets/images/bg_streaks.jpg');

  const QPhoto(this.asset);
  final String asset;
}

/// The photo band at the top of a screen, exactly as the design draws it:
/// `object-fit: cover` at [height], [focus] = CSS `object-position` (x%, y%),
/// [opacity], then a vertical fade into the page colour.
class QHeroImage {
  const QHeroImage(
    this.photo, {
    required this.height,
    this.focus = const (50, 50),
    this.opacity = 1,
    this.fadeTop = 0.25,
    this.fadeMid = 0.66,
  });

  final QPhoto photo;
  final double height;
  final (double, double) focus;
  final double opacity;

  /// Page-colour alpha at the top and at 55% of the fade (design: 0.25/0.66,
  /// or 0.30/0.62 on the room photo screens).
  final double fadeTop, fadeMid;

  Alignment get alignment => Alignment(focus.$1 / 50 - 1, focus.$2 / 50 - 1);
}

/// Paints a [QHeroImage] pinned to the top of the screen (it does not scroll).
class QHeroLayer extends StatelessWidget {
  const QHeroLayer(this.spec, {super.key});
  final QHeroImage spec;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: spec.height + 2,
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: spec.height,
              child: Opacity(
                opacity: spec.opacity,
                child: Image.asset(
                  spec.photo.asset,
                  fit: BoxFit.cover,
                  alignment: spec.alignment,
                  excludeFromSemantics: true,
                  gaplessPlayback: true,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.55, 1],
                  colors: [
                    Q.bg.withValues(alpha: spec.fadeTop),
                    Q.bg.withValues(alpha: spec.fadeMid),
                    Q.bg,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
