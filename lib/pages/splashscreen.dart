import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../repositories/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _visible = false; // ✅ Added missing variable

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

    // Navigate to the home screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      context.go('/home');
    });
  }
 Future<void> _initializeApp() async {
    // Initialize notifications
    final notificationService = context.read<NotificationService>();
    await notificationService.init();
    
   Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
       
        context.go('/home');
      }
    });
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
