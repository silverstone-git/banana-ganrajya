import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/network/api_config.dart';
import '../../../../core/providers/feed_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_header.dart';
import '../widgets/fineprint_widgets.dart';

/// Premium subscription hub — loaded dynamically from the FastAPI backend.
class FinePrintScreen extends ConsumerWidget {
  const FinePrintScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double statusBarHeight = MediaQuery.paddingOf(context).top;
    final fineprintFeedAsync = ref.watch(fineprintFeedProvider);

    return Scaffold(
      appBar: AppHeader(
        title: 'Ground Reports',
        statusBarHeight: statusBarHeight,
        onProfileTap: () => context.go('/settings'),
      ),
      body: fineprintFeedAsync.when(
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
                  'Could not retrieve premium ground reports. Check your backend server connection.',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelMd.copyWith(color: AppColors.secondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (kDebugMode) {
                      await ApiConfig.forceResolveDebugBaseUrl();
                    }
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
        data: (feed) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(fineprintFeedProvider);
            try {
              await ref.read(fineprintFeedProvider.future);
            } catch (_) {}
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile,
                vertical: AppSpacing.stackLg,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.fineprintGold.withOpacity(0.1),
                    AppColors.fineprintPurple.withOpacity(0.1),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Symbols.star,
                          color: AppColors.tertiaryContainer, fill: 1.0),
                      const SizedBox(width: 8),
                      Text(
                        'FINEPRINT EXCLUSIVE',
                        style: AppTypography.labelLg.copyWith(
                          color: AppColors.tertiaryContainer,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Journalism that demands your attention, not just your time.',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Deep-dives, investigative rigor, and the stories others "
                    "miss. Access the full spectrum of Banana Ganrajya's premium "
                    "reporting.",
                    style: AppTypography.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            FinePrintFeaturedCard(
              article: feed.featured,
              onTap: () =>
                  context.push('/article/${feed.featured.id}'),
            ),
            SubscriptionCtaCard(onUnlock: () {}),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMobile,
                AppSpacing.stackLg,
                AppSpacing.marginMobile,
                12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GROUND REPORTS',
                    style:
                        AppTypography.labelLg.copyWith(letterSpacing: 2),
                  ),
                  Icon(Symbols.tune, color: AppColors.secondary),
                ],
              ),
            ),
            const Divider(height: 1, indent: 20, endIndent: 20),
            for (var i = 0; i < feed.list.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile,
                  vertical: 20,
                ),
                child: FinePrintListRow(
                  article: feed.list[i],
                  dotColor: i.isEven
                      ? AppColors.fineprintGold
                      : AppColors.fineprintPurple,
                  onTap: () =>
                      context.push('/article/${feed.list[i].id}'),
                ),
              ),
              if (i != feed.list.length - 1)
                const Divider(height: 1, indent: 20, endIndent: 20),
            ],
            const SizedBox(height: AppSpacing.stackMd),
            const SubscriptionTiersCard(),
            Padding(
              padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.marginMobile)
                  .copyWith(bottom: 48),
              child: Column(
                children: [
                  Text(
                    '"Honest journalism is expensive. It requires time, risk, '
                    'and resources. Your subscription makes it possible."',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.secondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Symbols.verified_user, color: AppColors.outline),
                      const SizedBox(width: 24),
                      Icon(Symbols.shield_with_heart, color: AppColors.outline),
                      const SizedBox(width: 24),
                      Icon(Symbols.public, color: AppColors.outline),
                    ],
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
