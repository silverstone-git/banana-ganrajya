import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/article.dart';
import '../models/author.dart';
import 'api_client_provider.dart';

/// Response payload representation of the Home Screen Feed.
class HomeFeedData {
  HomeFeedData({
    required this.heroStory,
    required this.secondaryStories,
    required this.groundReports,
  });

  final Article heroStory;
  final List<Article> secondaryStories;
  final List<Article> groundReports;
}

/// Response payload representation of the FinePrint (Premium) Screen Feed.
class FineprintFeedData {
  FineprintFeedData({
    required this.featured,
    required this.list,
  });

  final Article featured;
  final List<Article> list;
}

/// Representation of Columnist biography & profile details.
class ColumnistData {
  ColumnistData({
    required this.name,
    required this.avatarUrl,
    required this.title,
  });

  final String name;
  final String avatarUrl;
  final String title;

  factory ColumnistData.fromJson(Map<String, dynamic> json) {
    return ColumnistData(
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String,
      title: json['title'] as String,
    );
  }
}

/// Response payload representation of the Opinion Screen Feed.
class OpinionFeedData {
  OpinionFeedData({
    required this.featured,
    required this.rows,
    required this.columnists,
  });

  final Article featured;
  final List<Article> rows;
  final List<ColumnistData> columnists;
}

/// FutureProvider that fetches the curated Home feed asynchronously.
final homeFeedProvider = FutureProvider<HomeFeedData>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/api/feed/home');
  final data = response.data as Map<String, dynamic>;

  return HomeFeedData(
    heroStory: Article.fromJson(data['heroStory'] as Map<String, dynamic>),
    secondaryStories: (data['secondaryStories'] as List)
        .map((e) => Article.fromJson(e as Map<String, dynamic>))
        .toList(),
    groundReports: (data['groundReports'] as List)
        .map((e) => Article.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
});

/// FutureProvider that fetches the Premium FinePrint investigative feed.
final fineprintFeedProvider = FutureProvider<FineprintFeedData>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/api/feed/fineprint');
  final data = response.data as Map<String, dynamic>;

  return FineprintFeedData(
    featured: Article.fromJson(data['featured'] as Map<String, dynamic>),
    list: (data['list'] as List)
        .map((e) => Article.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
});

/// FutureProvider that fetches the Columnist Opinion articles and author list.
final opinionFeedProvider = FutureProvider<OpinionFeedData>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/api/feed/opinion');
  final data = response.data as Map<String, dynamic>;

  return OpinionFeedData(
    featured: Article.fromJson(data['featured'] as Map<String, dynamic>),
    rows: (data['rows'] as List)
        .map((e) => Article.fromJson(e as Map<String, dynamic>))
        .toList(),
    columnists: (data['columnists'] as List)
        .map((e) => ColumnistData.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
});

/// FutureProvider parameter family that fetches individual article details.
final articleDetailProvider = FutureProvider.family<Article, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/api/articles/$id');
  return Article.fromJson(response.data as Map<String, dynamic>);
});

/// FutureProvider that fetches politics-specific news stories dynamically.
final politicsArticlesProvider = FutureProvider<List<Article>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/api/articles', queryParameters: {'category': 'POLITICS'});
  return (response.data as List)
      .map((e) => Article.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// FutureProvider parameter family that fetches individual author profile details.
final authorProfileProvider = FutureProvider.family<Author, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/api/authors/$id');
  return Author.fromJson(response.data as Map<String, dynamic>);
});

/// FutureProvider parameter family that fetches dynamic chronologically paginated articles written by an author.
final authorArticlesProvider = FutureProvider.family<List<Article>, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/api/authors/$id/articles');
  return (response.data as List)
      .map((e) => Article.fromJson(e as Map<String, dynamic>))
      .toList();
});
