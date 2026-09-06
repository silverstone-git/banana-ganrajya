import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_config.dart';
import '../../../../core/providers/feed_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/fineprint_promo_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../widgets/home_widgets.dart';

/// The main news feed — loaded dynamically from the FastAPI backend.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double statusBarHeight = MediaQuery.paddingOf(context).top;
    
    // Watch both home feed data and premium fineprint promo asynchronously
    final homeFeedAsync = ref.watch(homeFeedProvider);
    final fineprintFeedAsync = ref.watch(fineprintFeedProvider);

    return Scaffold(
      appBar: AppHeader(
        title: 'Home',
        statusBarHeight: statusBarHeight,
        onProfileTap: () => context.go('/settings'),
      ),
      body: homeFeedAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 48, color: AppColors.secondary),
                const SizedBox(height: 16),
                Text(
                  'Unable to Connect to Banana Ganrajya Server',
                  style: AppTypography.labelLg,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please verify your internet connection or check that the backend at localhost/ngrok is active.',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelMd.copyWith(color: AppColors.secondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (kDebugMode) {
                      await ApiConfig.forceResolveDebugBaseUrl();
                    }
                    ref.invalidate(homeFeedProvider);
                    ref.invalidate(fineprintFeedProvider);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                  ),
                  child: const Text('Retry Connection'),
                ),
              ],
            ),
          ),
        ),
        data: (feed) {
          final featuredFineprint = fineprintFeedAsync.maybeWhen(
            data: (fpData) => fpData.featured,
            orElse: () => null,
          );

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              // Invalidate both providers to force refetching from the API
              ref.invalidate(homeFeedProvider);
              ref.invalidate(fineprintFeedProvider);
              try {
                // Await completion so the reload loading indicator spins naturally
                await ref.read(homeFeedProvider.future);
              } catch (_) {}
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(), // Ensures pulling works even if list content is short
              children: [
                BreakingNewsTicker(
                headline:
                    'Supreme Court initiates suo motu proceedings on major constitutional reform...',
                onTap: () => context.push('/article/breaking-1'),
              ),
              HeroStoryCard(
                article: feed.heroStory,
                onTap: () => context.push('/article/${feed.heroStory.id}'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile,
                  vertical: AppSpacing.stackMd,
                ),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.gutter,
                  crossAxisSpacing: AppSpacing.gutter,
                  childAspectRatio: 0.61,
                  children: feed.secondaryStories
                      .map((a) => SecondaryStoryCard(
                            article: a,
                            onTap: () => context.push('/article/${a.id}'),
                          ))
                      .toList(),
                ),
              ),
              if (featuredFineprint != null)
                FinePrintPromoCard(
                  article: featuredFineprint,
                  onTap: () => context.go('/ground-reports'),
                ),
              SectionHeader(
                eyebrow: 'In-Depth',
                title: 'Ground Reports',
                onTrailingTap: () => context.go('/ground-reports'),
              ),
              for (final article in feed.groundReports) ...[
                GroundReportTile(
                  article: article,
                  onTap: () => context.push('/article/${article.id}'),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
              ],
              const SizedBox(height: AppSpacing.stackMd),
              NewsletterCard(onJoin: () {}),
            ],
          ),
        );
      },
      ),
    );
  }
}
