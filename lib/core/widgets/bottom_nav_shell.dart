import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The persistent bottom navigation bar + tab content host.
///
/// Wraps a [StatefulNavigationShell] so each tab (Home / Politics / Opinion
/// / Ground / Settings) keeps its own scroll position and navigation stack
/// when switching tabs — mirrors the fixed `<nav>` bar shared by every
/// screen in the HTML mockups.
class BottomNavShell extends StatelessWidget {
  const BottomNavShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    (label: 'Home', icon: Symbols.home),
    (label: 'Politics', icon: Symbols.gavel),
    (label: 'Opinion', icon: Symbols.history_edu),
    (label: 'Ground', icon: Symbols.explore),
    (label: 'Settings', icon: Symbols.settings),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final tab = _tabs[index];
                final selected = navigationShell.currentIndex == index;
                final color =
                    selected ? AppColors.primary : AppColors.onSurfaceVariant;

                return Expanded(
                  child: InkWell(
                    onTap: () => navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tab.icon,
                          color: color,
                          fill: selected ? 1.0 : 0.0,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: AppTypography.labelMd.copyWith(
                            color: color,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
