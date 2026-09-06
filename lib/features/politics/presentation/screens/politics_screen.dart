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
import '../../../../core/widgets/section_header.dart';
import '../../../home/presentation/widgets/home_widgets.dart';

/// Politics tab — loads dynamically from the backend using politicsArticlesProvider.
class PoliticsScreen extends ConsumerWidget {
  const PoliticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double statusBarHeight = MediaQuery.paddingOf(context).top;
    final politicsArticlesAsync = ref.watch(politicsArticlesProvider);

    return Scaffold(
      appBar: AppHeader(
        title: 'Politics',
        statusBarHeight: statusBarHeight,
        onProfileTap: () => context.go('/settings'),
      ),
      body: politicsArticlesAsync.when(
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
                  'Could not retrieve politics articles.',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelMd.copyWith(color: AppColors.secondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (kDebugMode) {
                      await ApiConfig.forceResolveDebugBaseUrl();
                    }
                    ref.invalidate(politicsArticlesProvider);
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
        data: (stories) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(politicsArticlesProvider);
            try {
              await ref.read(politicsArticlesProvider.future);
            } catch (_) {}
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SectionHeader(eyebrow: 'Coverage', title: 'Latest in Politics'),
            if (stories.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'No articles currently matching POLITICS category in database.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
                ),
              ),
            for (final article in stories) ...[
              GroundReportTile(
                article: article,
                onTap: () => context.push('/article/${article.id}'),
              ),
              const Divider(height: 1, indent: 20, endIndent: 20),
            ],
            const SizedBox(height: AppSpacing.stackLg),
          ],
        ),
      ),
    ),
    );
  }
}
