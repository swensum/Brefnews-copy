import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_model.dart';
import '../supabase/supabase_client.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NewsProvider with ChangeNotifier {
  final List<News> _bookmarkedNews = [];
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

  List<String> _bookmarkedNewsIds = [];
  // Language support
  String _currentLanguage = 'en';
  String get currentLanguage => _currentLanguage;
  
  List<News> get notifiedNews {
    return _allNews.where((news) => news.notified == true).toList();
  }
  List<News> get bookmarkedNews {
  // Filter allNews to get bookmarked articles with current language
  return _allNews.where((news) => _bookmarkedNewsIds.contains(news.id)).toList();
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
    'goodNews'
  ];

  // Get localized categories - add this method
  List<String> get categories {
  // Combine static categories with dynamic categories
  List<String> allCategories = [];
  
  // Add static categories (always show these)
  allCategories.addAll(_staticCategoryKeys.map((key) {
    switch (key) {
      case 'myFeed': return 'My Feed';
      case 'finance': return 'Finance';
      case 'timeline': return 'Timeline';
      case 'videos': return 'Videos';
      case 'goodNews': return 'Good News';
      default: return key;
    }
  }));
  allCategories.addAll(_dynamicCategories);
  
 
  return allCategories.toSet().toList();
}

  final List<String> _searchCategories = [
    'My Feed',
    'Top Stories', 
    'Trending',
    'Bookmarks',
    'Unread'
  ];
  
  List<String> get searchCategories => _searchCategories;

  NewsProvider() {
    _initializeApp();
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
    notifyListeners();
  }

  Future<void> _loadCurrentLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString(_currentLanguageKey) ?? 'en';
      print('🟢 [NewsProvider] Loaded language preference: $_currentLanguage');
    } catch (e) {
      if (kDebugMode) print('Error loading language: $e');
      _currentLanguage = 'en';
    }
  }

  Future<void> _saveCurrentLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentLanguageKey, _currentLanguage);
      print('💾 [NewsProvider] Saved language preference: $_currentLanguage');
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

    print('🟢 [NewsProvider] RPC Category Filter: $rpcCategoryFilter (always loading all articles)');

    final response = await SupabaseService().client.rpc(
      'get_translated_news_with_notified',
      params: {
        'target_language': _currentLanguage,
        'limit_count': 50,
        'category_filter': rpcCategoryFilter, // This is now always null
      },
    ).select();

    _allNews = response.map<News>((item) => News.fromJson(item)).toList();
    _filterNewsByCategory(_selectedCategory); // Filter locally
    
    print('🟢 [NewsProvider] Loaded ${_allNews.length} articles in $_currentLanguage');
    print('🟢 [NewsProvider] Filtered to ${_filteredNews.length} articles for: $_selectedCategory');
    
    setState(() { _isLoading = false; });
  } catch (e) {
    print('🔴 [NewsProvider] Failed to load news: $e');
    setState(() { 
      _isLoading = false; 
      _hasError = true; 
    });
  }
}

  Future<void> fetchNewsByTopic(String topic) async {
    try {
      _isLoadingTopicNews = true;
      notifyListeners();

      final response = await SupabaseService().client.rpc(
        'get_translated_news',
        params: {
          'target_language': _currentLanguage,
          'limit_count': 50,
          'category_filter': topic,
        },
      ).select();

      _topicNews = response.map<News>((data) => News.fromJson(data)).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching topic news: $e');
      try {
        final newsData = await SupabaseService().getNewsByTopic(topic);
        _topicNews = newsData.map((data) => News.fromJson(data)).toList();
      } catch (e) {
        if (kDebugMode) print('Fallback failed: $e');
        _topicNews = [];
      }
    } finally {
      _isLoadingTopicNews = false;
      notifyListeners();
    }
  }

  // ========== EXISTING METHODS ==========

  void addDynamicCategory(String category) {
  if (!_dynamicCategories.contains(category) && !_staticCategoryKeys.contains(category)) {
    _dynamicCategories.add(category);
    _saveDynamicCategories();
    notifyListeners();
    
    print('🟢 [NewsProvider] Added dynamic category: $category');
  } else {
    print('ℹ️ [NewsProvider] Category already exists: $category');
  }
}
 bool get hasBookmarks => _bookmarkedNewsIds.isNotEmpty; 

 Future<void> _loadDynamicCategories() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = prefs.getStringList(_dynamicCategoriesKey);
    if (categoriesJson != null) {
      _dynamicCategories = categoriesJson;
      print('🟢 [NewsProvider] Loaded dynamic categories: $_dynamicCategories');
      notifyListeners();
    }
  } catch (e) {
    if (kDebugMode) print('Error loading categories: $e');
  }
}

  Future<void> fetchTopics() async {
    try {
      final topicsData = await SupabaseService().getTopics();
      _topics = topicsData;
      notifyListeners();
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
        final datesMap = Map<String, dynamic>.from(json.decode(bookmarkDatesJson));
        datesMap.forEach((newsId, timestamp) {
          if (timestamp is int) {
            _bookmarkDates[newsId] = DateTime.fromMillisecondsSinceEpoch(timestamp);
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
  
  if (_bookmarkedNewsIds.isEmpty && _dynamicCategories.contains('Bookmarks')) {
    _dynamicCategories.remove('Bookmarks');
    _saveDynamicCategories();
  }
  
  _saveBookmarksToSharedPreferences();
  notifyListeners();
}
bool isBookmarked(News news) {
  return _bookmarkedNewsIds.contains(news.id);
}


  DateTime getBookmarkDate(News news) => _bookmarkDates[news.id] ?? DateTime.now();
  
  void removeBookmark(News news) {
  // Change this:
  _bookmarkedNews.removeWhere((item) => item.id == news.id);
  // To this:
  _bookmarkedNewsIds.remove(news.id);
  
  _bookmarkDates.remove(news.id);
  if (_bookmarkedNewsIds.isEmpty && _dynamicCategories.contains('Bookmarks')) { // Also update this condition
    _dynamicCategories.remove('Bookmarks');
    _saveDynamicCategories();
  }
  _saveBookmarksToSharedPreferences(); 
  notifyListeners();
}

 void setCategory(String category) {
  print('🟢 [NewsProvider] Setting category from: $_selectedCategory to: $category');
  _selectedCategory = category;
  
  // Immediately filter the existing news
  _filterNewsByCategory(category);
  
  // // For certain categories, reload from server
  // if (category == 'Top Stories' || category == 'Trending' || category == 'Unread') {
  //   print('🟢 [NewsProvider] Reloading news for special category: $category');
  //   loadNews();
  // }
  
  notifyListeners();
}
  void _filterNewsByCategory(String category) {
  if (category == 'My Feed') {
    _filteredNews = List.from(_allNews);
  } else if (category == 'Bookmarks') {
    _filteredNews = List.from(bookmarkedNews);
  } else if (category == 'Trending') {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    _filteredNews = _allNews.where((news) => news.publishedAt.isAfter(yesterday)).toList();
  } else if (category == 'Top Stories') {
    // Add specific logic for Top Stories
    _filteredNews = _allNews.where((news) {
      final hasTopStories = news.categories.any((cat) => 
          cat.toLowerCase().contains('top') || 
          cat.toLowerCase().contains('stories') ||
          cat.toLowerCase() == 'top_stories');
      
      return hasTopStories;
    }).toList();
  } else if (category == 'Good News') {
    // ADD THIS: Specific logic for Good News
    _filteredNews = _allNews.where((news) {
      final hasGoodNews = news.categories.any((cat) => 
          cat.toLowerCase().contains('good') || 
          cat.toLowerCase().contains('news') ||
          cat.toLowerCase() == 'good_news' ||
          cat.toLowerCase() == 'good news');
      return hasGoodNews;
    }).toList();
  } else if (category == 'Unread') {
    _filteredNews = List.from(_allNews); 
  } else {
    _filteredNews = _allNews.where((news) {
      final dbCategory = _mapCategoryToDbFormat(category);
      return news.categories.any((cat) => cat.toLowerCase() == dbCategory.toLowerCase());
    }).toList();
  }
  
  print('🟢 [NewsProvider] Filtered ${_filteredNews.length} articles for: $category');
  notifyListeners();
}

  String _mapCategoryToDbFormat(String uiCategory) {
    switch (uiCategory.toLowerCase()) {
      case 'finance': return 'Finanace'; 
      case 'good news': return 'Good_News';
      case 'top stories': return 'Top_Stories';
      case 'videos': return 'Videos';
      case 'timeline': return 'Timeline';
      default: return uiCategory;
    }
  }

  void refreshNews() => loadNews();
  void setState(void Function() fn) { fn(); notifyListeners(); }
}