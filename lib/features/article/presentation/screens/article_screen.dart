import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/network/api_config.dart';
import '../../../../core/providers/api_client_provider.dart';
import '../../../../core/providers/bookmarks_provider.dart';
import '../../../../core/providers/feed_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/article_app_bar.dart';
import '../widgets/comments_section.dart';

/// Full article reading view — loaded dynamically from the backend SQLite DB.
/// Reachable by tapping any story card; pushed on top of the bottom-nav shell.
class ArticleScreen extends ConsumerStatefulWidget {
  const ArticleScreen({super.key, required this.articleId});

  final String articleId;

  @override
  ConsumerState<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends ConsumerState<ArticleScreen> {
  bool _isListening = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Telemetry Scroll & Focus Time Tracking
  final ScrollController _scrollController = ScrollController();
  int _maxScrollPercentage = 0;
  late final DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _scrollController.addListener(_onScroll);
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() => _isListening = false);
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    
    // Calculate focus read time in seconds
    final timeSpent = DateTime.now().difference(_startTime).inSeconds;
    
    // Fire-and-forget telemetry update
    _sendTelemetry(timeSpent, _maxScrollPercentage);
    
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final currentScroll = _scrollController.position.pixels;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll > 0) {
      final percent = ((currentScroll / maxScroll) * 100).clamp(0, 100).toInt();
      if (percent > _maxScrollPercentage) {
        _maxScrollPercentage = percent;
      }
    }
  }

  Future<void> _sendTelemetry(int timeSpent, int maxScroll) async {
    if (timeSpent < 1 && maxScroll < 1) return;
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/analytics/reads', data: {
        'article_id': widget.articleId,
        'time_spent_seconds': timeSpent,
        'max_scroll_percentage': maxScroll,
      });
    } catch (e) {
      debugPrint('[!] Failed to send telemetry: $e');
    }
  }

  Future<void> _toggleAudio(String? audioUrl) async {
    if (audioUrl == null || audioUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio is still synthesizing on S3... Please wait a few seconds and try again.')),
      );
      return;
    }
    
    try {
      if (_isListening) {
        await _audioPlayer.pause();
        setState(() => _isListening = false);
      } else {
        await _audioPlayer.play(UrlSource(audioUrl));
        setState(() => _isListening = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play article audio: $e')),
        );
      }
    }
  }

  /// Utility to dynamically split the backend article's body text by double
  /// newlines and render clean paragraph spacing, complete with elegant, inline
  /// subscribe and exclusive analytical CTAs.
  /// Overhauled semantic HTML block parser that reads, decodes, and renders Quill's rich HTML
  /// layout seamlessly (paragraphs, blockquotes, inline R2/S3 images, ordered/unordered lists).
  List<Widget> _buildBodyParagraphs(String body) {
    final widgets = <Widget>[];
    
    // Normalize HTML string to remove carriage returns and line feeds between tags
    var html = body.replaceAll('\n', ' ').replaceAll('\r', ' ').trim();
    
    // Regex to capture independent sequential HTML block elements
    final blockRegex = RegExp(
      r'(<p>.*?</p>|<h2>.*?</h2>|<h3>.*?</h3>|<h1>.*?</h1>|<blockquote>.*?</blockquote>|<img[^>]*src="([^"]+)"[^>]*>|<ul>.*?</ul>|<ol>.*?</ol>)',
      caseSensitive: false,
    );
    
    final matches = blockRegex.allMatches(html);
    var index = 0;
    
    if (matches.isEmpty) {
      // Fallback: Split by double-newlines if the body is standard plaintext
      final paragraphs = body.split('\n\n');
      for (var i = 0; i < paragraphs.length; i++) {
        final text = paragraphs[i].trim();
        if (text.isEmpty) continue;
        widgets.add(_buildRichTextParagraph(text));
        widgets.add(const SizedBox(height: 24));
        _injectCTAs(widgets, i);
      }
      return widgets;
    }
    
    for (final match in matches) {
      final block = match.group(0)!;
      
      // 1. Inline S3 Image Block
      if (block.startsWith('<img') || block.startsWith('<IMG')) {
        final srcMatch = RegExp(r'src="([^"]+)"', caseSensitive: false).firstMatch(block);
        var url = srcMatch?.group(1) ?? '';
        if (url.isNotEmpty) {
          // Crucial Security Fix: Decode &amp; back to & in pre-signed S3 URLs
          // to prevent access denied / invalid signature errors.
          url = url.replaceAll('&amp;', '&');
          widgets.add(_buildInlineImage(url, ''));
          widgets.add(const SizedBox(height: 24));
        }
      }
      // 2. Header Blocks
      else if (block.startsWith('<h2>') || block.startsWith('<H2>')) {
        final text = _stripTags(block);
        if (text.isNotEmpty) {
          widgets.add(
            Text(
              _decodeHtmlEntities(text),
              style: AppTypography.headlineMd.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
          widgets.add(const SizedBox(height: 16));
        }
      }
      else if (block.startsWith('<h1>') || block.startsWith('<H1>')) {
        final text = _stripTags(block);
        if (text.isNotEmpty) {
          widgets.add(
            Text(
              _decodeHtmlEntities(text),
              style: AppTypography.headlineLg.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          );
          widgets.add(const SizedBox(height: 16));
        }
      }
      else if (block.startsWith('<h3>') || block.startsWith('<H3>')) {
        final text = _stripTags(block);
        if (text.isNotEmpty) {
          widgets.add(
            Text(
              _decodeHtmlEntities(text),
              style: AppTypography.headlineMd.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          );
          widgets.add(const SizedBox(height: 16));
        }
      }
      // 3. Blockquote Block
      else if (block.startsWith('<blockquote>') || block.startsWith('<BLOCKQUOTE>')) {
        final text = _stripTags(block);
        if (text.isNotEmpty) {
          widgets.add(_buildBlockquote(text));
          widgets.add(const SizedBox(height: 24));
        }
      }
      // 4. Bullet & Numbered List Blocks
      else if (block.startsWith('<ul>') || block.startsWith('<UL>')) {
        widgets.add(_buildListBlock(block, false));
        widgets.add(const SizedBox(height: 24));
      }
      else if (block.startsWith('<ol>') || block.startsWith('<OL>')) {
        widgets.add(_buildListBlock(block, true));
        widgets.add(const SizedBox(height: 24));
      }
      // 5. Standard Paragraph Block (which might wrap an inline <img src="...">)
      else if (block.startsWith('<p>') || block.startsWith('<P>')) {
        final text = _stripTags(block);
        if (text.isNotEmpty) {
          if (text.startsWith('<img') || text.startsWith('<IMG')) {
            final srcMatch = RegExp(r'src="([^"]+)"', caseSensitive: false).firstMatch(text);
            var url = srcMatch?.group(1) ?? '';
            if (url.isNotEmpty) {
              url = url.replaceAll('&amp;', '&');
              widgets.add(_buildInlineImage(url, ''));
              widgets.add(const SizedBox(height: 24));
            }
          } else {
            final decodedText = _decodeHtmlEntities(text);
            widgets.add(_buildRichTextParagraph(decodedText));
            widgets.add(const SizedBox(height: 24));
            _injectCTAs(widgets, index);
            index++;
          }
        }
      }
    }
    
    return widgets;
  }

  /// Extracts inner block copy by stripping outer tag elements.
  String _stripTags(String block) {
    final startTagRegex = RegExp(r'^<[a-zA-Z0-9]+[^>]*>');
    final endTagRegex = RegExp(r'</[a-zA-Z0-9]+>$');
    var text = block.replaceFirst(startTagRegex, '');
    text = text.replaceFirst(endTagRegex, '');
    return text.trim();
  }

  /// Fully decodes common XML / HTML entities used in rich-text prose.
  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ');
  }

  /// Renders a beautiful italic blockquote with a primary border accent.
  Widget _buildBlockquote(String text) {
    final decodedText = _decodeHtmlEntities(text);
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppColors.primary,
            width: 4,
          ),
        ),
      ),
      child: Text(
        decodedText,
        style: AppTypography.bodyMd.copyWith(
          color: AppColors.secondary,
          fontStyle: FontStyle.italic,
          height: 1.6,
        ),
      ),
    );
  }

  /// Parses and renders bulleted or ordered lists natively with bold red accents.
  Widget _buildListBlock(String block, bool isOrdered) {
    final listItems = <Widget>[];
    final liRegex = RegExp(r'<li>(.*?)</li>', caseSensitive: false);
    final matches = liRegex.allMatches(block);
    
    var index = 1;
    for (final match in matches) {
      final innerText = _stripTags(match.group(0)!);
      final decodedText = _decodeHtmlEntities(innerText);
      
      listItems.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isOrdered ? '$index. ' : '• ',
                style: AppTypography.bodyMd.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRichTextParagraph(decodedText),
              ),
            ],
          ),
        ),
      );
      index++;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: listItems,
    );
  }

  /// Conditionally injects subscription prompts and custom CTA blocks inline.
  void _injectCTAs(List<Widget> widgets, int index) {
    if (index == 1) {
      widgets.add(const _InlineSubscribePrompt());
      widgets.add(const SizedBox(height: 24));
    } else if (index == 2) {
      widgets.add(const _FinePrintInlineBlock());
      widgets.add(const SizedBox(height: 24));
    }
  }

  Widget _buildInlineImage(String url, String caption) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: AppNetworkImage(
              url: url,
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            caption,
            style: AppTypography.labelMd.copyWith(
              color: AppColors.secondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRichTextParagraph(String text) {
    // Force decode HTML/XML entities first to guarantee unescaped tags before parsing
    final decodedText = _decodeHtmlEntities(text);
    final List<InlineSpan> spans = _parseInlineSpans(decodedText);
    
    return RichText(
      text: TextSpan(
        style: AppTypography.bodyMd.copyWith(height: 1.8, color: AppColors.onSurface),
        children: spans,
      ),
    );
  }

  /// Recursively parses formatting tags inside text blocks to support nesting (e.g. em inside strong).
  List<InlineSpan> _parseInlineSpans(String text) {
    final List<InlineSpan> spans = [];
    final pattern = RegExp(
      r'(\*\*[\s\S]*?\*\*|\*[\s\S]*?\*|<b[^>]*>[\s\S]*?</b>|<i[^>]*>[\s\S]*?</i>|<strong[^>]*>[\s\S]*?</strong>|<em[^>]*>[\s\S]*?</em>)',
      caseSensitive: false,
    );
    
    final matches = pattern.allMatches(text);
    var lastMatchEnd = 0;
    
    for (final match in matches) {
      final textBefore = text.substring(lastMatchEnd, match.start);
      if (textBefore.isNotEmpty) {
        spans.add(TextSpan(text: textBefore));
      }
      
      final matchedText = match.group(0)!;
      final matchedLower = matchedText.toLowerCase();
      
      if (matchedLower.startsWith('**') && matchedLower.endsWith('**')) {
        final innerText = matchedText.substring(2, matchedText.length - 2);
        spans.add(TextSpan(
          style: const TextStyle(fontWeight: FontWeight.bold),
          children: _parseInlineSpans(innerText),
        ));
      } else if (matchedLower.startsWith('*') && matchedLower.endsWith('*')) {
        final innerText = matchedText.substring(1, matchedText.length - 1);
        spans.add(TextSpan(
          style: const TextStyle(fontStyle: FontStyle.italic),
          children: _parseInlineSpans(innerText),
        ));
      } else if (matchedLower.startsWith('<b') && matchedLower.endsWith('</b>')) {
        final openTagEnd = matchedText.indexOf('>') + 1;
        final innerText = matchedText.substring(openTagEnd, matchedText.length - 4);
        spans.add(TextSpan(
          style: const TextStyle(fontWeight: FontWeight.bold),
          children: _parseInlineSpans(innerText),
        ));
      } else if (matchedLower.startsWith('<i') && matchedLower.endsWith('</i>')) {
        final openTagEnd = matchedText.indexOf('>') + 1;
        final innerText = matchedText.substring(openTagEnd, matchedText.length - 4);
        spans.add(TextSpan(
          style: const TextStyle(fontStyle: FontStyle.italic),
          children: _parseInlineSpans(innerText),
        ));
      } else if (matchedLower.startsWith('<strong') && matchedLower.endsWith('</strong>')) {
        final openTagEnd = matchedText.indexOf('>') + 1;
        final innerText = matchedText.substring(openTagEnd, matchedText.length - 9);
        spans.add(TextSpan(
          style: const TextStyle(fontWeight: FontWeight.bold),
          children: _parseInlineSpans(innerText),
        ));
      } else if (matchedLower.startsWith('<em') && matchedLower.endsWith('</em>')) {
        final openTagEnd = matchedText.indexOf('>') + 1;
        final innerText = matchedText.substring(openTagEnd, matchedText.length - 5);
        spans.add(TextSpan(
          style: const TextStyle(fontStyle: FontStyle.italic),
          children: _parseInlineSpans(innerText),
        ));
      }
      lastMatchEnd = match.end;
    }
    
    final textAfter = text.substring(lastMatchEnd);
    if (textAfter.isNotEmpty) {
      spans.add(TextSpan(text: textAfter));
    }
    
    if (spans.isEmpty && text.isNotEmpty) {
      spans.add(TextSpan(text: text));
    }
    
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.paddingOf(context).top;
    final isBookmarked = ref.watch(
      bookmarksProvider.select((ids) => ids.contains(widget.articleId)),
    );
    
    // Asynchronously fetch this specific article's details from SQLite via ngrok
    final articleAsync = ref.watch(articleDetailProvider(widget.articleId));

    return Scaffold(
      appBar: ArticleAppBar(statusBarHeight: statusBarHeight),
      body: articleAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to Load Article',
                  style: AppTypography.labelLg,
                ),
                const SizedBox(height: 8),
                Text(
                  'Make sure the backend is active and ngrok is piping localhost:8000 successfully.',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelMd.copyWith(color: AppColors.secondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (kDebugMode) {
                      await ApiConfig.forceResolveDebugBaseUrl();
                    }
                    ref.invalidate(articleDetailProvider(widget.articleId));
                  },
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
        data: (article) => ListView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMobile,
                16,
                AppSpacing.marginMobile,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        color: AppColors.primary,
                        child: Text(
                          article.category.toUpperCase(),
                          style: AppTypography.labelMd
                              .copyWith(color: AppColors.onPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                          radius: 2, backgroundColor: AppColors.outlineVariant),
                      const SizedBox(width: 8),
                      Text(
                        article.isPremium ? 'PREMIUM' : 'ANALYSIS',
                        style: AppTypography.labelMd
                            .copyWith(color: AppColors.secondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    article.title,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 24,
                          height: 32 / 24,
                        ),
                  ),
                  if (article.excerpt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      article.excerpt!,
                      style: AppTypography.bodyLg.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.onSurfaceVariant.withOpacity(0.9),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.surfaceContainer),
                        bottom: BorderSide(color: AppColors.surfaceContainer),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (article.authorId != null) {
                                  context.push('/author/${article.authorId}');
                                }
                              },
                              child: Row(
                                children: [
                                  ClipOval(
                                    child: SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: AppNetworkImage(
                                          url: article.authorAvatarUrl ?? article.imageUrl), 
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (article.authorId != null) {
                                    context.push('/author/${article.authorId}');
                                  }
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      article.author.replaceAll('By ', ''),
                                      style: AppTypography.labelLg.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Banana Ganrajya Staff Correspondent',
                                      style: AppTypography.labelMd,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            _ListenButton(
                              isListening: _isListening,
                              onTap: () => _toggleAudio(article.audioUrl),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  article.timeAgo ?? 'TODAY',
                                  style: AppTypography.labelMd
                                      .copyWith(color: AppColors.secondary),
                                ),
                                const SizedBox(width: 8),
                                CircleAvatar(
                                    radius: 2,
                                    backgroundColor: AppColors.outlineVariant),
                                const SizedBox(width: 8),
                                Text(
                                  (article.readTime ?? '5 mins read').toUpperCase(),
                                  style: AppTypography.labelMd
                                      .copyWith(color: AppColors.secondary),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => ref
                                      .read(bookmarksProvider.notifier)
                                      .toggle(widget.articleId),
                                  child: Icon(
                                    Symbols.bookmark,
                                    fill: isBookmarked ? 1.0 : 0.0,
                                    color: isBookmarked
                                        ? AppColors.primary
                                        : AppColors.secondary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(Symbols.share,
                                    color: AppColors.secondary),
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
            const SizedBox(height: 24),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: AppNetworkImage(url: article.imageUrl),
            ),
            Container(
              width: double.infinity,
              color: AppColors.surfaceContainerLow,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile, vertical: 8),
              child: Text(
                'Media Coverage Desk | Photo: Special Arrangement for Banana Ganrajya',
                style: AppTypography.labelMd.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.secondary,
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  
                  // Build dynamic paragraphs with embedded CTA breaks
                  ..._buildBodyParagraphs(article.body ?? ''),
                  
                  const SizedBox(height: 32),
                  const Divider(height: 1),
                  const SizedBox(height: 24),
                  Text('Edited by Shoma Chaudhury',
                      style: AppTypography.labelMd.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.secondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final tag in [
                        '#${article.category}',
                        '#Banana GanrajyaAnalysis',
                        '#NationalResilience'
                      ])
                        Chip(
                          label: Text(tag),
                          labelStyle: AppTypography.labelMd
                              .copyWith(color: AppColors.onSurfaceVariant),
                          backgroundColor: AppColors.surfaceContainerHigh,
                          side: BorderSide.none,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      if (article.authorId != null) {
                        context.push('/author/${article.authorId}');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipOval(
                                child: SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: AppNetworkImage(
                                      url: article.imageUrl), // Profile photo fallback
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    article.author.replaceAll('By ', ''),
                                    style: Theme.of(context).textTheme.headlineMedium,
                                  ),
                                  Text('View Profile',
                                      style: AppTypography.labelMd.copyWith(
                                        color: AppColors.primary,
                                        decoration: TextDecoration.underline,
                                      )),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Reporting extensively on dynamic policy frameworks, economic indicators, '
                            'and strategic developments shaping public interest across regional ecosystems.',
                            style: AppTypography.bodyMd
                                .copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        Text('SHARE THIS ARTICLE',
                            style: AppTypography.labelMd
                                .copyWith(letterSpacing: 2)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ShareCircle(
                                icon: Symbols.alternate_email,
                                background: AppColors.onSurface,
                                iconColor: AppColors.surface),
                            const SizedBox(width: 20),
                            const _ShareCircle(
                                icon: Symbols.thumb_up,
                                background: Color(0xFF1877F2)),
                            const SizedBox(width: 20),
                            const _ShareCircle(
                                icon: Symbols.forum,
                                background: Color(0xFF25D366)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            CommentsSection(articleId: widget.articleId),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              color: AppColors.surfaceContainerLowest,
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Democracy Dies in Darkness',
                  style: TextStyle(
                    fontFamily: AppTypography.displayLg.fontFamily,
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 2,
                    color: AppColors.onSurface.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListenButton extends StatelessWidget {
  const _ListenButton({required this.isListening, required this.onTap});

  final bool isListening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isListening ? AppColors.onPrimaryFixed : AppColors.onSurface;
    final iconColor = isListening ? AppColors.onPrimaryFixed : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isListening
              ? AppColors.primaryFixed
              : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isListening ? Symbols.pause_circle : Symbols.volume_up,
              color: iconColor,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              isListening ? 'PLAYING' : 'LISTEN',
              style: AppTypography.labelMd.copyWith(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineSubscribePrompt extends StatelessWidget {
  const _InlineSubscribePrompt();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.primary, width: 2)),
      ),
      child: Column(
        children: [
          Text(
            'Quality journalism requires your support.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
          Text(
            'Banana Ganrajya is committed to independent, data-backed reporting '
            'that holds power to account.',
            textAlign: TextAlign.center,
            style:
                AppTypography.labelMd.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            child: const Text('SUBSCRIBE TO BANANA GANRAJYA'),
          ),
        ],
      ),
    );
  }
}

class _FinePrintInlineBlock extends StatelessWidget {
  const _FinePrintInlineBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: AppColors.fineprintGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
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
                Text('FINEPRINT EXCLUSIVE',
                    style: AppTypography.labelMd
                        .copyWith(letterSpacing: 2, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text("Inside the Finance Commission's Private Deliberations",
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '"The data suggests a 4% variance in tax devolution that '
              'could trigger a constitutional stalemate by 2026..."',
              style: AppTypography.bodyMd.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: AppColors.fineprintGradient,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    child: Text('Unlock Full Analysis',
                        style: AppTypography.labelLg
                            .copyWith(color: Colors.white)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareCircle extends StatelessWidget {
  const _ShareCircle({
    required this.icon,
    required this.background,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final Color background;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: background,
      child: Icon(icon, color: iconColor, size: 22),
    );
  }
}
