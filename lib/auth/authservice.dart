import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

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

  static Future<bool> isSignedIn() async {
    try {
      final user = _supabase.auth.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final isLoggedInPref = prefs.getBool('isLoggedIn') ?? false;

      return user != null && isLoggedInPref;
    } catch (e) {
      print('Error checking sign-in status: $e');
      return false;
    }
  }

 static Future<Map<String, dynamic>?> getCurrentUser() async {
  try {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    String signInMethod = 'email'; 

    final appMetadata = user.appMetadata;
    if (appMetadata.containsKey('provider')) {
      final provider = appMetadata['provider'];
      if (provider == 'google') {
        signInMethod = 'google';
      }
    }

    if (user.userMetadata?['avatar_url'] != null ||
        user.userMetadata?['full_name'] != null) {
      signInMethod = 'google';
    }

    return {
      'id': user.id,
      'email': user.email,
      'displayName':
          user.userMetadata?['full_name'] ??
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
        clientId: Platform.isIOS
            ? iosClientId
            : (Platform.isAndroid ? androidClientId : null),
        serverClientId: webClientId,
      );

      await googleSignIn.signOut();

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
        try {
          final profileExists = await _supabase
              .from('user_profiles')
              .select('id')
              .eq('id', user.id)
              .maybeSingle();

          if (profileExists == null) {
            await _supabase.from('user_profiles').insert({
              'id': user.id,
              'username':
                  user.userMetadata?['full_name'] ??
                  googleUser.displayName ??
                  'User',
              'bio': null,
              'role': 'user',
              'updated_at': DateTime.now().toIso8601String(),
            });
            print(
              "✅ User profile created with role 'user' for Google user: ${user.id}",
            );
          } else {
            await _supabase
                .from('user_profiles')
                .update({
                  'role': 'user',
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', user.id);
            print("✅ User role updated to 'user' for Google user: ${user.id}");
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
            content: Text(errorMessage, style: TextStyle(color: Colors.white)),
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

  static Future<void> signInWithEmail({
    required String email,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    try {
      print('Attempting to send OTP to email: $email');

      await _supabase.auth.signInWithOtp(email: email);

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

        try {
          final profileExists = await _supabase
              .from('user_profiles')
              .select('id')
              .eq('id', user.id)
              .maybeSingle();

          if (profileExists == null) {
            await _supabase.from('user_profiles').insert({
              'id': user.id,
              'username': email.split('@').first,
              'bio': null,
              'role': 'user',
              'updated_at': DateTime.now().toIso8601String(),
            });
            print(
              "✅ User profile created with role 'user' for email user: ${user.id}",
            );
          } else {
            await _supabase
                .from('user_profiles')
                .update({
                  'role': 'user',
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', user.id);
            print("✅ User role updated to 'user' for email user: ${user.id}");
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