import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _lastSavedTokenKey = 'last_saved_token';

  Future<void> init() async {
    print('🔔 Initializing Notification Service...');
    
    final prefs = await SharedPreferences.getInstance();
    final bool isFirstTime = prefs.getBool(_notificationsEnabledKey) == null;
    
    if (isFirstTime) {
      print('🔔 First time app launch - enabling notifications by default');
      await enableNotifications();
    } else {
      final enabled = await areNotificationsEnabled();
      if (enabled) {
        await _setupNotifications();
      }
    }
    
    print('🔔 Notification service initialized');
  }

  Future<void> _setupNotifications() async {
    try {
      // REMOVE provisional: true to get immediate banner notifications
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,    // Enables banners and alerts
        badge: true,    // Enables badge numbers
        sound: true,    // Enables sound
        // provisional: true, // REMOVED - this sends to notification center silently
      );
      
      print('🔔 Notification permission: ${settings.authorizationStatus}');
      
      // Debug what permissions we actually got
      print('🔔 Alert permission: ${settings.alert}');
      print('🔔 Badge permission: ${settings.badge}');
      print('🔔 Sound permission: ${settings.sound}');
      
      // If we have provisional, request full permissions
      if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ Provisional permissions - requesting full permissions...');
        await _requestFullPermissions();
      }

      // Get FCM token and handle it
      await _handleToken();

      // Setup message handlers
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
      
      // Token refresh - only save if different
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔄 Token refreshed: $newToken');
        _handleToken(newToken: newToken);
      });
    } catch (e) {
      print('❌ Error setting up notifications: $e');
    }
  }

  Future<void> _requestFullPermissions() async {
    try {
      print('🔄 Requesting full notification permissions...');
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        // No provisional parameter
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('🎉 Full permissions granted! Notifications will show as banners');
      } else {
        print('⚠️ Still not full permissions: ${settings.authorizationStatus}');
      }
    } catch (e) {
      print('❌ Error requesting full permissions: $e');
    }
  }

  Future<void> _handleToken({String? newToken}) async {
    try {
      final token = newToken ?? await _firebaseMessaging.getToken();
      if (token == null) {
        print('🔔 No FCM token available');
        return;
      }

      print('🔔 FCM Token: $token');

      // Check if token is same as last saved one
      final prefs = await SharedPreferences.getInstance();
      final lastSavedToken = prefs.getString(_lastSavedTokenKey);
      
      if (lastSavedToken == token) {
        print('🔄 Token unchanged, skipping save');
        return;
      }

      // Save token to Supabase using UPSERT approach
      await _saveTokenToSupabase(token);
      
      // Update last saved token
      await prefs.setString(_lastSavedTokenKey, token);
      
    } catch (e) {
      print('❌ Error handling token: $e');
    }
  }

  Future<void> _saveTokenToSupabase(String token) async {
  try {
    print('💾 Saving FCM token to Supabase...');

    // Simple upsert - only need fcm_token
    final response = await _supabase.from('users_tokens').upsert({
      'fcm_token': token,
      'platform': await _getPlatform(),
      'created_at': DateTime.now().toIso8601String(),
    }, onConflict: 'fcm_token');

    if (response.error != null) {
      print('❌ Database error: ${response.error}');
    } else {
      print('✅ Token saved successfully!');
    }
  } catch (e) {
    print('❌ Error saving token to Supabase: $e');
  }
}
  Future<void> enableNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, true);
    await _setupNotifications();
    print('🔔 Notifications enabled');
  }

  Future<void> disableNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, false);
    
    // Delete current token from Supabase
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _deleteTokenFromSupabase(token);
    }
    
    // Clear last saved token
    await prefs.remove(_lastSavedTokenKey);
    
    print('🔔 Notifications disabled');
  }

  Future<void> _deleteTokenFromSupabase(String token) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('users_tokens')
          .delete()
          .eq('user_id', user.id)
          .eq('fcm_token', token);
          
      print('🗑️ Token deleted from Supabase');
    } catch (e) {
      print('❌ Error deleting token: $e');
    }
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<String> _getPlatform() async {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'web';
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('📱 Foreground message: ${message.notification?.title}');
    print('📱 Message data: ${message.data}');
    
    // TODO: Show local notification or update UI
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print('📱 App opened from notification: ${message.notification?.title}');
    print('📱 Message data: ${message.data}');
    
    // TODO: Navigate to specific article using message.data['article_id']
  }

  Future<NotificationSettings> getNotificationSettings() async {
    return await _firebaseMessaging.getNotificationSettings();
  }

  // Reset permissions and request again
  Future<void> resetAndRequestPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsEnabledKey);
    await prefs.remove(_lastSavedTokenKey);
    
    // Wait a bit and request permissions again
    await Future.delayed(Duration(seconds: 1));
    await _setupNotifications();
    
    print('🔄 Notification permissions reset and requested again');
  }
}