import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  // Save topic preferences locally with user-specific key
  Future<void> saveTopicPreferences(Map<String, String> preferences, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = userId != null 
          ? 'topic_preferences_$userId' 
          : 'topic_preferences_guest';
      
      final preferencesJson = <String, String>{};
      
      preferences.forEach((key, value) {
        if (value.isNotEmpty) {
          preferencesJson[key] = value;
        }
      });
      
      await prefs.setString(storageKey, jsonEncode(preferencesJson));
      print('Preferences saved locally for ${userId ?? 'guest'}');
    } catch (e) {
      print('Failed to save preferences locally: $e');
    }
  }

  // Get topic preferences from local storage for specific user
  Future<Map<String, String>> getTopicPreferences({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = userId != null 
          ? 'topic_preferences_$userId' 
          : 'topic_preferences_guest';
      
      final preferencesJson = prefs.getString(storageKey);
      
      if (preferencesJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(preferencesJson);
        final Map<String, String> preferences = {};
        
        decoded.forEach((key, value) {
          preferences[key] = value.toString();
        });
        
        print('Loaded ${preferences.length} local preferences for ${userId ?? 'guest'}');
        return preferences;
      }
      
      return {};
    } catch (e) {
      print('Failed to load preferences locally: $e');
      return {};
    }
  }

  // Clear topic preferences for specific user
  Future<void> clearTopicPreferences({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = userId != null 
          ? 'topic_preferences_$userId' 
          : 'topic_preferences_guest';
      
      await prefs.remove(storageKey);
      print('Cleared local preferences for ${userId ?? 'guest'}');
    } catch (e) {
      print('Failed to clear preferences: $e');
    }
  }

  // Migrate guest preferences to user account when they sign in
  Future<void> migrateGuestPreferencesToUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guestKey = 'topic_preferences_guest';
      final userKey = 'topic_preferences_$userId';
      
      final guestPreferences = prefs.getString(guestKey);
      if (guestPreferences != null) {
        // Copy guest preferences to user
        await prefs.setString(userKey, guestPreferences);
        // Clear guest preferences
        await prefs.remove(guestKey);
        print('Migrated guest preferences to user: $userId');
      }
    } catch (e) {
      print('Failed to migrate guest preferences: $e');
    }
  }
}