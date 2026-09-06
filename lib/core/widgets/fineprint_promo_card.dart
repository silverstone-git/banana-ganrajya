import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../models/article.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// The "FinePrint Subscriber Exclusive" teaser card shown on the Home feed
/// — a gold-to-purple gradient frame around a headline + CTA button that
/// deep-links to the Ground/FinePrint tab.
class FinePrintPromoCard extends StatelessWidget {
  const FinePrintPromoCard({
    super.key,
    required this.article,
    required this.onTap,
  });

  final Article article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.marginMobile,
        vertical: AppSpacing.stackSm,
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          gradient: AppColors.fineprintGradient,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl - 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Symbols.workspace_premium,
                      color: AppColors.fineprintGold, fill: 1.0),
                  const SizedBox(width: 8),
                  Text(
                    'FINEPRINT',
                    style: AppTypography.labelLg.copyWith(
                      color: AppColors.fineprintPurple,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Subscriber Exclusive',
                    style: AppTypography.labelMd.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(article.title,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 24,
                        height: 32 / 24,
                      )),
              if (article.excerpt != null) ...[
                const SizedBox(height: 8),
                Text(
                  article.excerpt!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Ink(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AppColors.fineprintGradient,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      child: Text(
                        'READ FULL INVESTIGATION',
                        style: AppTypography.labelLg
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
