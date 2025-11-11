import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_model.dart';
import '../models/video_model.dart';
import '../supabase/supabase_client.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NewsProvider with ChangeNotifier {
  
  List<News> _allNews = [];
  List<News> _filteredNews = [];
  String _selectedCategory = 'My Feed';
  bool _isLoading = true;
  bool _hasError = false;
  List<Map<String, dynamic>> _topics = [];
  List<Map<String, dynamic>> get topics => _topics;
  List<News> _topicNews = [];
  List<News> get topicNews => _topicNews;

  bool _isLoadingTopicNews = false;
  bool get isLoadingTopicNews => _isLoadingTopicNews;

  List<News> get news => _filteredNews;
  List<News> get allNews => _allNews;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
List<VideoArticle> _videos = [];
  bool _isLoadingVideos = false;
  String? _videosError;

  List<VideoArticle> get videos => _videos;
  bool get isLoadingVideos => _isLoadingVideos;
  String? get videosError => _videosError;
  List<String> _bookmarkedNewsIds = [];
  // Language support
  String _currentLanguage = 'en';
  String get currentLanguage => _currentLanguage;
  List<Map<String, dynamic>> _headlines = [];
  List<Map<String, dynamic>> get headlines => _headlines;
  bool _isLoadingHeadlines = false;
  bool get isLoadingHeadlines => _isLoadingHeadlines;

  List<News> get notifiedNews {
    return _allNews.where((news) => news.notified == true).toList();
  }

  List<News> get bookmarkedNews {
    // Filter allNews to get bookmarked articles with current language
    return _allNews
        .where((news) => _bookmarkedNewsIds.contains(news.id))
        .toList();
  }

  final Map<String, DateTime> _bookmarkDates = {};

  // SharedPreferences keys
  static const String _bookmarkedNewsKey = 'bookmarked_news';
  static const String _bookmarkDatesKey = 'bookmark_dates';
  static const String _dynamicCategoriesKey = 'dynamic_categories';
  static const String _currentLanguageKey = 'current_language';

  List<String> _dynamicCategories = [];

  // Store category keys instead of hardcoded text
  final List<String> _staticCategoryKeys = [
    'myFeed',
    'finance',
    'timeline',
    'videos',
    'goodNews',
  ];
  List<String> get categories {
    List<String> allCategories = [];

    // Add static categories (always show these)
    allCategories.addAll(
      _staticCategoryKeys.map((key) {
        switch (key) {
          case 'myFeed':
            return 'My Feed';
          case 'finance':
            return 'Finance';
          case 'timeline':
            return 'Timeline';
          case 'videos':
            return 'Videos';
          case 'goodNews':
            return 'Good News';
          default:
            return key;
        }
      }),
    );
    allCategories.addAll(_dynamicCategories);

    return allCategories.toSet().toList();
  }

  final List<String> _searchCategories = [
    'My Feed',
    'Top Stories',
    'Trending',
    'Bookmarks',
    'Unread',
  ];

  List<String> get searchCategories => _searchCategories;

  NewsProvider() {
    _initializeApp();
  }

Future<void> loadVideos() async {
  if (_isLoadingVideos) return;
  
  _isLoadingVideos = true;
  _videosError = null;
  notifyListeners();

  try {
    // Use the PostgreSQL function to get translated videos
    final response = await SupabaseService().client
        .rpc(
          'get_translated_videos',
          params: {
            'target_language': _currentLanguage,
            'limit_count': 50,
          },
        )
        .select();

    print('🎬 [Video Debug] Raw response for language $_currentLanguage:');
    for (var video in response) {
      print('🎬 Video: ${video['title']} -> ${video['translated_title']}');
      print('🎬 Source: ${video['source_name']} -> ${video['translated_source_name']}');
      print('🎬 Platform: ${video['platform_name']} -> ${video['translated_platform_name']}');
      print('---');
    }

    _videos = response.map<VideoArticle>((videoData) {
      return VideoArticle.fromJson(videoData);
    }).toList();
    
    print('🟢 [NewsProvider] Loaded ${_videos.length} translated videos for language: $_currentLanguage');
  } catch (e) {
    _videosError = 'Failed to load videos: $e';
    print('❌ Error loading videos: $e');
    
    // Fallback code remains the same...
  } finally {
    _isLoadingVideos = false;
    notifyListeners();
  }
}

  Future<void> refreshVideos() async {
    _videos.clear();
    await loadVideos();
  }

  // Check if we have videos data
  bool get hasVideos => _videos.isNotEmpty;





  Future<void> fetchHeadlines() async {
    try {
      _isLoadingHeadlines = true;
      final response = await SupabaseService().client
          .from('headlines')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      _headlines = List<Map<String, dynamic>>.from(response);
      print('🟢 [NewsProvider] Loaded ${_headlines.length} headlines');
    } catch (e) {
      print('🔴 [NewsProvider] Failed to load headlines: $e');
      _headlines = [];
    } finally {
      _isLoadingHeadlines = false;
      notifyListeners(); // Only call this once at the end
    }
  }

  Future<Map<String, List<News>>> getNewsGroupedByHeadlines() async {
    try {
      final response = await SupabaseService().client
          .rpc(
            'get_news_grouped_by_headlines',
            params: {'target_language': _currentLanguage},
          )
          .select();

      // The response now contains complete headline data
      final Map<String, List<News>> groupedNews = {};

      for (final item in response) {
        final headlineId = item['headline_id'].toString();
        final newsList = (item['news_articles'] as List)
            .map((newsJson) => News.fromJson(newsJson))
            .toList();

        groupedNews[headlineId] = newsList;

        // Debug: Print what we're getting
        print('🟢 Headline ID: $headlineId, News Count: ${newsList.length}');
        print('🟢 Headline Text: ${item['headline_text']}');
      }

      return groupedNews;
    } catch (e) {
      print('🔴 [NewsProvider] Failed to get grouped news: $e');
      return {};
    }
  }

  // ========== APP INITIALIZATION ==========

  Future<void> _initializeApp() async {
    await _loadBookmarksFromSharedPreferences();
    await _loadDynamicCategories();
    await _initializeLanguage();
  }

  // ========== LANGUAGE METHODS ==========

  Future<void> _initializeLanguage() async {
    await _loadCurrentLanguage();
    // Load news with the saved language immediately
    await loadNews();
  }

  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    await _saveCurrentLanguage();
    await loadNews();
    await fetchTopics();
     await loadVideos();
    notifyListeners();
  }

  Future<void> _loadCurrentLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString(_currentLanguageKey) ?? 'en';
    } catch (e) {
      if (kDebugMode) print('Error loading language: $e');
      _currentLanguage = 'en';
    }
  }

  Future<void> _saveCurrentLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentLanguageKey, _currentLanguage);
    } catch (e) {
      if (kDebugMode) print('Error saving language: $e');
    }
  }
 
  Future<void> loadNews() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      String? rpcCategoryFilter;
      final response = await SupabaseService().client
          .rpc(
            'get_translated_news_with_notified',
            params: {
              'target_language': _currentLanguage,
              'limit_count': 300,
              'category_filter': rpcCategoryFilter,
            },
          )
          .select();

      _allNews = response.map<News>((item) => News.fromJson(item)).toList();
      _filterNewsByCategory(_selectedCategory);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> fetchNewsByTopic(String topic) async {
    String topicForQuery = topic;

    try {
      _isLoadingTopicNews = true;
      notifyListeners();
      topicForQuery = topic;

      if (_topics.isNotEmpty) {
        final topicData = _topics.firstWhere(
          (t) => t['name'] == topic,
          orElse: () => {},
        );

        if (topicData.isNotEmpty && topicData.containsKey('original_name')) {
          topicForQuery = topicData['original_name'] as String;
        }
      }

      final response = await SupabaseService().client
          .rpc(
            'get_translated_news',
            params: {
              'target_language': _currentLanguage,
              'limit_count': 50,
              'category_filter': topicForQuery,
            },
          )
          .select();

      _topicNews = response.map<News>((data) => News.fromJson(data)).toList();
    } catch (e) {
      print('🔴 [NewsProvider] Error fetching topic news: $e');
    } finally {
      _isLoadingTopicNews = false;
      notifyListeners();
    }
  }

  void addDynamicCategory(String category) {
    if (!_dynamicCategories.contains(category) &&
        !_staticCategoryKeys.contains(category)) {
      _dynamicCategories.add(category);
      _saveDynamicCategories();
      notifyListeners();
    }
  }

  bool get hasBookmarks => _bookmarkedNewsIds.isNotEmpty;

  Future<void> _loadDynamicCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = prefs.getStringList(_dynamicCategoriesKey);
      if (categoriesJson != null) {
        _dynamicCategories = categoriesJson;
        print(
          '🟢 [NewsProvider] Loaded dynamic categories: $_dynamicCategories',
        );
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('Error loading categories: $e');
    }
  }

  Future<void> fetchTopics() async {
    try {
      final topicsData = await SupabaseService().getTopics(
        language: _currentLanguage,
      );
      _topics = topicsData;
      notifyListeners();
      for (final topic in _topics) {
        print(
          '🔍 Topic: ${topic['name']} (original: ${topic['original_name']})',
        );
      }
    } catch (e) {
      print('Error fetching topics: $e');
    }
  }

  Future<void> _saveDynamicCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_dynamicCategoriesKey, _dynamicCategories);
    } catch (e) {
      if (kDebugMode) print('Error saving categories: $e');
    }
  }

  Future<void> _loadBookmarksFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load bookmarked news IDs
      _bookmarkedNewsIds = prefs.getStringList(_bookmarkedNewsKey) ?? [];

      // Load bookmark dates
      final bookmarkDatesJson = prefs.getString(_bookmarkDatesKey);
      if (bookmarkDatesJson != null) {
        try {
          final datesMap = Map<String, dynamic>.from(
            json.decode(bookmarkDatesJson),
          );
          datesMap.forEach((newsId, timestamp) {
            if (timestamp is int) {
              _bookmarkDates[newsId] = DateTime.fromMillisecondsSinceEpoch(
                timestamp,
              );
            }
          });
        } catch (e) {
          if (kDebugMode) print('Error loading bookmark dates: $e');
        }
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error loading bookmarks: $e');
    }
  }

  Future<void> _saveBookmarksToSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save only IDs
      await prefs.setStringList(_bookmarkedNewsKey, _bookmarkedNewsIds);

      final bookmarkDatesMap = <String, int>{};
      _bookmarkDates.forEach((newsId, dateTime) {
        bookmarkDatesMap[newsId] = dateTime.millisecondsSinceEpoch;
      });
      await prefs.setString(_bookmarkDatesKey, json.encode(bookmarkDatesMap));
    } catch (e) {
      if (kDebugMode) print('Error saving bookmarks: $e');
    }
  }

  void toggleBookmark(News news) {
    if (_bookmarkedNewsIds.contains(news.id)) {
      _bookmarkedNewsIds.remove(news.id);
      _bookmarkDates.remove(news.id);
    } else {
      _bookmarkedNewsIds.add(news.id);
      _bookmarkDates[news.id] = DateTime.now();
    }

    if (_bookmarkedNewsIds.isEmpty &&
        _dynamicCategories.contains('Bookmarks')) {
      _dynamicCategories.remove('Bookmarks');
      _saveDynamicCategories();
    }

    _saveBookmarksToSharedPreferences();
    notifyListeners();
  }

  bool isBookmarked(News news) {
    return _bookmarkedNewsIds.contains(news.id);
  }

  DateTime getBookmarkDate(News news) =>
      _bookmarkDates[news.id] ?? DateTime.now();

  void removeBookmark(News news) {

    _bookmarkedNewsIds.remove(news.id);

    _bookmarkDates.remove(news.id);
    if (_bookmarkedNewsIds.isEmpty &&
        _dynamicCategories.contains('Bookmarks')) {
      _dynamicCategories.remove('Bookmarks');
      _saveDynamicCategories();
    }
    _saveBookmarksToSharedPreferences();
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _filterNewsByCategory(category);
    notifyListeners();
  }

  void _filterNewsByCategory(String category) {
    if (category == 'My Feed') {
      _filteredNews = List.from(_allNews);
    } else if (category == 'Timeline') {
      _filteredNews = List.from(_allNews);
    } else if (category == 'Bookmarks') {
      _filteredNews = List.from(bookmarkedNews);
    } else if (category == 'Trending') {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      _filteredNews = _allNews
          .where((news) => news.publishedAt.isAfter(yesterday))
          .toList();
    } else if (category == 'Top Stories') {
      _filteredNews = _allNews.where((news) {
        return news.categories.any(
          (cat) =>
              cat.toLowerCase().contains('top') ||
              cat.toLowerCase().contains('stories') ||
              cat.toLowerCase() == 'top_stories' ||
              cat.toLowerCase() == 'top news',
        );
      }).toList();
    } else if (category == 'Good News') {
      _filteredNews = _allNews.where((news) {
        return news.categories.any(
          (cat) =>
              cat.toLowerCase().contains('good') ||
              cat.toLowerCase().contains('news') ||
              cat.toLowerCase() == 'good_news' ||
              cat.toLowerCase() == 'Good news' ||
              cat.toLowerCase() == 'good news',
        );
      }).toList();
    } else if (category == 'Finance') {
      _filteredNews = _allNews.where((news) {
        final exactCategoriesMatch = news.categories.any((cat) {
          return cat == 'Finance' ||
              cat == 'FINANCE' ||
              cat == 'finance' ||
              cat == 'Finanace' ||
              cat == 'Financial';
        });
        final mainCategoryMatch =
            news.category == 'Finance' ||
            news.category == 'FINANCE' ||
            news.category == 'finance' ||
            news.category == 'Finanace' ||
            news.category == 'Financial';

        return mainCategoryMatch || exactCategoriesMatch;
      }).toList();

      print(
        '🟢 [NewsProvider] Exact Finance filter found ${_filteredNews.length} articles',
      );
    } else if (category == 'Unread') {
      _filteredNews = List.from(_allNews);
    } else {
      final dbCategory = _mapCategoryToDbFormat(category);
      _filteredNews = _allNews.where((news) {
        final mainCategoryMatch =
            news.category.toLowerCase() == dbCategory.toLowerCase();
        final categoriesMatch = news.categories.any(
          (cat) =>
              cat.toLowerCase() == dbCategory.toLowerCase() ||
              cat.toLowerCase().contains(dbCategory.toLowerCase()),
        );
        return mainCategoryMatch || categoriesMatch;
      }).toList();
    }

    notifyListeners();
  }

  String _mapCategoryToDbFormat(String uiCategory) {
    switch (uiCategory.toLowerCase()) {
      case 'finance':
        return 'Finance';
      case 'good news':
        return 'Good_News';
      case 'top stories':
        return 'Top_Stories';
      case 'videos':
        return 'Videos';
      case 'timeline':
        return 'Timeline';
      default:
        return uiCategory;
    }
  }

Future<int> silentRefresh() async {
  try {
    print('🟢 [NewsProvider] Performing silent refresh...');
    
    String? rpcCategoryFilter;
    final response = await SupabaseService().client
        .rpc(
          'get_translated_news_with_notified',
          params: {
            'target_language': _currentLanguage,
            'limit_count': 100,
            'category_filter': rpcCategoryFilter,
          },
        )
        .select();

    final List<News> newNews = response.map<News>((item) => News.fromJson(item)).toList();
    
    // Check if there are actually new articles
    final Set<String> currentIds = _allNews.map((news) => news.id).toSet();
    final List<News> actuallyNewNews = newNews.where((news) => !currentIds.contains(news.id)).toList();
    
    if (actuallyNewNews.isNotEmpty) {
      print('🟢 [NewsProvider] Found ${actuallyNewNews.length} new articles, updating list');
      
      // Add new news to the beginning while preserving existing ones
      _allNews = [...actuallyNewNews, ..._allNews];
      _filterNewsByCategory(_selectedCategory);
      
      // Only notify if there are actual changes
      notifyListeners();
      return actuallyNewNews.length;
    } else {
      print('🟢 [NewsProvider] No new articles found');
      return 0;
    }
  } catch (e) {
    print('🔴 [NewsProvider] Error in silent refresh: $e');
    return 0;
  }
}

Future<void> refreshNews() async {
  try {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    await silentRefresh();
    
    setState(() {
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _isLoading = false;
      _hasError = true;
    });
  }
}
  void setState(void Function() fn) {
    fn();
    notifyListeners();
  }
}
