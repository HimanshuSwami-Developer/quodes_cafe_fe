import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/widgets.dart';

/// Scaffold for the four tabs. Each tab keeps its own navigation stack.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: QBottomNav(
      currentIndex: shell.currentIndex,
      onSelect: (i) =>
          shell.goBranch(i, initialLocation: i == shell.currentIndex),
    ),
  );
}
