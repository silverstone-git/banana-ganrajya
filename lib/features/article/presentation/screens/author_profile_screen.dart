import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/providers/bookmarks_provider.dart';
import '../../../../core/providers/feed_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_network_image.dart';

/// Editorial Author and Columnist profile screen — fully styled in
/// classic "Journalistic Authority" broadsheet newspaper theme.
class AuthorProfileScreen extends ConsumerWidget {
  const AuthorProfileScreen({super.key, required this.authorId});

  final String authorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double statusBarHeight = MediaQuery.paddingOf(context).top;
    
    // Watch author profile and articles feeds concurrently
    final profileAsync = ref.watch(authorProfileProvider(authorId));
    final articlesAsync = ref.watch(authorArticlesProvider(authorId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        title: 'Author Profile',
        statusBarHeight: statusBarHeight,
        onProfileTap: () => context.go('/settings'),
      ),
      body: profileAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Symbols.error_circle_rounded, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to Load Author Profile',
                  style: AppTypography.headlineMd,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ensure your local backend is running and the database is properly seeded.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(authorProfileProvider(authorId)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (author) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(authorProfileProvider(authorId));
            ref.invalidate(authorArticlesProvider(authorId));
            try {
              await ref.read(authorArticlesProvider(authorId).future);
            } catch (_) {}
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              // 1. Double line decorative accent at the top
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
                child: Column(
                  children: [
                    SizedBox(height: 16),
                    _BroadsheetDivider(),
                  ],
                ),
              ),

              // 2. Author Bio Header (Premium Editorial Column Layout)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Portrait with double border accent
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: SizedBox(
                              width: 80,
                              height: 80,
                              child: AppNetworkImage(url: author.avatarUrl),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  author.title.toUpperCase(),
                                  style: AppTypography.labelMd.copyWith(
                                    color: AppColors.primary,
                                    letterSpacing: 1.5,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                author.name,
                                style: AppTypography.headlineLg.copyWith(
                                  fontSize: 26,
                                  height: 32 / 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (author.bio != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.surfaceContainer),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                width: 4.5,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(AppRadius.lg),
                                    bottomLeft: Radius.circular(AppRadius.lg),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    author.bio!,
                                    style: AppTypography.bodyMd.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      height: 1.6,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 3. Double line separation transition
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BroadsheetDivider(),
                    SizedBox(height: 24),
                  ],
                ),
              ),

              // 4. Columns Header List Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
                child: Row(
                  children: [
                    Text(
                      authorId == 'banana_team' ? 'LATEST REPORTS' : 'PUBLISHED COLUMNS',
                      style: AppTypography.labelLg.copyWith(
                        letterSpacing: 2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      authorId == 'banana_team' ? Symbols.feed : Symbols.newspaper,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 5. Paginated Column Grid / Feed
              articlesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, stack) => Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'Failed to load author columns.',
                      style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
                    ),
                  ),
                ),
                data: (stories) {
                  if (stories.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile, vertical: 40),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Text(
                          'No columns published by this author yet.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stories.length,
                    separatorBuilder: (_, __) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
                      child: Divider(
                        color: AppColors.surfaceContainerHigh,
                        height: 1,
                      ),
                    ),
                    itemBuilder: (context, index) {
                      final article = stories[index];
                      return _AuthorColumnTile(article: article);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A double-line separation mimicking vintage broadsheet headers
class _BroadsheetDivider extends StatelessWidget {
  const _BroadsheetDivider();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 2.5,
          color: AppColors.onSurface.withOpacity(0.85),
        ),
        const SizedBox(height: 2),
        Container(
          height: 0.5,
          color: AppColors.onSurface.withOpacity(0.5),
        ),
      ],
    );
  }
}

/// Broadsheet Columnist List Tile with excerpt and inline bookmark actions
class _AuthorColumnTile extends ConsumerWidget {
  const _AuthorColumnTile({required this.article});

  final dynamic article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked = ref.watch(
      bookmarksProvider.select((ids) => ids.contains(article.id)),
    );

    return InkWell(
      onTap: () => context.push('/article/${article.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.marginMobile,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  color: AppColors.primary,
                  child: Text(
                    article.category.toUpperCase(),
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (article.isPremium) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Text(
                      'PREMIUM',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        style: AppTypography.headlineMd.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          height: 24 / 18,
                        ),
                      ),
                      if (article.excerpt != null && article.excerpt!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          article.excerpt!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMd.copyWith(
                            fontSize: 13,
                            height: 1.5,
                            color: AppColors.onSurfaceVariant.withOpacity(0.9),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (article.imageUrl != null && article.imageUrl!.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: AppNetworkImage(url: article.imageUrl!),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      article.timeAgo?.toUpperCase() ?? 'TODAY',
                      style: AppTypography.labelMd.copyWith(
                        fontSize: 11,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 1.5,
                      backgroundColor: AppColors.outlineVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (article.readTime ?? '5 mins read').toUpperCase(),
                      style: AppTypography.labelMd.copyWith(
                        fontSize: 11,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        ref.read(bookmarksProvider.notifier).toggle(article.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Symbols.bookmark,
                          fill: isBookmarked ? 1.0 : 0.0,
                          size: 18,
                          color: isBookmarked ? AppColors.primary : AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Symbols.share,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
