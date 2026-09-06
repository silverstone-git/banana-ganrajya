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
import '../widgets/opinion_widgets.dart';

/// Opinion & Analysis hub — loaded dynamically from the FastAPI backend.
class OpinionScreen extends ConsumerWidget {
  const OpinionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double statusBarHeight = MediaQuery.paddingOf(context).top;
    final opinionFeedAsync = ref.watch(opinionFeedProvider);

    return Scaffold(
      appBar: AppHeader(
        title: 'Opinion',
        statusBarHeight: statusBarHeight,
        onProfileTap: () => context.go('/settings'),
      ),
      body: opinionFeedAsync.when(
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
                  'Could not retrieve opinion feeds and columnists lists.',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelMd.copyWith(color: AppColors.secondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (kDebugMode) {
                      await ApiConfig.forceResolveDebugBaseUrl();
                    }
                    ref.invalidate(opinionFeedProvider);
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
            ref.invalidate(opinionFeedProvider);
            try {
              await ref.read(opinionFeedProvider.future);
            } catch (_) {}
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Container(
              color: AppColors.surfaceContainerLowest,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile,
                vertical: AppSpacing.stackLg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 48, height: 4, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'OPINION & ANALYSIS',
                        style: AppTypography.labelLg.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('The Unhyphenated Truth.',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Sharp, clear, and uncompromising. We strip away the noise '
                    'to bring you perspectives that challenge the status quo '
                    'and define the national conversation.',
                    style: AppTypography.bodyLg
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            OpinionFeaturedCard(
              article: feed.featured,
              onTap: () =>
                  context.push('/article/${feed.featured.id}'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMobile,
                AppSpacing.stackLg,
                AppSpacing.marginMobile,
                16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('The Sharpest Minds',
                      style: Theme.of(context).textTheme.headlineMedium),
                  Icon(Symbols.history_edu, color: AppColors.primary),
                ],
              ),
            ),
            for (var i = 0; i < feed.rows.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile,
                  vertical: 12,
                ),
                child: OpinionListRow(
                  article: feed.rows[i],
                  onTap: () =>
                      context.push('/article/${feed.rows[i].id}'),
                ),
              ),
              if (i != feed.rows.length - 1)
                const Divider(height: 1, indent: 20, endIndent: 20),
            ],
            const QuoteOfTheDay(
              quote: '"Journalism is printing what someone else does not '
                  'want printed; everything else is public relations."',
              attribution: 'George Orwell',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile),
              child: Text('OUR COLUMNISTS',
                  style: AppTypography.labelLg.copyWith(letterSpacing: 2)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.marginMobile),
                itemCount: feed.columnists.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.gutter),
                itemBuilder: (context, index) {
                  final col = feed.columnists[index];
                  return ColumnistAvatar(
                    name: col.name,
                    imageUrl: col.avatarUrl,
                    highlighted: index == 0,
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Container(
              margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.marginMobile)
                  .copyWith(bottom: 32),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.inverseSurface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Column(
                children: [
                  Text(
                    'Get the Clarity Newsletter',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: AppColors.inverseOnSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Subscribe to get columns by India\'s sharpest minds sent straight to your inbox every morning.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMd
                        .copyWith(color: AppColors.outlineVariant),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Subscribe Now'),
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
