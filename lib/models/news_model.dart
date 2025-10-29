class News {
  final String id;
  final String title;
  final String summary; 
  final String? imageUrl;
  final String sourceUrl;
  final String source; 
  final String category; // This will now show the topic name
  final DateTime publishedAt;
  final DateTime createdAt;
  final bool notified;
  final List<String> categories;
  final Map<String, dynamic>? headline;
  News({
    required this.id,
    required this.title,
    required this.summary,
    this.imageUrl,
    required this.sourceUrl,
    required this.source,
    required this.category,
    required this.publishedAt,
    required this.createdAt,
    required this.notified,
    this.categories = const [],
     this.headline, 
  });

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
      summary: json['summary']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      sourceUrl: json['source_url']?.toString() ?? '',
      source: json['source']?.toString() ?? 'Unknown',
      // FIX: Use topics field instead of category field
      category: json['topics']?.toString() ?? 'News', // Changed from 'General' to 'News'
      publishedAt: DateTime.parse(json['published_at']?.toString() ?? DateTime.now().toString()),
      createdAt: DateTime.parse(json['created_at']?.toString() ?? DateTime.now().toString()),
      notified: json['notified'] ?? false,
      categories: json['categories'] != null 
          ? List<String>.from(json['categories'])
          : <String>[],
            headline: headlineData, 
    
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
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