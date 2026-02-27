import 'package:animations/animations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _visible = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();

    // Show the logo with a fade-in effect
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _visible = true;
      });
    });
  }

  Future<void> _initializeApp() async {
    if (_isInitialized) return;
    
    // Wait for splash screen duration
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    _isInitialized = true;

    // Check if onboarding is completed
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('language_onboarding_completed') ?? false;

    // Navigate based on onboarding status
    if (onboardingCompleted) {
      // If onboarding is already completed, request notification permission
      await _requestNotificationPermission();
      if (!mounted) return;
      context.go('/home');
    } else {
      // Option 1: Navigate to home anyway (skip onboarding)
      await _requestNotificationPermission();
      if (!mounted) return;
      context.go('/home');
      
      // Option 2: If you want to show something else, uncomment one of these:
      // context.go('/some-other-screen');
      // OR
      // Show an error or stay on splash (not recommended)
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      final settings = await notificationService.getNotificationSettings();
      
      print('🔔 [SplashScreen] Current permission status: ${settings.authorizationStatus}');
      
      // If permission is not determined or denied, request it
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined ||
          settings.authorizationStatus == AuthorizationStatus.denied) {
        print('🔔 [SplashScreen] Requesting notification permission...');
        await notificationService.setupNotifications();
      }
    } catch (e) {
      print('❌ [SplashScreen] Error requesting notification permission: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: PageTransitionSwitcher(
          duration: const Duration(seconds: 2),
          transitionBuilder: (
            Widget child,
            Animation<double> primaryAnimation,
            Animation<double> secondaryAnimation,
          ) {
            return FadeScaleTransition(
              animation: primaryAnimation,
              child: child,
            );
          },
          child: _visible
              ? Padding(
                  padding: EdgeInsets.only(left: screenWidth * 0.1),
                  child: SizedBox(
                    key: const ValueKey('logo'),
                    width: screenWidth * 0.8,
                    height: screenHeight * 0.5,
                    child: Image.asset(
                      'assets/brefnews.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}