import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// The "IN-DEPTH / Ground Reports [→]" pattern repeated across screens:
/// a small uppercase eyebrow label above a serif headline, with an optional
/// circular trailing action button.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.onTrailingTap,
  });

  final String title;
  final String? eyebrow;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile)
          .copyWith(top: AppSpacing.stackLg, bottom: AppSpacing.stackSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!.toUpperCase(),
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(title, style: Theme.of(context).textTheme.headlineLarge),
              ],
            ),
          ),
          if (onTrailingTap != null)
            IconButton(
              onPressed: onTrailingTap,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceContainer,
                shape: const CircleBorder(),
              ),
              icon: const Icon(Symbols.trending_flat),
            ),
        ],
      ),
    );
  }
}
