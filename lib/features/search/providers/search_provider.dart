import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/article.dart';
import '../../../core/models/author.dart';
import '../../../core/providers/api_client_provider.dart';

class SearchState {
  final String query;
  final bool isLoading;
  final String? errorMessage;
  final List<Article> articles;
  final List<Author> authors;
  final List<String> tags;
  final List<String> history;

  SearchState({
    required this.query,
    required this.isLoading,
    this.errorMessage,
    required this.articles,
    required this.authors,
    required this.tags,
    required this.history,
  });

  SearchState.initial()
      : query = '',
        isLoading = false,
        errorMessage = null,
        articles = const [],
        authors = const [],
        tags = const [],
        history = const [];

  SearchState copyWith({
    String? query,
    bool? isLoading,
    String? errorMessage,
    List<Article>? articles,
    List<Author>? authors,
    List<String>? tags,
    List<String>? history,
  }) {
    return SearchState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      articles: articles ?? this.articles,
      authors: authors ?? this.authors,
      tags: tags ?? this.tags,
      history: history ?? this.history,
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  Timer? _debounceTimer;
  static const String _historyKey = 'search_history_queries';

  @override
  SearchState build() {
    _loadHistory();
    return SearchState.initial();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_historyKey) ?? [];
      state = state.copyWith(history: history);
    } catch (e) {
      debugPrint('[SearchNotifier] Failed to load history: $e');
    }
  }

  void setQuery(String query) {
    if (state.query == query) return;
    
    state = state.copyWith(query: query, errorMessage: null);

    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      state = state.copyWith(
        isLoading: false,
        articles: const [],
        authors: const [],
        tags: const [],
      );
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      performSearch(query.trim());
    });
  }

  Future<void> performSearch(String query) async {
    if (query.isEmpty) return;

    _debounceTimer?.cancel();
    state = state.copyWith(query: query, isLoading: true, errorMessage: null);

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/api/search', queryParameters: {'q': query});

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        final rawArticles = data['articles'] as List<dynamic>? ?? [];
        final rawAuthors = data['authors'] as List<dynamic>? ?? [];
        final rawTags = data['tags'] as List<dynamic>? ?? [];

        final articles = rawArticles
            .map((item) => Article.fromJson(item as Map<String, dynamic>))
            .toList();

        final authors = rawAuthors
            .map((item) => Author.fromJson(item as Map<String, dynamic>))
            .toList();

        final tags = rawTags.map((item) => item.toString()).toList();

        state = state.copyWith(
          isLoading: false,
          articles: articles,
          authors: authors,
          tags: tags,
        );

        // Add to history only after a successful search
        _addToHistory(query);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Server returned unexpected status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message ?? 'An error occurred during search.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _addToHistory(String query) async {
    final cleanedQuery = query.trim();
    if (cleanedQuery.isEmpty) return;

    final updatedHistory = List<String>.from(state.history);
    updatedHistory.removeWhere((item) => item.toLowerCase() == cleanedQuery.toLowerCase());
    updatedHistory.insert(0, cleanedQuery);

    if (updatedHistory.length > 10) {
      updatedHistory.removeLast();
    }

    state = state.copyWith(history: updatedHistory);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_historyKey, updatedHistory);
    } catch (e) {
      debugPrint('[SearchNotifier] Failed to save history: $e');
    }
  }

  Future<void> deleteHistoryItem(String query) async {
    final updatedHistory = List<String>.from(state.history)..remove(query);
    state = state.copyWith(history: updatedHistory);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_historyKey, updatedHistory);
    } catch (e) {
      debugPrint('[SearchNotifier] Failed to save history: $e');
    }
  }

  Future<void> clearHistory() async {
    state = state.copyWith(history: const []);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      debugPrint('[SearchNotifier] Failed to clear history: $e');
    }
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
