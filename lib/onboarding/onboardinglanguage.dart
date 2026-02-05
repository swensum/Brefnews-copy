import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import '../provider/language_provider.dart';
import '../provider/news_provider.dart';
import '../repositories/notification_service.dart';

class OnboardingLanguagePage extends StatefulWidget {
  const OnboardingLanguagePage({super.key});

  @override
  State<OnboardingLanguagePage> createState() => _OnboardingLanguagePageState();
}

class _OnboardingLanguagePageState extends State<OnboardingLanguagePage> {
  String? _selectedLanguageCode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Don't set any default language
    _selectedLanguageCode = null;
  }
Future<void> _requestNotificationPermission() async {
  try {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    final settings = await notificationService.getNotificationSettings();
    
    print('🔔 [OnboardingLanguagePage] Current permission status: ${settings.authorizationStatus}');
    
    // If permission is not determined or denied, request it
    if (settings.authorizationStatus == AuthorizationStatus.notDetermined ||
        settings.authorizationStatus == AuthorizationStatus.denied) {
      print('🔔 [OnboardingLanguagePage] Requesting notification permission...');
      await notificationService.setupNotifications();
    }
  } catch (e) {
    print('❌ [OnboardingLanguagePage] Error requesting notification permission: $e');
  }
}
  Future<void> _markOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('language_onboarding_completed', true);
  }

  Future<void> _completeOnboarding() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Mark onboarding as completed
      await _markOnboardingCompleted();
        await _requestNotificationPermission();
      // Navigate to main app
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      print('Error completing onboarding: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _selectLanguage(String languageCode, String languageName) {
    setState(() {
      _selectedLanguageCode = languageCode;
    });

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);

    // No snackbar shown
    languageProvider.setLanguage(languageCode);
    newsProvider.setLanguage(languageCode);
  }

  // Get language name in its own script
  String _getLanguageInNativeScript(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिन्दी';
      case 'ur':
        return 'اردو';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'zh':
        return '中文';
      case 'ja':
        return '日本語';
      default:
        return languageCode;
    }
  }

  // Get "Continue" text in the selected language
  String _getContinueText(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'Continue';
      case 'hi':
        return 'आगे बढ़ें';
      case 'ur':
        return 'جاری رکھیں';
      case 'es':
        return 'Continuar';
      case 'fr':
        return 'Continuer';
      case 'zh':
        return '继续';
      case 'ja':
        return '続ける';
      default:
        return 'Continue';
    }
  }

  // Get English name for the language (only for non-English languages)
  String? _getEnglishLanguageName(String languageCode) {
    if (languageCode == 'en') return null; // No small text for English
    
    switch (languageCode) {
      case 'hi':
        return 'Hindi';
      case 'ur':
        return 'Urdu';
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      case 'zh':
        return 'Chinese';
      case 'ja':
        return 'Japanese';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          child: Column(
            children: [
              // Skip button at top right
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.04),

              // Single language icon at top center
              Center(
                child: Image.asset(
                  'assets/translating.png', 
                  width: screenWidth * 0.18,
                  height: screenWidth * 0.18,
                  fit: BoxFit.contain,
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // Title
              Text(
                'Select Language',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: screenWidth * 0.065,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: screenHeight * 0.04),

              // Language options in 2-column grid
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: screenWidth * 0.05,
                      mainAxisSpacing: screenHeight * 0.02,
                      childAspectRatio: 1.8,
                    ),
                    itemCount: languageProvider.supportedLanguageNames.length,
                    itemBuilder: (context, index) {
                      final languageName = languageProvider.supportedLanguageNames[index];
                      final languageCode = languageProvider.supportedLanguageCodes[index];
                      final isSelected = _selectedLanguageCode == languageCode;
                      final englishName = _getEnglishLanguageName(languageCode);

                      return GestureDetector(
                        onTap: () => _selectLanguage(languageCode, languageName),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue[50] : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Language name in its native script
                                    Text(
                                      _getLanguageInNativeScript(languageCode),
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: screenWidth * 0.045,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    
                                    // English name below in smaller text (only for non-English)
                                    if (englishName != null) ...[
                                      SizedBox(height: screenHeight * 0.005),
                                      Text(
                                        englishName,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: screenWidth * 0.03,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              
                              // Checkmark for selected language - top right
                              if (isSelected)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.blue,
                                    size: screenWidth * 0.05,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Continue button - Only show when a language is selected
              if (_selectedLanguageCode != null) ...[
                SizedBox(height: screenHeight * 0.03),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _completeOnboarding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: screenHeight * 0.025, // Same height as text
                              child: FittedBox(
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            )
                          : Text(
                              _getContinueText(_selectedLanguageCode!),
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
              
              SizedBox(height: screenHeight * 0.04),
            ],
          ),
        ),
      ),
    );
  }
}