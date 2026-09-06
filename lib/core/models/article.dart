/// A minimal, plain (non-freezed) article model used to drive the mock
/// content on every screen.
///
/// Kept deliberately simple for this UI bootstrap. When you wire this up to
/// your backend, this is the shape to replace with a generated
/// `json_serializable`/`freezed` model in a `features/<x>/domain/entities`
/// folder, fed by a repository — see the auth example discussed earlier in
/// this conversation for the layering pattern to follow.
class Article {
  const Article({
    required this.id,
    required this.category,
    required this.title,
    required this.imageUrl,
    required this.author,
    this.authorId, // Add authorId property
    this.readTime,
    this.timeAgo,
    this.excerpt,
    this.body,
    this.isPremium = false,
    this.isLocked = false,
    this.audioUrl,
    this.authorAvatarUrl,
  });

  final String id;
  final String category;
  final String title;
  final String imageUrl;
  final String author;
  final String? authorId; // Add authorId property
  final String? readTime;
  final String? timeAgo;
  final String? excerpt;
  final String? body;
  final bool isPremium;
  final bool isLocked;
  final String? audioUrl;
  final String? authorAvatarUrl;

  /// Creates an [Article] from a JSON map returned by the backend API.
  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String,
      author: json['author'] as String,
      authorId: json['authorId'] as String?, // Parse authorId directly
      readTime: json['readTime'] as String?,
      timeAgo: json['timeAgo'] as String?,
      excerpt: json['excerpt'] as String?,
      body: json['body'] as String?,
      isPremium: json['isPremium'] as bool? ?? false,
      isLocked: json['isLocked'] as bool? ?? false,
      audioUrl: json['audioUrl'] as String?,
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
    );
  }
}
