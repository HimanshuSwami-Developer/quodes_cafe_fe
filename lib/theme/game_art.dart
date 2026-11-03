import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Tile artwork exported from the design canvas (`assets/games/<MONO>.svg`).
/// Games added later in the admin panel have no art: [GameArt.has] is false
/// and callers draw their fallback.
class GameArt extends StatelessWidget {
  const GameArt(this.mono, {super.key, this.fit = BoxFit.cover});
  final String mono;
  final BoxFit fit;

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
  static bool has(String mono) => _known.contains(mono.toUpperCase());

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/games/${mono.toUpperCase()}.svg',
    fit: fit,
    excludeFromSemantics: true,
  );
}
