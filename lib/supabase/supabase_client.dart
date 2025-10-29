

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getNews() async {
    try {
      print('🟡 [SupabaseService] Fetching news from news_articles table...');
      
      final response = await client
          .from('news_articles')
          .select('*')
          .order('published_at', ascending: false);

      print('🟢 [SupabaseService] Successfully fetched ${response.length} news articles');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('🔴 [SupabaseService] Failed to fetch news: $e');
      throw Exception('Failed to fetch news: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getNewsStream() {
    print('🟡 [SupabaseService] Setting up news stream...');
    return client
        .from('news_articles')
        .stream(primaryKey: ['id'])
        .order('published_at', ascending: false)
        .map((list) => List<Map<String, dynamic>>.from(list));
  }

  Future<List<Map<String, dynamic>>> getNewsByCategory(String category) async {
    try {
      print('🟡 [SupabaseService] Fetching news for category: $category');
      
      final response = await client
          .from('news_articles')
          .select('*')
          .contains('categories', [category])
          .order('published_at', ascending: false);

      print('🟢 [SupabaseService] Found ${response.length} articles for category: $category');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('🔴 [SupabaseService] Failed to fetch news by category $category: $e');
      throw Exception('Failed to fetch news by category: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTopics() async {
    try {
      print('🟡 [SupabaseService] Fetching active topics...');
      
      final response = await client
          .from('topics')
          .select('*')
          .eq('is_active', true)
          .order('name', ascending: true);

      print('🟢 [SupabaseService] Successfully fetched ${response.length} topics');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('🔴 [SupabaseService] Failed to fetch topics: $e');
      throw Exception('Failed to fetch topics: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNewsByTopic(String topic) async {
    try {
      print('🟡 [SupabaseService] Fetching news for topic: $topic');
      
      final response = await client
          .from('news_articles')
          .select('*')
          .ilike('topics', '%$topic%') 
          .order('published_at', ascending: false)
          .limit(10);

      print('🟢 [SupabaseService] Found ${response.length} articles for topic: $topic');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('🔴 [SupabaseService] Failed to fetch news by topic $topic: $e');
      throw Exception('Failed to fetch news by topic: $e');
    }
  }

  Future<void> saveTopicPreference(String topicName, String preference) async {
    try {
      print('🟡 [SupabaseService] Saving topic preference - Topic: $topicName, Preference: $preference');
      
      final user = client.auth.currentUser;
      
      if (preference.isEmpty) {
        print('🟡 [SupabaseService] Removing preference for topic: $topicName');
        
        if (user != null) {
          await client
              .from('user_topic_preferences')
              .delete()
              .eq('user_id', user.id)
              .eq('topic_name', topicName);
          print('🟢 [SupabaseService] Successfully removed preference for authenticated user');
        } else {
          print('🟡 [SupabaseService] Guest user - preference removed locally for: $topicName');
        }
      } else {
        print('🟡 [SupabaseService] Upserting preference for topic: $topicName');
        
        final data = {
          'topic_name': topicName,
          'preference': preference,
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        if (user != null) {
          data['user_id'] = user.id;
          print('🟡 [SupabaseService] User authenticated, including user_id: ${user.id}');
        } else {
          print('🟡 [SupabaseService] User not authenticated, saving without user_id');
        }
        
        await client
            .from('user_topic_preferences')
            .upsert(data);
        
        print('🟢 [SupabaseService] Successfully saved topic preference');
      }
    } catch (e) {
      print('🔴 [SupabaseService] Failed to save topic preference: $e');
      throw Exception('Failed to save topic preference: $e');
    }
  }

  Future<Map<String, String>> getUserTopicPreferences() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        print('🟡 [SupabaseService] No authenticated user found for preferences');
        return {};
      }

      print('🟡 [SupabaseService] Fetching preferences for user: ${user.id}');

      final response = await client
          .from('user_topic_preferences')
          .select('topic_name, preference')
          .eq('user_id', user.id);

      final preferences = <String, String>{};
      for (final item in response) {
        preferences[item['topic_name'] as String] = item['preference'] as String;
      }

      print('🟢 [SupabaseService] Found ${preferences.length} preferences for user');
      return preferences;
    } on AuthException catch (e) {
      print('🔴 [SupabaseService] Auth error fetching preferences: ${e.message}');
      return {};
    } catch (e) {
      print('🔴 [SupabaseService] Error fetching preferences: $e');
      return {};
    }
  }

  Future<String?> getTopicPreference(String topicName) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        print('🟡 [SupabaseService] No user for topic preference check');
        return null;
      }

      print('🟡 [SupabaseService] Fetching preference for topic: $topicName, user: ${user.id}');

      final response = await client
          .from('user_topic_preferences')
          .select('preference')
          .eq('user_id', user.id)
          .eq('topic_name', topicName)
          .maybeSingle();

      final preference = response?['preference'] as String?;
      print('🟢 [SupabaseService] Topic preference result: $preference');
      return preference;
    } catch (e) {
      print('🔴 [SupabaseService] Error fetching topic preference: $e');
      return null;
    }
  }

  bool get isAuthenticated {
    final isAuth = client.auth.currentUser != null;
    print('🟡 [SupabaseService] Authentication check: $isAuth');
    return isAuth;
  }

  String? get currentUserId {
    final userId = client.auth.currentUser?.id;
    print('🟡 [SupabaseService] Current user ID: $userId');
    return userId;
  }
 
}