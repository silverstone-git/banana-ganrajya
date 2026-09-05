import 'package:flutter_test/flutter_test.dart';
import 'package:banana/features/article/models/comment.dart';
import 'package:banana/features/search/providers/search_provider.dart';

void main() {
  group('Comments Model Unit Tests', () {
    test('ArticleComment should correctly parse recursive threaded JSON replies', () {
      final jsonPayload = {
        'id': 'comment-1',
        'article_id': 'article-123',
        'user_name': 'Aria Smith',
        'user_avatar': 'https://example.com/avatar1.jpg',
        'body': 'This is an excellent analysis of the legal reforms.',
        'created_at': '2026-08-01T12:00:00Z',
        'replies': [
          {
            'id': 'reply-1',
            'article_id': 'article-123',
            'user_name': 'Devin Jones',
            'user_avatar': null,
            'body': 'I agree with your perspective!',
            'created_at': '2026-08-01T12:15:00Z',
            'replies': []
          }
        ]
      };

      final comment = ArticleComment.fromJson(jsonPayload);

      expect(comment.id, 'comment-1');
      expect(comment.articleId, 'article-123');
      expect(comment.userName, 'Aria Smith');
      expect(comment.userAvatar, 'https://example.com/avatar1.jpg');
      expect(comment.body, 'This is an excellent analysis of the legal reforms.');
      expect(comment.createdAt, DateTime.parse('2026-08-01T12:00:00Z'));
      
      expect(comment.replies.length, 1);
      final reply = comment.replies.first;
      expect(reply.id, 'reply-1');
      expect(reply.userName, 'Devin Jones');
      expect(reply.userAvatar, isNull);
      expect(reply.body, 'I agree with your perspective!');
      expect(reply.replies, isEmpty);
    });
  });

  group('SearchState Unit Tests', () {
    test('SearchState should correctly instantiate with initial state defaults', () {
      final state = SearchState.initial();
      expect(state.query, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.articles, isEmpty);
      expect(state.authors, isEmpty);
      expect(state.tags, isEmpty);
      expect(state.history, isEmpty);
    });

    test('SearchState copyWith should safely overwrite specified properties', () {
      final initialState = SearchState.initial();
      final updatedState = initialState.copyWith(
        query: 'Ecosystem',
        isLoading: true,
        history: ['National', 'Ecosystem'],
      );

      expect(updatedState.query, 'Ecosystem');
      expect(updatedState.isLoading, isTrue);
      expect(updatedState.history, ['National', 'Ecosystem']);
      
      // Unspecified elements should keep their defaults
      expect(updatedState.errorMessage, isNull);
      expect(updatedState.articles, isEmpty);
    });
  });
}
