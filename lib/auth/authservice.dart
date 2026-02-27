import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
      } else if (provider == 'apple') {
        signInMethod = 'apple';
      }
    }

   
    if (signInMethod == 'email') {
      if (user.userMetadata?['avatar_url'] != null ||
          user.userMetadata?['full_name'] != null) {
        signInMethod = 'google';
      }
    
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
static Future<bool> deleteAccount() async {
  try {
    print('Starting account deletion process...');
    
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('No user logged in');
      return false;
    }
    
    final userId = user.id;
    print('Deleting account for user ID: $userId');
    
    // Load environment variables
    await dotenv.load();
    
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final serviceRoleKey = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'];
    
    if (supabaseUrl == null || serviceRoleKey == null) {
      print('Missing Supabase configuration in .env file');
      return false;
    }
    
    // Create admin client with service role key
    final adminClient = SupabaseClient(
      supabaseUrl,
      serviceRoleKey,
    );
    
    // Step 1: Delete user profile
    try {
      await adminClient
          .from('user_profiles')
          .delete()
          .eq('id', userId);
      print('✅ User profile deleted from database');
    } catch (e) {
      print('⚠️ Could not delete user profile: $e');
     
    }

    await adminClient.auth.admin.deleteUser(userId);
    print('✅ Auth user deleted successfully');
    
    // Sign out current session
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print('⚠️ Error during sign out: $e');
    }
    
    // Clear shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.clear();
    
    print('✅ Account deletion completed successfully');
    return true;
  } catch (e) {
    print('❌ Error deleting account: $e');
    return false;
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
static Future<bool> signInWithApple(BuildContext context) async {
  try {
    print('Starting Apple Sign-In...');
    
    // Generate nonce like in the reference code
    final rawNonce = _supabase.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    
    // Request Apple credentials WITHOUT webAuthenticationOptions
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
      // No webAuthenticationOptions for mobile
    );

    print('Apple credentials received');

    final idToken = appleCredential.identityToken;
    if (idToken == null) {
      throw Exception('No identity token received from Apple');
    }
    
    // Sign in with Supabase using the raw nonce
    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );

    if (response.session != null && response.user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      final user = response.user!;
      
      // Get full name from Apple credential
      String? fullName;
      if (appleCredential.givenName != null && appleCredential.familyName != null) {
        fullName = '${appleCredential.givenName} ${appleCredential.familyName}'.trim();
      }

      // Create username from email or full name
      String username = '';
      if (fullName != null && fullName.isNotEmpty) {
        username = fullName.length > 20 ? fullName.substring(0, 20) : fullName;
      } else {
        username = user.email?.split('@').first ?? 'User';
        username = username.length > 20 ? username.substring(0, 20) : username;
      }

      // Check if user profile exists in 'user_profiles' table
      final profileExists = await _supabase
          .from('user_profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      final isNewUser = profileExists == null;

      // Insert or update user profile data (matching your table structure)
      if (isNewUser) {
        await _supabase.from('user_profiles').insert({
          'id': user.id,
          'username': username,
          'email': user.email,
          'bio': null,
          'role': 'user',
          'updated_at': DateTime.now().toIso8601String(),
        });
        print('✅ New user profile created: ${user.id}');
      } else {
        await _supabase
            .from('user_profiles')
            .update({
              'username': username,
              'email': user.email,
              'role': 'user',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', user.id);
        print('✅ User profile updated: ${user.id}');
      }

      print("✅ Apple sign-in success: ${user.email}");
      return true;
    } else {
      throw Exception('Apple sign-in failed - no session or user returned');
    }
  } catch (e) {
    print("❌ Apple Sign-in Error: $e");

    // More detailed error logging
    if (e is PlatformException) {
      print("Code: ${e.code}");
      print("Message: ${e.message}");
      print("Details: ${e.details}");
    } else if (e is AuthException) {
      print("Message: ${e.message}");
      print("Status Code: ${e.statusCode}");
    } else if (e is PostgrestException) {
      print("Postgrest Error: ${e.message}");
      print("Details: ${e.details}");
    }

   
    if (context.mounted) {
      String errorMessage = 'Apple Sign-in failed';
      
      if (e is AuthException) {
        errorMessage = 'Authentication error: ${e.message}';
      } else if (e is PlatformException) {
        errorMessage = 'Apple Sign-in error: ${e.message ?? e.code}';
      } else if (e is PostgrestException) {
        errorMessage = 'Database error: ${e.message}';
      } else {
        errorMessage = 'Apple Sign-in failed: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
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