import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/models/article.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';

/// Full-width featured premium story with a "Premium Deep Dive" badge —
/// the top card on the FinePrint / Ground Reports screen.
class FinePrintFeaturedCard extends StatelessWidget {
  const FinePrintFeaturedCard({super.key, required this.article, this.onTap});

  final Article article;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin:
            const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppNetworkImage(url: article.imageUrl),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppColors.fineprintGradient,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Symbols.workspace_premium,
                          size: 14, color: Colors.white, fill: 1.0),
                      const SizedBox(width: 6),
                      Text(
                        article.category.toUpperCase(),
                        style: AppTypography.labelMd
                            .copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article.author,
                      style: AppTypography.labelMd
                          .copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Support Independent Truth" subscription CTA card with a gold left
/// border and gradient "Unlock Full Access" button.
class SubscriptionCtaCard extends StatelessWidget {
  const SubscriptionCtaCard({super.key, this.onUnlock});

  final VoidCallback? onUnlock;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile)
          .copyWith(top: AppSpacing.stackLg),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: const Border(
          left: BorderSide(color: AppColors.fineprintGold, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Support Independent Truth',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '"In an era of noise, we provide the signal. Our investigative '
            'reports are the historical record of our times."',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
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
                onTap: onUnlock,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Unlock Full Access',
                          style: AppTypography.labelLg
                              .copyWith(color: Colors.white)),
                      const SizedBox(width: 8),
                      const Icon(Symbols.arrow_forward,
                          size: 18, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Starting at ₹199/month. Cancel anytime.',
              style: AppTypography.labelMd,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single Ground Reports list row with a colored dot + category, headline,
/// and metadata — the locked ones show a translucent lock overlay.
class FinePrintListRow extends StatelessWidget {
  const FinePrintListRow({
    super.key,
    required this.article,
    required this.dotColor,
    this.onTap,
  });

  final Article article;
  final Color dotColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration:
                          BoxDecoration(color: dotColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      article.category.toUpperCase(),
                      style: AppTypography.labelMd
                          .copyWith(color: AppColors.tertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  article.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontSize: 18, height: 1.25),
                ),
                const SizedBox(height: 4),
                if (article.timeAgo != null)
                  Text(article.timeAgo!,
                      style: AppTypography.labelMd
                          .copyWith(color: AppColors.secondary)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: article.isLocked ? 0.6 : 1,
                    child: AppNetworkImage(url: article.imageUrl),
                  ),
                  if (article.isLocked)
                    const ColoredBox(
                      color: Colors.transparent,
                      child: Center(
                        child: Icon(Symbols.lock,
                            color: Colors.white, fill: 1.0),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The Digital vs Patron subscription tier comparison grid near the bottom.
class SubscriptionTiersCard extends StatelessWidget {
  const SubscriptionTiersCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile)
          .copyWith(bottom: AppSpacing.stackLg),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
            color: AppColors.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text('Choose Your Level of Access',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _TierColumn(
                  name: 'Digital',
                  price: '₹199',
                  perks: const ['Daily FinePrint', 'Ad-free App'],
                  highlighted: false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TierColumn(
                  name: 'Patron',
                  price: '₹499',
                  perks: const ['All Digital Perks', 'Monthly Webinar'],
                  highlighted: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TierColumn extends StatelessWidget {
  const _TierColumn({
    required this.name,
    required this.price,
    required this.perks,
    required this.highlighted,
  });

  final String name;
  final String price;
  final List<String> perks;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: highlighted ? Colors.white : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: highlighted
            ? Border.all(color: AppColors.fineprintGold, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(highlighted ? 0.08 : 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(name, style: AppTypography.labelLg),
              if (highlighted) ...[
                const SizedBox(width: 4),
                const Icon(Symbols.verified,
                    size: 14, color: AppColors.fineprintGold, fill: 1.0),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(price,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
          for (final perk in perks)
            Text(
              perk,
              style: AppTypography.labelMd.copyWith(fontSize: 10),
            ),
        ],
      ),
    );
  }
}
