import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'en';
  
  final Map<String, String> _supportedLanguages = {
    'en': 'English',
    'hi': 'Hindi',
    'es': 'Spanish',
    'fr': 'French',
    'ur': 'Urdu',
    'zh': 'Chinese',
    'ja': 'Japanese',
  };

  // Dynamic methods and properties (preserved from your original code)
  String get currentLanguage => _currentLanguage;
  String get currentLanguageName => _supportedLanguages[_currentLanguage] ?? 'English';
  List<String> get supportedLanguageCodes => _supportedLanguages.keys.toList();
  List<String> get supportedLanguageNames => _supportedLanguages.values.toList();

  // App restart tracking
  bool _needsAppRestart = false;
  bool get needsAppRestart => _needsAppRestart;

  // Add initialization tracking
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  LanguageProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCurrentLanguage();
    _isInitialized = true;
    notifyListeners();
    print('🟢 [LanguageProvider] Initialization completed with language: $_currentLanguage');
  }

  Future<void> setLanguage(String languageCode) async {
    if (_supportedLanguages.containsKey(languageCode)) {
      _currentLanguage = languageCode;
      await _saveCurrentLanguage();
      
      // Check if language change requires app restart
      _needsAppRestart = true;
      
      notifyListeners();
      print('🟢 [LanguageProvider] Language set to: $languageCode');
    }
  }

  Future<void> _loadCurrentLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString('current_language') ?? 'en';
      print('🟢 [LanguageProvider] Loaded language preference: $_currentLanguage');
    } catch (e) {
      print('Error loading language: $e');
      _currentLanguage = 'en';
    }
  }

  Future<void> _saveCurrentLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_language', _currentLanguage);
      print('💾 [LanguageProvider] Saved language preference: $_currentLanguage');
    } catch (e) {
      print('Error saving language: $e');
    }
  }

  // Wait for initialization to complete
  Future<void> ensureInitialized() async {
    while (!_isInitialized) {
      await Future.delayed(Duration(milliseconds: 10));
    }
  }

  // ========== DYNAMIC METHODS (PRESERVED) ==========

  String getLanguageCode(String languageName) {
    return _supportedLanguages.entries
        .firstWhere(
          (entry) => entry.value == languageName,
          orElse: () => MapEntry('en', 'English'),
        )
        .key;
  }

  String getLanguageName(String languageCode) {
    return _supportedLanguages[languageCode] ?? 'English';
  }

  // Check if language is supported
  bool isLanguageSupported(String languageCode) {
    return _supportedLanguages.containsKey(languageCode);
  }

  // Get language flag emoji (optional utility method)
  String getLanguageFlag(String languageCode) {
    final flags = {
      'en': '🇺🇸',
      'hi': '🇮🇳',
      'es': '🇪🇸',
      'fr': '🇫🇷',
      'ur': '🇵🇰',
      'zh': '🇨🇳',
      'ja': '🇯🇵',
    };
    return flags[languageCode] ?? '🌐';
  }

  // Reset app restart flag
  void resetRestartFlag() {
    _needsAppRestart = false;
    notifyListeners();
  }

  // Get language info for display
  Map<String, dynamic> getLanguageInfo(String languageCode) {
    return {
      'code': languageCode,
      'name': _supportedLanguages[languageCode] ?? 'English',
      'isCurrent': languageCode == _currentLanguage,
      'flag': getLanguageFlag(languageCode),
    };
  }

  // Get all languages with info
  List<Map<String, dynamic>> getAllLanguagesInfo() {
    return _supportedLanguages.keys.map((code) => getLanguageInfo(code)).toList();
  }

  // Validate and set language with fallback
  Future<void> setLanguageWithFallback(String languageCode, {String fallback = 'en'}) async {
    if (isLanguageSupported(languageCode)) {
      await setLanguage(languageCode);
    } else {
      print('⚠️ Language $languageCode not supported, falling back to $fallback');
      await setLanguage(fallback);
    }
  }

  // Get current locale
  Locale get currentLocale => Locale(_currentLanguage);

  // Check if current language is RTL
  bool get isRTL {
    return _currentLanguage == 'ur' || _currentLanguage == 'ar'; // Add other RTL languages as needed
  }
}