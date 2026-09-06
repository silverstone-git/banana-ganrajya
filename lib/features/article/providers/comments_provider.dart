import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_client_provider.dart';
import '../models/comment.dart';

class CommentsState {
  final bool isLoading;
  final String? errorMessage;
  final List<ArticleComment> comments;

  CommentsState({
    required this.isLoading,
    this.errorMessage,
    required this.comments,
  });

  CommentsState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<ArticleComment>? comments,
  }) {
    return CommentsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      comments: comments ?? this.comments,
    );
  }
}

class CommentsNotifier extends StateNotifier<CommentsState> {
  final Ref ref;
  final String articleId;

  CommentsNotifier(this.ref, this.articleId)
      : super(CommentsState(isLoading: false, comments: const [])) {
    fetchComments();
  }

  Future<void> fetchComments() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/api/articles/$articleId/comments');
      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        final comments = data
            .map((item) => ArticleComment.fromJson(item as Map<String, dynamic>))
            .toList();
        state = state.copyWith(isLoading: false, comments: comments);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Server returned status: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> addComment(String body, {String? parentId}) async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        '/api/articles/$articleId/comments',
        data: {
          'body': body,
          'parent_id': parentId,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchComments();
        return true;
      }
    } catch (e) {
      debugPrint('[CommentsNotifier] Failed to post comment: $e');
    }
    return false;
  }
}

final commentsProvider =
    StateNotifierProvider.family<CommentsNotifier, CommentsState, String>((ref, articleId) {
  return CommentsNotifier(ref, articleId);
});
