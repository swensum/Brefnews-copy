import 'package:html/parser.dart' as html_parser;

class News {
  final String id;
  final String title;
  final String summary; // This will now be automatically cleaned
  final String? imageUrl;
  final String sourceUrl;
  final String source; 
  final String category; 
  final DateTime publishedAt;
  final DateTime createdAt;
  final bool notified;
  final List<String> categories;
  final Map<String, dynamic>? headline;

  News({
    required this.id,
    required this.title,
    required String summary, // Change to required String
    this.imageUrl,
    required this.sourceUrl,
    required this.source,
    required this.category,
    required this.publishedAt,
    required this.createdAt,
    required this.notified,
    this.categories = const [],
    this.headline, 
  }) : summary = _cleanHtmlSummary(summary); // Clean HTML in constructor

  factory News.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? headlineData;
    if (json['headline'] != null) {
      if (json['headline'] is Map) {
        headlineData = Map<String, dynamic>.from(json['headline']);
      }
    }
    
    return News(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '', // This gets cleaned in constructor
      imageUrl: json['image_url']?.toString(),
      sourceUrl: json['source_url']?.toString() ?? '',
      source: json['source']?.toString() ?? 'Unknown',
      category: json['topics']?.toString() ?? 'News',
      publishedAt: DateTime.parse(json['published_at']?.toString() ?? DateTime.now().toString()),
      createdAt: DateTime.parse(json['created_at']?.toString() ?? DateTime.now().toString()),
      notified: json['notified'] ?? false,
      categories: json['categories'] != null 
          ? List<String>.from(json['categories'])
          : <String>[],
      headline: headlineData, 
    );
  }

  // HTML cleaning method
  static String _cleanHtmlSummary(String htmlString) {
    try {
      if (htmlString.isEmpty) return '';
      
      final document = html_parser.parse(htmlString);
      final plainText = document.body?.text ?? htmlString;
      
      // Basic cleaning if parsing doesn't work well
      return _basicClean(plainText);
    } catch (e) {
      // If parsing fails, do basic cleaning
      return _basicClean(htmlString);
    }
  }

  static String _basicClean(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove any remaining HTML tags
        .replaceAll('&#8230;', '...') // Replace ellipsis
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary, // This is now clean text
      'image_url': imageUrl,
      'source_url': sourceUrl,
      'source': source,
      'category': category,
      'published_at': publishedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'notified': notified,
      'categories': categories,
      'headline': headline,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}w ago';
    return '${(difference.inDays / 30).floor()}mo ago';
  }
}

class Topic {
  final String id;
  final String name;
  final String? imageUrl;

  Topic({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['image_url'],
    );
  }
}