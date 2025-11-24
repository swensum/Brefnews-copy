// auth_provider.dart
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/authservice.dart';

class AuthProvider with ChangeNotifier {
  bool _isSignedIn = false;
  String? _userName;
  String? _userPhotoUrl;
  String? _userEmail;
  String? _userId;
  String? _signInMethod; 

  bool get isSignedIn => _isSignedIn;
  String? get userName => _userName;
  String? get userPhotoUrl => _userPhotoUrl;
  String? get userEmail => _userEmail;
  String? get userId => _userId;
  String? get signInMethod => _signInMethod; 

  final SupabaseClient _supabase = Supabase.instance.client;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    try {
      _isSignedIn = await AuthService.isSignedIn();
      final userData = await AuthService.getCurrentUser();
      
      if (_isSignedIn && userData != null) {
        _userName = userData['displayName'];
        _userPhotoUrl = userData['photoURL'];
        _userEmail = userData['email'];
        _userId = userData['id'];
        _signInMethod = userData['signInMethod']; 
      } else {
        _clearUserData();
      }
      notifyListeners();
    } catch (e) {
      print('Error checking auth status: $e');
      _clearUserData();
    }
  }

  Future<bool> signInWithGoogle(BuildContext context) async {
    try {
      final success = await AuthService.signInWithGoogle(context);
      if (success) {
        await checkAuthStatus();
      }
      return success;
    } catch (e) {
      print('Error in signInWithGoogle: $e');
      return false;
    }
  }


  // Email sign-in methods
  Future<void> signInWithEmail({
    required String email,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    try {
      await AuthService.signInWithEmail(
        email: email,
        onCodeSent: onCodeSent,
        onError: onError,
      );
    } catch (e) {
     onError('Failed to send verification code: ${e.toString()}');
    }
  }

  Future<void> verifyEmailOTP({
    required String email,
    required String token,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    try {
      await AuthService.verifyEmailOTP(
        email: email,
        token: token,
        onSuccess: (user) async {
          await checkAuthStatus();
          onSuccess();
        },
        onError: onError,
      );
    } catch (e) {
      onError('Verification failed');
    }
  }

  Future<bool> signOut() async {
    try {
      // First sign out from Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      
      // Then sign out from Supabase
      await _supabase.auth.signOut();
      
      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      
      await checkAuthStatus();
      return true;
    } catch (e) {
      print('Error signing out: $e');
      return false;
    }
  }

  // Get current user data directly
  Map<String, dynamic>? get currentUserData {
    if (!_isSignedIn) return null;
    
    return {
      'id': _userId,
      'email': _userEmail,
      'displayName': _userName,
      'photoURL': _userPhotoUrl,
      'signInMethod': _signInMethod, 
    };
  }

  
  void _clearUserData() {
    _isSignedIn = false;
    _userName = null;
    _userPhotoUrl = null;
    _userEmail = null;
    _userId = null;
    _signInMethod = null;
  }
}