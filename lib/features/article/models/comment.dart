/// Represents a comment or replies in an article discussion thread.
class ArticleComment {
  final String id;
  final String articleId;
  final String userName;
  final String? userAvatar;
  final String body;
  final DateTime createdAt;
  final List<ArticleComment> replies;

  ArticleComment({
    required this.id,
    required this.articleId,
    required this.userName,
    this.userAvatar,
    required this.body,
    required this.createdAt,
    required this.replies,
  });

  /// Factory constructor to parse comment schema JSON recursively
  factory ArticleComment.fromJson(Map<String, dynamic> json) {
    final rawReplies = json['replies'] as List<dynamic>? ?? [];
    final replies = rawReplies
        .map((item) => ArticleComment.fromJson(item as Map<String, dynamic>))
        .toList();

    return ArticleComment(
      id: json['id'] as String,
      articleId: json['article_id'] as String,
      userName: json['user_name'] as String,
      userAvatar: json['user_avatar'] as String?,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      replies: replies,
    );
  }
}
