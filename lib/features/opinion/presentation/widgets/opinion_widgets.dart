import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/models/article.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';

/// Large featured opinion piece: grayscale-leaning photo, "Editor's Choice"
/// chip, headline overlay, then author + excerpt + CTA beneath.
class OpinionFeaturedCard extends StatelessWidget {
  const OpinionFeaturedCard({super.key, required this.article, this.onTap});

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
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 256,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      0.35, 0.35, 0.35, 0, 0, //
                      0.35, 0.35, 0.35, 0, 0, //
                      0.35, 0.35, 0.35, 0, 0, //
                      0, 0, 0, 1, 0,
                    ]),
                    child: AppNetworkImage(url: article.imageUrl),
                  ),
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
                    left: 20,
                    right: 20,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.tertiaryFixed,
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            article.category,
                            style: AppTypography.labelMd
                                .copyWith(color: AppColors.onTertiaryFixed),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          article.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.surfaceContainerHighest,
                        child: Icon(Symbols.person,
                            color: AppColors.onSurfaceVariant, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(article.author, style: AppTypography.labelLg),
                          Text('Chief Political Observer',
                              style: AppTypography.labelMd),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (article.excerpt != null)
                    Text(
                      article.excerpt!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMd
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (article.readTime != null)
                        Text(article.readTime!,
                            style: AppTypography.labelMd
                                .copyWith(color: AppColors.secondary)),
                      Row(
                        children: [
                          Text('Read Full Piece',
                              style: AppTypography.labelLg
                                  .copyWith(color: AppColors.primary)),
                          const SizedBox(width: 4),
                          Icon(Symbols.arrow_forward,
                              size: 18, color: AppColors.primary),
                        ],
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

/// A single row in "The Sharpest Minds" list: square grayscale thumbnail,
/// category, headline, author + read time.
class OpinionListRow extends StatelessWidget {
  const OpinionListRow({super.key, required this.article, this.onTap});

  final Article article;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: SizedBox(
              width: 80,
              height: 80,
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.35, 0.35, 0.35, 0, 0, //
                  0.35, 0.35, 0.35, 0, 0, //
                  0.35, 0.35, 0.35, 0, 0, //
                  0, 0, 0, 1, 0,
                ]),
                child: AppNetworkImage(url: article.imageUrl),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.category.toUpperCase(),
                  style:
                      AppTypography.labelMd.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 2),
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontSize: 18, height: 1.25),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(article.author,
                        style: AppTypography.labelLg
                            .copyWith(color: AppColors.onSurfaceVariant)),
                    const SizedBox(width: 8),
                    CircleAvatar(
                        radius: 2, backgroundColor: AppColors.outlineVariant),
                    const SizedBox(width: 8),
                    if (article.readTime != null)
                      Text(article.readTime!, style: AppTypography.labelMd),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The "Journalism is printing what someone else does not want printed..."
/// quote-of-the-day block on a tinted skewed background.
class QuoteOfTheDay extends StatelessWidget {
  const QuoteOfTheDay({
    super.key,
    required this.quote,
    required this.attribution,
  });

  final String quote;
  final String attribution;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.gutter),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.marginMobile,
        vertical: AppSpacing.stackLg,
      ),
      color: AppColors.primary.withOpacity(0.05),
      child: Column(
        children: [
          Icon(Symbols.format_quote,
              color: AppColors.primary.withOpacity(0.5), size: 36),
          const SizedBox(height: 12),
          Text(
            quote,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Text('— $attribution', style: AppTypography.labelLg),
        ],
      ),
    );
  }
}

/// A single columnist portrait in the horizontally-scrolling gallery.
class ColumnistAvatar extends StatelessWidget {
  const ColumnistAvatar({
    super.key,
    required this.name,
    required this.imageUrl,
    this.highlighted = false,
  });

  final String name;
  final String imageUrl;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: highlighted
                  ? LinearGradient(colors: [
                      AppColors.primary,
                      AppColors.tertiary,
                    ])
                  : null,
              color: highlighted ? null : AppColors.surfaceContainerHighest,
            ),
            child: ClipOval(
              child: Container(
                color: AppColors.surface,
                padding: const EdgeInsets.all(2),
                child: ClipOval(child: AppNetworkImage(url: imageUrl)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelLg,
          ),
        ],
      ),
    );
  }
}
