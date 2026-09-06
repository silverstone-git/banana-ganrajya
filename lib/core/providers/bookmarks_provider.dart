import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client_provider.dart';
import 'auth_provider.dart';


/// Tracks bookmarked article ids for the session synchronized with the remote database.
class BookmarksNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    // Watch authentication state changes. When logging in or out, rebuild and refetch bookmarks
    ref.watch(authProvider);
    
    // Asynchronously fetch current bookmarks from remote database
    Future.microtask(() => fetchBookmarks());
    
    return <String>{};
  }

  /// Fetches bookmarked article IDs from the backend API.
  Future<void> fetchBookmarks() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/api/bookmarks');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final articleIds = data.map((item) => item['id'] as String).toSet();
        state = articleIds;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BookmarksNotifier] Failed to fetch bookmarks from backend: $e');
      }
    }
  }

  /// Toggles bookmark state optimistically in the UI, then syncs with the remote database.
  /// Rolls back state gracefully on network failure.
  Future<void> toggle(String articleId) async {
    final isAlreadyBookmarked = state.contains(articleId);
    
    // Optimistic UI Update
    final next = {...state};
    if (isAlreadyBookmarked) {
      next.remove(articleId);
    } else {
      next.add(articleId);
    }
    state = next;

    try {
      final dio = ref.read(dioProvider);
      if (isAlreadyBookmarked) {
        await dio.delete('/api/bookmarks/$articleId');
      } else {
        await dio.post('/api/bookmarks/$articleId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BookmarksNotifier] Failed to toggle bookmark on backend: $e');
      }
      // Rollback state on failure
      final revert = {...state};
      if (isAlreadyBookmarked) {
        revert.add(articleId);
      } else {
        revert.remove(articleId);
      }
      state = revert;
    }
  }

  bool isBookmarked(String articleId) => state.contains(articleId);
}

final bookmarksProvider =
    NotifierProvider<BookmarksNotifier, Set<String>>(BookmarksNotifier.new);

