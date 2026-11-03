import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Game tile artwork, best source first:
/// 1. the cover uploaded in the admin panel ([url], served from Cloudinary),
/// 2. the design-canvas export bundled with the app (`assets/games/<MONO>.svg`),
/// 3. nothing: [GameArt.has] is false and callers draw their own fallback.
///
/// If the cover fails to load (offline, deleted), the bundled art or
/// [fallback] is shown instead.
class GameArt extends StatelessWidget {
  const GameArt(
    this.mono, {
    super.key,
    this.url,
    this.fit = BoxFit.cover,
    this.fallback,
  });
  final String mono;
  final String? url;
  final BoxFit fit;

  /// Shown when the cover can't load and there is no bundled art.
  final Widget? fallback;

  static const _known = {
    'FC25',
    'VAL',
    'GTA',
    'COD',
    'T8',
    'FH5',
    'SM2',
    'CS2',
  };

  static bool _hasAsset(String mono) => _known.contains(mono.toUpperCase());

  /// Whether there is any artwork for this game.
  static bool has(String mono, [String? url]) =>
      (url != null && url.isNotEmpty) || _hasAsset(mono);

  Widget _bundled() => _hasAsset(mono)
      ? SvgPicture.asset(
          'assets/games/${mono.toUpperCase()}.svg',
          fit: fit,
          excludeFromSemantics: true,
        )
      : (fallback ?? const SizedBox.shrink());

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || u.isEmpty) return _bundled();
    return Image.network(
      u,
      fit: fit,
      excludeFromSemantics: true,
      gaplessPlayback: true,
      // Fade in once decoded; show the bundled art / fallback meanwhile.
      frameBuilder: (context, child, frame, sync) => sync
          ? child
          : Stack(
              fit: StackFit.passthrough,
              children: [
                if (frame == null) _bundled(),
                AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 220),
                  child: child,
                ),
              ],
            ),
      errorBuilder: (_, _, _) => _bundled(),
    );
  }
}
