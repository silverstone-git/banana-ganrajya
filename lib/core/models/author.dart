/// Represents an editorial author or columnist.
class Author {
  const Author({
    required this.id,
    required this.name,
    required this.title,
    this.bio,
    required this.avatarUrl,
  });

  final String id;
  final String name;
  final String title;
  final String? bio;
  final String avatarUrl;

  /// Creates an [Author] profile from a JSON map returned by the backend API.
  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] as String,
      name: json['name'] as String,
      title: json['title'] as String,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String,
    );
  }
}
