import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService extends ChangeNotifier {
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
       await setupNotifications(); 
      }
    }
    
    print('🔔 Notification service initialized');
  }

 // In NotificationService - change from private to public
Future<void> setupNotifications() async {  // Remove the underscore
  try {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,   
      badge: true, 
      sound: true, 
    );
    
    print('🔔 Notification permission: ${settings.authorizationStatus}');
    
    if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ Provisional permissions - requesting full permissions...');
      await _requestFullPermissions();
    }

    await _handleToken();
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
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
      final prefs = await SharedPreferences.getInstance();
      final lastSavedToken = prefs.getString(_lastSavedTokenKey);
      
      if (lastSavedToken == token) {
        print('🔄 Token unchanged, skipping save');
        return;
      }
      await _saveTokenToSupabase(token);
      await prefs.setString(_lastSavedTokenKey, token);
      
    } catch (e) {
      print('❌ Error handling token: $e');
    }
  }

  Future<void> _saveTokenToSupabase(String token) async {
  try {
    print('💾 Saving FCM token to Supabase...');
    await _supabase.from('users_tokens').insert({
      'fcm_token': token,
      'platform': await _getPlatform(),
      'created_at': DateTime.now().toIso8601String(),
    });

    print('✅ Token saved successfully!');
    
  } catch (e) {
    if (e.toString().contains('duplicate key') || e.toString().contains('23505')) {
      print('🔄 Token already exists in database');
    } else {
      print('❌ Error saving token to Supabase: $e');
    }
  }
}
  Future<void> enableNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, true);
    await  setupNotifications(); ();
    print('🔔 Notifications enabled');
  }

  Future<void> disableNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, false);
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _deleteTokenFromSupabase(token);
    }
    await prefs.remove(_lastSavedTokenKey);
    
    print('🔔 Notifications disabled');
  }

  Future<void> _deleteTokenFromSupabase(String token) async {
  try {
    await _supabase
        .from('users_tokens')
        .delete()
        .eq('fcm_token', token);
        
    print('🗑️ Token deleted from Supabase');
  } catch (e) {
    print('⚠️ Token deletion completed (may not exist): $e');
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
    
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print('📱 App opened from notification: ${message.notification?.title}');
    print('📱 Message data: ${message.data}');
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
   await setupNotifications();
    
    print('🔄 Notification permissions reset and requested again');
  }
}