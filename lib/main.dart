import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'language/app_localizations.dart';
import 'provider/auth_provider.dart';
import 'provider/language_provider.dart';
import 'provider/news_provider.dart';
import 'provider/themeprovider.dart';

import 'repositories/notification_service.dart';
import 'route/route.dart';
import 'utilities/supabase_init.dart';
import 'utilities/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await SupabaseInitializer.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => NewsProvider()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        // Initialize NotificationService here
        ChangeNotifierProvider(
          create: (_) => NotificationService()..init(),
          lazy: false, 
        ),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          print('🎯 [MyApp] Building with language: ${languageProvider.currentLanguage}');
          
          return MaterialApp.router(
            key: Key('app_${languageProvider.currentLanguage}'), 
            routerConfig: AppRouter.router,
            title: 'Bref News',
           
            locale: languageProvider.currentLocale,
            supportedLocales: const [
              Locale('en'), // English
              Locale('hi'), // Hindi
              Locale('es'), // Spanish
              Locale('fr'), // French
              Locale('ur'), // Urdu
              Locale('zh'), // Chinese
              Locale('ja'), // Japanese
            ],
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            
            // Theme setup
            theme: AppTheme.lightTheme, 
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            
            // RTL support
            builder: (context, child) {
              return Directionality(
                textDirection: languageProvider.isRTL ? TextDirection.rtl : TextDirection.ltr,
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}