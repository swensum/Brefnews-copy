import 'package:flutter/material.dart';

class AppTheme {
   
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
     hintColor: Colors.black87,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
    colorScheme: ColorScheme.light(
      primary: Colors.blue[800]!, 
      onPrimary: Colors.white,
      surface: Colors.white, 
      onPrimaryContainer: Colors.transparent,
      outlineVariant: Colors.grey,
      onSurface: Colors.black, 
      onSecondary: Colors.grey[900]!,
      outline: Colors.grey[300]!,
      error: Colors.orange,
   onSecondaryFixed: Colors.grey[700]!,
    ),
    
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.grey[600]!),
      bodyMedium: TextStyle(color: Colors.black),
      titleLarge: TextStyle(color: const Color.fromARGB(74, 81, 122, 137)),
      titleMedium: TextStyle(color: Colors.grey[700]!),
    ),
      textSelectionTheme: TextSelectionThemeData(
      cursorColor: Colors.black,
      selectionColor: Colors.blue.withValues(alpha: 0.3),
      selectionHandleColor: Colors.blue[800], 
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    hintColor: Colors.black87,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
    colorScheme: ColorScheme.dark(
      primary: Colors.blue,
      onPrimary: Colors.white,
      surface: Color(0xFF131313), 
       outlineVariant: Colors.grey,
      onSurface: Colors.white,    
     onPrimaryContainer:  Color(0xFFF0F4FF),
      onSecondary: Colors.grey[900]!, 
   onSecondaryFixed: Colors.grey[300]!,
      outline: Colors.grey[300]!,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.grey[600]!),
      bodyMedium: TextStyle(color: Colors.white),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Colors.white70),
    ),
      textSelectionTheme:  TextSelectionThemeData(
      cursorColor: Colors.grey, // Cursor color for dark theme
      selectionColor: Colors.blue.withValues(alpha: 0.3), // Selection color
      selectionHandleColor: Colors.blue, // Selection handle color
    ),
  );
}
