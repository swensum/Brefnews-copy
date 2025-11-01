import 'package:flutter/material.dart';

class VideoArticle {
  final String id;
  final String title;
  final String videoUrl;
  final String sourceName;
  final String? sourceLogoUrl;
  final String platformName;
  final String platformUrl;
  final DateTime publishedAt;
  final DateTime createdAt;
  final bool notified;
  
  // Translated fields
  final String translatedTitle;
  final String translatedSourceName;
  final String translatedPlatformName;

  VideoArticle({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.sourceName,
    this.sourceLogoUrl,
    required this.platformName,
    required this.platformUrl,
    required this.publishedAt,
    required this.createdAt,
    required this.notified,
    required this.translatedTitle,
    required this.translatedSourceName,
    required this.translatedPlatformName,
  });

  factory VideoArticle.fromJson(Map<String, dynamic> json) {
    return VideoArticle(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      videoUrl: json['video_url'] ?? '',
      sourceName: json['source_name'] ?? '',
      sourceLogoUrl: json['source_logo_url'],
      platformName: json['platform_name'] ?? '',
      platformUrl: json['platform_url'] ?? '',
      publishedAt: DateTime.parse(json['published_at'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      notified: json['notified'] ?? false,
      translatedTitle: json['translated_title'] ?? json['title'] ?? '',
      translatedSourceName: json['translated_source_name'] ?? json['source_name'] ?? '',
      translatedPlatformName: json['translated_platform_name'] ?? json['platform_name'] ?? '',
    );
  }
 String getTranslatedTitle(BuildContext context) {
    // Return translated title if available, otherwise fallback to original
    return translatedTitle.isNotEmpty == true ? translatedTitle : title;
  }

  String getTranslatedSourceName(BuildContext context) {
    // Return translated source name if available, otherwise fallback to original
    return translatedSourceName.isNotEmpty == true ? translatedSourceName : sourceName;
  }

  String getTranslatedPlatformName(BuildContext context) {
    // Return translated platform name if available, otherwise fallback to original
    return translatedPlatformName.isNotEmpty == true ? translatedPlatformName : platformName;
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