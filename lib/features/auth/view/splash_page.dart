import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import '../../../theme/widgets.dart';

/// Shown while the AuthBloc restores the session; the router moves on.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) => const QBackground(
    hero: QHeroImage(
      QPhoto.room,
      height: 400,
      focus: (50, 45),
      fadeTop: 0.3,
      fadeMid: 0.62,
    ),
    grid: true,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QLogo(),
          SizedBox(height: 28),
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Q.link),
          ),
        ],
      ),
    ),
  );
}
