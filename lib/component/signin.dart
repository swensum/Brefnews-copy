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
  bool _isLoading = false;

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
            color: Colors.black.withValues(alpha:  0.8),
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
    // Insert the overlay
    overlayState.insert(overlayEntry);

    // Wait for 1.5 seconds to show dialog and ensure auth state updates
    await Future.delayed(Duration(milliseconds: 1500));

    // Remove the overlay
    overlayEntry.remove();
if (!mounted) return;
    // Navigate to profile
    if (context.mounted) {
      context.go('/profile');
    }
  } catch (e) {
    // If anything fails, ensure overlay is removed and still navigate
    overlayEntry.remove();
    if (context.mounted) {
      context.go('/profile');
    }
  }
}

  Future<void> _handleGoogleSignIn() async {
    final localizations = AppLocalizations.of(context)!;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signInWithGoogle(context);

      if (context.mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          _showGoogleSuccessDialog();
        }
      }
    } catch (e) {
      if (context.mounted) {
        setState(() {
          _isLoading = false;
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
              padding:EdgeInsets.only(left: screenWidth * 0.08),
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
                      child: _isLoading
                          ? SizedBox(
                              width: screenWidth * 0.06,
                              height: screenWidth * 0.06,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
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
                    _isLoading
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
                    if (_isLoading)
                      SizedBox(
                        width: screenWidth * 0.06,
                        height: screenWidth * 0.06,
                      ),
                  ],
                ),
              ),
            ),
            // SizedBox(height: screenHeight * 0.02),

            // Phone Sign In Container
            // GestureDetector(
            //   onTap: _isLoading
            //       ? null
            //       : () {
            //           context.push('/phone-login');
            //         },
            //   child: Opacity(
            //     opacity: _isLoading ? 0.5 : 1.0,
            //     child: Container(
            //       width: double.infinity,
            //       padding: EdgeInsets.symmetric(
            //         horizontal: screenWidth * 0.04,
            //         vertical: screenHeight * 0.01,
            //       ),
            //       decoration: BoxDecoration(
            //         color: Colors.white,
            //         borderRadius: BorderRadius.circular(screenWidth * 0.03),
            //         border: Border.all(
            //           color: Colors.grey[300]!,
            //           width: screenWidth * 0.003,
            //         ),
            //       ),
            //       child: Row(
            //         children: [
            //           // Phone Icon
            //           Container(
            //             padding: EdgeInsets.all(screenWidth * 0.02),
            //             decoration: BoxDecoration(
            //               color: Colors.grey[100],
            //               shape: BoxShape.circle,
            //             ),
            //             child: Icon(
            //               Icons.phone,
            //               color: Colors.green,
            //               size: screenWidth * 0.06,
            //             ),
            //           ),
            //           SizedBox(width: screenWidth * 0.04),
            //           Text(
            //             localizations.signInWithPhone,
            //             style: TextStyle(
            //               fontSize: screenWidth * 0.04,
            //               fontWeight: FontWeight.w500,
            //               color: Colors.black87,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
            SizedBox(height: screenHeight * 0.02),

            // Email Sign In Container
            GestureDetector(
              onTap: _isLoading
                  ? null
                  : () {
                      context.push('/email-signin');
                    },
              child: Opacity(
                opacity: _isLoading ? 0.5 : 1.0,
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