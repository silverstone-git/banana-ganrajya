import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/models/article.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';

/// Scrolling red "BREAKING" banner pinned under the app bar.
class BreakingNewsTicker extends StatelessWidget {
  const BreakingNewsTicker({super.key, required this.headline, this.onTap});

  final String headline;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile)
                  .copyWith(top: 12, bottom: 12),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  'BREAKING',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLg
                      .copyWith(color: AppColors.onPrimary),
                ),
              ),
              Icon(Symbols.chevron_right, color: AppColors.onPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-bleed hero story with a gradient scrim, category chip, headline and
/// byline — the top story on the Home feed.
class HeroStoryCard extends StatelessWidget {
  const HeroStoryCard({super.key, required this.article, this.onTap});

  final Article article;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppNetworkImage(url: article.imageUrl),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        color: AppColors.primary,
                        child: Text(
                          article.category,
                          style: AppTypography.labelMd
                              .copyWith(color: AppColors.onPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (article.readTime != null)
                        Text(
                          article.readTime!,
                          style: AppTypography.labelMd
                              .copyWith(color: Colors.white70),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    article.title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(color: Colors.white, fontSize: 24, height: 32/24),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.surfaceContainer,
                        child: Icon(Symbols.person,
                            size: 16, color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        article.author,
                        style: AppTypography.labelLg
                            .copyWith(color: Colors.white.withOpacity(0.9)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Square image + category + headline — used in the 2-column secondary grid.
class SecondaryStoryCard extends StatelessWidget {
  const SecondaryStoryCard({super.key, required this.article, this.onTap});

  final Article article;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: AppNetworkImage(url: article.imageUrl),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            article.category.toUpperCase(),
            style: AppTypography.labelMd
                .copyWith(color: AppColors.primary, letterSpacing: 1.5),
          ),
          const SizedBox(height: 2),
          Text(
            article.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontSize: 18, height: 1.3),
          ),
        ],
      ),
    );
  }
}

/// Horizontal list row: text on the left, thumbnail on the right — used for
/// "Ground Reports" on the Home feed.
class GroundReportTile extends StatelessWidget {
  const GroundReportTile({super.key, required this.article, this.onTap});

  final Article article;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.marginMobile,
          vertical: 24,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.category.toUpperCase(),
                        style: AppTypography.labelMd
                            .copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        article.title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontSize: 18, height: 1.25),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (article.readTime != null)
                        Text(article.readTime!, style: AppTypography.labelMd),
                      if (article.readTime != null && article.timeAgo != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: CircleAvatar(
                              radius: 2,
                              backgroundColor: AppColors.outlineVariant),
                        ),
                      if (article.timeAgo != null)
                        Text(article.timeAgo!, style: AppTypography.labelMd),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: SizedBox(
                width: 96,
                height: 96,
                child: AppNetworkImage(url: article.imageUrl),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "The Morning Brief" newsletter signup card at the bottom of the feed.
class NewsletterCard extends StatelessWidget {
  const NewsletterCard({super.key, this.onJoin});

  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile)
          .copyWith(bottom: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('The Morning Brief', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Wake up to the smartest news analysis in your inbox every day at 8 AM.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Email address',
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onJoin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                ),
                child: const Text('JOIN'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
