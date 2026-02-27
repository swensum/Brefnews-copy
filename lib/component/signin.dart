import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../language/app_localizations.dart';
import '../provider/auth_provider.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
   bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  final bool _isEmailLoading = false;
  Future<void> _showGoogleSuccessDialog() async {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final overlayState = Overlay.of(context);
    final localizations = AppLocalizations.of(context)!;

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: screenHeight * 0.18,
        left: screenWidth * 0.3,
        right: screenWidth * 0.3,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.002,
              vertical: screenWidth * 0.02,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              localizations.googleSignInSuccess,
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.038,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    try {
      overlayState.insert(overlayEntry);

      await Future.delayed(Duration(milliseconds: 1500));

      overlayEntry.remove();
      if (!mounted) return;

      if (context.mounted) {
        context.go('/profile');
      }
    } catch (e) {
      overlayEntry.remove();
      if (context.mounted) {
        context.go('/profile');
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final localizations = AppLocalizations.of(context)!;
    if (_isGoogleLoading) return;

    setState(() {
      _isGoogleLoading= true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signInWithGoogle(context);

      if (context.mounted) {
        setState(() {
          _isGoogleLoading = false;
        });

        if (success) {
          _showGoogleSuccessDialog();
        }
      }
    } catch (e) {
      if (context.mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.signInFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
Future<void> _handleAppleSignIn() async {
  if (_isAppleLoading) return;

  setState(() {
    _isAppleLoading = true;
  });

  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithApple(context);

    if (context.mounted) {
      setState(() {
        _isAppleLoading = false;
      });

      if (success) {
        _showAppleSuccessDialog(); 
      }
    }
  } catch (e) {
    if (context.mounted) {
      setState(() {
       _isAppleLoading = false;
      });
      if (!mounted) return;
      final localizations = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.signInFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
Future<void> _showAppleSuccessDialog() async {
  final localizations = AppLocalizations.of(context)!;
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  final overlayState = Overlay.of(context);

  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      bottom: screenHeight * 0.18,
      left: screenWidth * 0.3,
      right: screenWidth * 0.3,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.002,
            vertical: screenWidth * 0.02,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            localizations.signedInWithApple,
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.038,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );

  try {
    overlayState.insert(overlayEntry);

    await Future.delayed(Duration(milliseconds: 1500));

    overlayEntry.remove();
    if (!mounted) return;

    if (context.mounted) {
      context.go('/profile');
    }
  } catch (e) {
    overlayEntry.remove();
    if (context.mounted) {
      context.go('/profile');
    }
  }
}
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
            size: screenWidth * 0.06,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.01),
        child: Column(
          children: [
            // App Logo
            Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.08),
              child: Center(
                child: ClipOval(
                  child: Image.asset(
                    'assets/brefnews.png',
                    color: Theme.of(context).colorScheme.onSurface,
                    width: screenWidth * 0.62,
                    height: screenWidth * 0.62,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.04),

            // Google Sign In Container
            GestureDetector(
              onTap: _handleGoogleSignIn,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.01,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: screenWidth * 0.003,
                  ),
                ),
                child: Row(
                  children: [
                    // Google Logo with loading indicator
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.02),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child:_isGoogleLoading
                          ? SizedBox(
                              width: screenWidth * 0.06,
                              height: screenWidth * 0.06,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.grey),
                              ),
                            )
                          : Image.network(
                              'https://developers.google.com/identity/images/g-logo.png',
                              width: screenWidth * 0.06,
                              height: screenWidth * 0.06,
                              fit: BoxFit.contain,
                            ),
                    ),
                    SizedBox(width: screenWidth * 0.04),
                    // Text with loading state
                   _isGoogleLoading
                        ? Expanded(
                            child: Text(
                              localizations.signingIn,
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                        : Expanded(
                            child: Text(
                              localizations.signInWithGoogle,
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                    // Optional: Add a disabled state visual indicator
                    if (_isGoogleLoading)
                      SizedBox(
                        width: screenWidth * 0.06,
                        height: screenWidth * 0.06,
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.02),

if (defaultTargetPlatform == TargetPlatform.iOS)
  GestureDetector(
    onTap: _isAppleLoading
    ? null
    : () {
        _handleAppleSignIn(); 
      },
    child: Opacity(
      opacity: _isAppleLoading ? 0.5 : 1.0,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.01,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white 
              : Colors.black, 
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
        ),
        child: Row(
          children: [
            // Apple Icon
            Container(
              padding: EdgeInsets.all(screenWidth * 0.02),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                shape: BoxShape.circle,
              ),
              child: _isAppleLoading
                  ? SizedBox(
                      width: screenWidth * 0.06,
                      height: screenWidth * 0.06,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.apple,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white,
                      size: screenWidth * 0.06,
                    ),
            
            ),
            SizedBox(width: screenWidth * 0.04),
            _isAppleLoading
                ? Expanded(
                    child: Text(
                      localizations.signingIn,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                  )
                : Expanded(
                    child: Text(
                     localizations.signInWithApple,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    ),
  ),

            if (defaultTargetPlatform == TargetPlatform.iOS)
              SizedBox(height: screenHeight * 0.02),

            // Email Sign In Container
            GestureDetector(
              onTap: _isEmailLoading
                  ? null
                  : () {
                      context.push('/email-signin');
                    },
              child: Opacity(
                opacity: _isEmailLoading? 0.5 : 1.0,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: screenWidth * 0.003,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Email Icon
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.email,
                          color: Colors.blue[700],
                          size: screenWidth * 0.06,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Text(
                        localizations.signInWithEmail,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}