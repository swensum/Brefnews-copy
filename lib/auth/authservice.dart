import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<void> signInWithPhone({
  required String phone,
  required Function(String) onCodeSent,
  required Function(String) onError,
}) async {
  try {
    final cleanedPhone = phone.replaceAll(RegExp(r'[-\s]'), '');
    
    print('📱 Production: Sending OTP to: $cleanedPhone');
    
    // Production call - will send real SMS
    await _supabase.auth.signInWithOtp(
      phone: cleanedPhone,
     
    );
    
    print('✅ OTP sent successfully to: $cleanedPhone');
    
    onCodeSent('Verification code sent to $phone');
  } on AuthException catch (e) {
    print('❌ AuthException: ${e.message}');
    
    // Handle specific production errors
    if (e.message.contains('invalid phone')) {
      onError('Please enter a valid phone number');
    } else if (e.message.contains('rate limit')) {
      onError('Too many attempts. Please try again later.');
    } else {
      onError('Authentication error: ${e.message}');
    }
  } catch (e) {
    print('❌ General error: $e');
    onError('Failed to send verification code. Please try again.');
  }
}

static Future<void> verifyOTP({
  required String phone,
  required String token,
  required Function(User) onSuccess,
  required Function(String) onError,
}) async {
  try {
    final cleanedPhone = phone.replaceAll(RegExp(r'[-\s]'), '');
    
    print('🔐 Production: Verifying OTP for: $cleanedPhone');
    
    final AuthResponse response = await _supabase.auth.verifyOTP(
      phone: cleanedPhone,
      token: token.trim(), // Trim whitespace
      type: OtpType.sms,
    );
    
    final user = response.user;
    
    if (user != null) {
      print('✅ User verified successfully: ${user.id}');
      
      // Create user profile for phone user
      await _createUserProfile(user);
      
      // Update shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('authMethod', 'phone');
      
      onSuccess(user);
    } else {
      onError('Verification failed. Please try again.');
    }
  } on AuthException catch (e) {
    print('❌ AuthException during verification: ${e.message}');
    
    // Handle specific verification errors
    if (e.message.contains('invalid')) {
      onError('Invalid verification code. Please try again.');
    } else if (e.message.contains('expired')) {
      onError('Verification code has expired. Please request a new one.');
    } else {
      onError('Verification error: ${e.message}');
    }
  } catch (e) {
    print('❌ General verification error: $e');
    onError('Failed to verify code. Please try again.');
  }
}static Future<void> _createUserProfile(User user) async {
  try {
    final profileExists = await _supabase
        .from('user_profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (profileExists == null) {
      // Generate a default username from phone
      String defaultUsername = 'User${user.phone?.substring(user.phone!.length - 4) ?? '1234'}';
      
      await _supabase.from('user_profiles').insert({
        'id': user.id,
        'username': defaultUsername,
        'phone': user.phone,
        'bio': null,
        'updated_at': DateTime.now().toIso8601String(),
      });
      print("✅ User profile created for phone user: ${user.id}");
    } else {
      print("✅ User profile already exists: ${user.id}");
    }
  } catch (e) {
    print('❌ Error creating user profile: $e');
    // Don't throw error - auth succeeded even if profile creation fails
  }
}
  // Get current user
  static User? get currentUser {
    return _supabase.auth.currentUser;
  }

  // Sign out
  static Future<bool> signOut() async {
    try {
      await _supabase.auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      return true;
    } catch (e) {
      print('Error during sign out: $e');
      return false;
    }
  }

  // Check if user is logged in
  static bool get isLoggedIn {
    return _supabase.auth.currentUser != null;
  }

  // NEW: Check if user is signed in (async version)
  static Future<bool> isSignedIn() async {
    try {
      // Check both Supabase auth and shared preferences
      final user = _supabase.auth.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final isLoggedInPref = prefs.getBool('isLoggedIn') ?? false;
      
      return user != null && isLoggedInPref;
    } catch (e) {
      print('Error checking sign-in status: $e');
      return false;
    }
  }

  // NEW: Get current user data with sign-in method
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // Determine sign-in method based on user data
      String signInMethod = 'email'; // default
      
      // Check user metadata to determine sign-in method
      final appMetadata = user.appMetadata;
      if (appMetadata.containsKey('provider')) {
        final provider = appMetadata['provider'];
        if (provider == 'google') {
          signInMethod = 'google';
        } else if (provider == 'phone') {
          signInMethod = 'phone';
        }
      }
      
      // Check if user has phone number (phone sign-in)
      if (user.phone != null && user.phone!.isNotEmpty) {
        signInMethod = 'phone';
      }
      
      // Check if user has Google-related data
      if (user.userMetadata?['avatar_url'] != null || 
          user.userMetadata?['full_name'] != null) {
        signInMethod = 'google';
      }

      return {
        'id': user.id,
        'email': user.email,
        'phone': user.phone,
        'displayName': user.userMetadata?['full_name'] ?? 
                      user.userMetadata?['name'] ?? 
                      user.email?.split('@').first ?? 
                      'User',
        'photoURL': user.userMetadata?['avatar_url'],
        'signInMethod': signInMethod,
      };
    } catch (e) {
      print('Error getting current user data: $e');
      return null;
    }
  }
static Future<bool> signInWithGoogle(BuildContext context) async {
  try {
    // Load environment variables
    await dotenv.load();
    
    final webClientId = dotenv.env['WEB_CLIENT_ID'] ?? '';
    final iosClientId = dotenv.env['IOS_CLIENT_ID'] ?? '';
    final androidClientId = dotenv.env['ANDROID_CLIENT_ID'] ?? '';

    if (webClientId.isEmpty) {
      throw Exception('WEB_CLIENT_ID is not configured in .env file');
    }

    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId: Platform.isIOS ? iosClientId : (Platform.isAndroid ? androidClientId : null),
      serverClientId: webClientId,
    );

    // 🔥 SIMPLE & SAFE: Just sign out (disconnect is not needed for account picker)
    await googleSignIn.signOut();

    // Now sign in - this will show account picker
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in aborted by user');
    }

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null || idToken == null) {
      throw Exception('Missing Google credentials');
    }

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    if (response.session != null && response.user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      final user = response.user!;
      
      // Create user profile
      try {
        final profileExists = await _supabase
            .from('user_profiles')
            .select('id')
            .eq('id', user.id)
            .maybeSingle();

        if (profileExists == null) {
          await _supabase.from('user_profiles').insert({
            'id': user.id,
            'username': user.userMetadata?['full_name'] ?? googleUser.displayName ?? 'User',
            'bio': null,
            'updated_at': DateTime.now().toIso8601String(),
          });
          print("✅ User profile created for Google user: ${user.id}");
        }
      } catch (e) {
        print('Error creating user profile: $e');
      }

      print("✅ Google sign-in success: ${user.email}");
      return true;
    } else {
      throw Exception('Supabase Google sign-in failed');
    }
  } catch (e) {
    print("❌ Google Sign-in Error: $e");
    
    if (context.mounted) {
      String errorMessage = 'Google Sign-in failed';
      
      if (e is PlatformException) {
        errorMessage = 'Google Sign-in failed: ${e.message ?? e.code}';
      } else if (e is AuthException) {
        errorMessage = 'Authentication error: ${e.message}';
      } else {
        errorMessage = 'Google Sign-in failed: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    return false;
  }
}

  // NEW: Update user profile with sign-in method (for phone/email sign-in)
  static Future<void> updateUserSignInMethod(String userId, String method) async {
    try {
      await _supabase.from('users').update({
        'sign_in_method': method,
      }).eq('id', userId);
    } catch (e) {
      print('Error updating user sign-in method: $e');
    }
  }



  // Add these methods to your AuthService class

// Sign in with email
static Future<void> signInWithEmail({
  required String email,
  required Function(String) onCodeSent,
  required Function(String) onError,
}) async {
  try {
    print('Attempting to send OTP to email: $email');
    
    await _supabase.auth.signInWithOtp(
      email: email,
    );
    
    print('OTP sent successfully to: $email');
    
    onCodeSent('Verification code sent to $email');
  } on AuthException catch (e) {
    print('AuthException: ${e.message}');
    onError('Authentication error: ${e.message}');
  } catch (e) {
    print('General error: $e');
    onError('Failed to send verification code. Please try again.');
  }
}

// Verify email OTP
static Future<void> verifyEmailOTP({
  required String email,
  required String token,
  required Function(User) onSuccess,
  required Function(String) onError,
}) async {
  try {
    print('Verifying OTP for email: $email');
    
    await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
    
    final user = _supabase.auth.currentUser;
    
    if (user != null) {
      print('User verified successfully: ${user.id}');
      
      // ✅ CREATE USER PROFILE FOR EMAIL USER
      try {
        final profileExists = await _supabase
            .from('user_profiles')
            .select('id')
            .eq('id', user.id)
            .maybeSingle();

        if (profileExists == null) {
          // Create new user profile for email user
          await _supabase.from('user_profiles').insert({
            'id': user.id,
            'username': email.split('@').first, // Use email prefix as username
            'bio': null, // Empty bio initially
            'updated_at': DateTime.now().toIso8601String(),
          });
          print("✅ User profile created for email user: ${user.id}");
        }
      } catch (e) {
        print('Error creating user profile for email user: $e');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      
      onSuccess(user);
    } else {
      onError('Verification failed. Please try again.');
    }
  } on AuthException catch (e) {
    print('AuthException during verification: ${e.message}');
    onError('Verification error: ${e.message}');
  } catch (e) {
    print('General verification error: $e');
    onError('Failed to verify code. Please try again.');
  }
}
}