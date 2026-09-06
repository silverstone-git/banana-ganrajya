import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The frosted, sticky top bar used on every tab screen: logo + optional
/// title on the left, search + profile avatar on the right. Mirrors the
/// `<header>` block shared by homescreen/fineprint/opinion_analysis HTML.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.title,
    this.onSearchTap,
    this.onProfileTap,
    this.statusBarHeight = 0.0,
  });

  /// Optional title shown next to the logo (e.g. "Opinion", "Ground Reports").
  final String? title;
  final VoidCallback? onSearchTap;
  final VoidCallback? onProfileTap;
  final double statusBarHeight;

  @override
  Size get preferredSize => Size.fromHeight(64 + statusBarHeight);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark || AppColors.isDark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: preferredSize.height,
          padding: EdgeInsets.only(
            top: statusBarHeight,
            left: AppSpacing.marginMobile,
            right: AppSpacing.marginMobile,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Image.asset(
                AppAssets.headerLogo(isDark),
                height: 36,
                fit: BoxFit.contain,
              ),
              if (title != null) ...[
                const SizedBox(width: 12),
                Text(
                  title!,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
              const Spacer(),
              IconButton(
                onPressed: onSearchTap ?? () => context.push('/search'),
                icon: Icon(Symbols.search,
                    color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onProfileTap,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Symbols.person,
                      color: AppColors.onPrimary, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
