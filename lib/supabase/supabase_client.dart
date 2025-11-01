import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getNews() async {
    try {
      final response = await client
          .from('news_articles')
          .select('*')
          .order('published_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch news: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getNewsStream() {
    return client
        .from('news_articles')
        .stream(primaryKey: ['id'])
        .order('published_at', ascending: false)
        .map((list) => List<Map<String, dynamic>>.from(list));
  }

  Future<List<Map<String, dynamic>>> getNewsByCategory(String category) async {
    try {
      final response = await client
          .from('news_articles')
          .select('*')
          .contains('categories', [category])
          .order('published_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch news by category: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTopics({String? language}) async {
    try {
      final query = client.from('topics').select('*').eq('is_active', true);
      final response = await query;
      
      final targetLanguage = language ?? 'en';
      
      if (targetLanguage != 'en') {
        final translatedTopics = response.map((topic) {
          final originalName = topic['name'] as String;
          var finalName = originalName;
          
          try {
            final translations = topic['translations'] as Map<String, dynamic>?;
            
            if (translations != null && translations.containsKey(targetLanguage)) {
              final translatedName = translations[targetLanguage];
              
              if (translatedName is String) {
                finalName = translatedName;
              }
            }
          } catch (e) {
            // Silent fail - use original name
          }
          
          return {
            ...topic,
            'name': finalName,
            'original_name': originalName,
          };
        }).toList();
        
        return translatedTopics;
      }
      
      return response.map((topic) => {
        ...topic,
        'original_name': topic['name'],
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getNewsByTopic(String topic) async {
    try {
      final response = await client
          .from('news_articles')
          .select('*')
          .ilike('topics', '%$topic%') 
          .order('published_at', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch news by topic: $e');
    }
  }

  Future<void> saveTopicPreference(String topicName, String preference) async {
    try {
      final user = client.auth.currentUser;
      
      if (preference.isEmpty) {
        if (user != null) {
          await client
              .from('user_topic_preferences')
              .delete()
              .eq('user_id', user.id)
              .eq('topic_name', topicName);
        }
      } else {
        final data = {
          'topic_name': topicName,
          'preference': preference,
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        if (user != null) {
          data['user_id'] = user.id;
        }
        
        await client.from('user_topic_preferences').upsert(data);
      }
    } catch (e) {
      throw Exception('Failed to save topic preference: $e');
    }
  }

  Future<Map<String, String>> getUserTopicPreferences() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        return {};
      }

      final response = await client
          .from('user_topic_preferences')
          .select('topic_name, preference')
          .eq('user_id', user.id);

      final preferences = <String, String>{};
      for (final item in response) {
        preferences[item['topic_name'] as String] = item['preference'] as String;
      }

      return preferences;
    } on AuthException {
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<String?> getTopicPreference(String topicName) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        return null;
      }

      final response = await client
          .from('user_topic_preferences')
          .select('preference')
          .eq('user_id', user.id)
          .eq('topic_name', topicName)
          .maybeSingle();

      return response?['preference'] as String?;
    } catch (e) {
      return null;
    }
  }

  bool get isAuthenticated {
    return client.auth.currentUser != null;
  }

  String? get currentUserId {
    return client.auth.currentUser?.id;
  }
}