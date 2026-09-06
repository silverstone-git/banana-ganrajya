import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';

/// Sticky bar used on the article-detail screen: a back arrow on the left
/// and the centered wordmark logo, matching `article_view.html`.
class ArticleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ArticleAppBar({super.key, this.statusBarHeight = 0.0});

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
          padding: EdgeInsets.only(top: statusBarHeight),
          color: AppColors.surface.withValues(alpha: 0.8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(Symbols.arrow_back,
                      color: AppColors.onSurface),
                ),
              ),
              Image.asset(
                AppAssets.headerLogo(isDark),
                height: 32,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
