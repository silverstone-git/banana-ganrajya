import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    final currentQuery = ref.read(searchProvider).query;
    _controller = TextEditingController(text: currentQuery);
    _focusNode = FocusNode();
    
    // Automatically focus the input field on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQuerySubmitted(String query) {
    if (query.trim().isNotEmpty) {
      ref.read(searchProvider.notifier).performSearch(query.trim());
    }
  }

  void _onTagTapped(String tag) {
    _controller.text = tag;
    ref.read(searchProvider.notifier).performSearch(tag);
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.paddingOf(context).top;
    final state = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // Frosted search header
          _buildSearchHeader(statusBarHeight, state),
          
          // Search Body
          Expanded(
            child: _buildSearchBody(state),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(double statusBarHeight, SearchState state) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.only(
            top: statusBarHeight + 8,
            bottom: 12,
            left: AppSpacing.marginMobile - 8,
            right: AppSpacing.marginMobile,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.85),
            border: Border(
              bottom: BorderSide(
                color: AppColors.surfaceContainerHigh,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
                icon: Icon(
                  Symbols.arrow_back,
                  color: AppColors.onSurface,
                ),
              ),
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: AppColors.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: (val) => ref.read(searchProvider.notifier).setQuery(val),
                    onSubmitted: _onQuerySubmitted,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search articles, columnists, topics...',
                      hintStyle: AppTypography.labelLg.copyWith(
                        color: AppColors.secondary.withOpacity(0.8),
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: Icon(
                        Symbols.search,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Symbols.close,
                                color: AppColors.secondary,
                                size: 18,
                              ),
                              onPressed: () {
                                _controller.clear();
                                ref.read(searchProvider.notifier).setQuery('');
                                _focusNode.requestFocus();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
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

  Widget _buildSearchBody(SearchState state) {
    if (state.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (state.errorMessage != null) {
      return _buildErrorState(state.errorMessage!);
    }

    if (state.query.trim().isEmpty) {
      return _buildHistoryAndSuggestions(state);
    }

    // When query is entered but results are completely empty
    if (state.articles.isEmpty && state.authors.isEmpty && state.tags.isEmpty) {
      return _buildEmptyResultsState();
    }

    return _buildResultsList(state);
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Symbols.error_circle_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Search Failed',
              style: AppTypography.headlineMd,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(searchProvider.notifier).performSearch(_controller.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Retry Search'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.search_off,
              size: 54,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Results Found',
              style: AppTypography.headlineMd,
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find anything matching "${_controller.text}".\nTry checking spelling or using broader search terms.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryAndSuggestions(SearchState state) {
    final recentTopics = [
      'National',
      'Ground Reports',
      'Ecosystem',
      'Opinion',
      'Constitutional Reform'
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.marginMobile,
        vertical: 16,
      ),
      children: [
        if (state.history.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT SEARCHES',
                style: AppTypography.labelMd.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              TextButton(
                onPressed: () => ref.read(searchProvider.notifier).clearHistory(),
                child: Text(
                  'Clear All',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.history.length,
            separatorBuilder: (_, __) => Divider(
              color: AppColors.surfaceContainer,
              height: 1,
            ),
            itemBuilder: (context, index) {
              final query = state.history[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Symbols.history,
                  color: AppColors.secondary,
                  size: 20,
                ),
                title: Text(
                  query,
                  style: AppTypography.bodyMd,
                ),
                trailing: IconButton(
                  icon: Icon(
                    Symbols.close,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                  onPressed: () {
                    ref.read(searchProvider.notifier).deleteHistoryItem(query);
                  },
                ),
                onTap: () {
                  _controller.text = query;
                  ref.read(searchProvider.notifier).performSearch(query);
                },
              );
            },
          ),
          const SizedBox(height: 24),
        ],
        Text(
          'EXPLORE TOPICS',
          style: AppTypography.labelMd.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: recentTopics.map((topic) {
            return InkWell(
              onTap: () => _onTagTapped(topic),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.surfaceContainerHigh,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Symbols.trending_up,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      topic,
                      style: AppTypography.labelLg.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResultsList(SearchState state) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.marginMobile,
        vertical: 16,
      ),
      children: [
        if (state.tags.isNotEmpty) ...[
          Text(
            'MATCHING TOPICS',
            style: AppTypography.labelMd.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.tags.map((tag) {
              return ActionChip(
                label: Text('#$tag'),
                labelStyle: AppTypography.labelLg.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: AppColors.surfaceContainerLow,
                side: BorderSide(
                  color: AppColors.primary.withOpacity(0.2),
                ),
                onPressed: () => _onTagTapped(tag),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
        if (state.authors.isNotEmpty) ...[
          Text(
            'COLUMNISTS & AUTHORS',
            style: AppTypography.labelMd.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.authors.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final author = state.authors[index];
              return InkWell(
                onTap: () {
                  context.push('/author/${author.id}');
                },
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: AppColors.surfaceContainer,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipOval(
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: AppNetworkImage(url: author.avatarUrl),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              author.name,
                              style: AppTypography.labelLg.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              author.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelMd.copyWith(
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Symbols.arrow_forward_ios,
                        size: 14,
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
        if (state.articles.isNotEmpty) ...[
          Text(
            'ARTICLES (${state.articles.length})',
            style: AppTypography.labelMd.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.articles.length,
            separatorBuilder: (_, __) => Divider(
              color: AppColors.surfaceContainer,
              height: 24,
            ),
            itemBuilder: (context, index) {
              final article = state.articles[index];
              return InkWell(
                onTap: () {
                  context.push('/article/${article.id}');
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                article.category.toUpperCase(),
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (article.isPremium) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  color: AppColors.primary,
                                  child: Text(
                                    'PREMIUM',
                                    style: AppTypography.labelMd.copyWith(
                                      color: AppColors.onPrimary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            article.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headlineLgMobile.copyWith(
                              fontSize: 16,
                              height: 22 / 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            article.author,
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (article.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: AppNetworkImage(url: article.imageUrl),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
