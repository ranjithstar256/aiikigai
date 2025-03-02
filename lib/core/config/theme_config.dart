import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Configuration for app themes
class ThemeConfig {
  // Available theme names
  static const String classicTheme = 'Classic';
  static const String orangeTheme = 'Orange';
  static const String purpleTheme = 'Purple';
  static const String premiumTheme = 'Premium';

  // Get a theme by name
  static ThemeData getThemeByName(String themeName) {
    switch (themeName) {
      case orangeTheme:
        return orangeLight;
      case purpleTheme:
        return purpleLight;
      case premiumTheme:
        return premiumLight;
      case classicTheme:
      default:
        return classicLight;
    }
  }

  // Classic Blue theme (Light)
  static ThemeData get classicLight => _createTheme(
    primaryColor: Colors.blueAccent,
    secondaryColor: Colors.blue,
    tertiaryColor: Colors.lightBlueAccent,
    isDark: false,
  );

  // Orange theme (Light)
  static ThemeData get orangeLight => _createTheme(
    primaryColor: Colors.deepOrange,
    secondaryColor: Colors.deepOrangeAccent,
    tertiaryColor: Colors.pinkAccent,
    isDark: false,
  );

  // Purple theme (Light)
  static ThemeData get purpleLight => _createTheme(
    primaryColor: Colors.deepPurple,
    secondaryColor: Colors.deepPurpleAccent,
    tertiaryColor: Colors.purpleAccent,
    isDark: false,
  );

  // Premium Gold theme (Light)
  static ThemeData get premiumLight => _createPremiumTheme(isDark: false);

  // Dark theme
  static ThemeData get darkTheme => _createDarkTheme();

  // Helper method to create a theme
  static ThemeData _createTheme({
    required Color primaryColor,
    required Color secondaryColor,
    required Color tertiaryColor,
    required bool isDark,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: isDark ? Brightness.dark : Brightness.light,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
      ),
      textTheme: GoogleFonts.latoTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          elevation: isDark ? 2 : 4,
        ),
      ),
      cardTheme: CardTheme(
        elevation: isDark ? 2 : 6,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDark ? Colors.grey.shade800 : Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
      ),
      scaffoldBackgroundColor: isDark ? Colors.black : Colors.white,
      dividerColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        elevation: isDark ? 4 : 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentTextStyle: TextStyle(
          fontFamily: GoogleFonts.lato().fontFamily,
        ),
      ),
    );
  }

  // Helper method to create premium theme
  static ThemeData _createPremiumTheme({required bool isDark}) {
    final goldColor = const Color(0xFFD4AF37);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: goldColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: goldColor,
        brightness: isDark ? Brightness.dark : Brightness.light,
        secondary: const Color(0xFFE8C36D),
        tertiary: const Color(0xFF8B7D41),
      ),
      textTheme: GoogleFonts.playfairDisplayTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: goldColor,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: goldColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
          textStyle: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          elevation: isDark ? 2 : 8,
        ),
      ),
      cardTheme: CardTheme(
        elevation: isDark ? 4 : 8,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDark ? Colors.grey.shade900 : Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: goldColor, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: goldColor, width: 2),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      ),
      scaffoldBackgroundColor: isDark ? Colors.black : Colors.white,
    );
  }

  // Dark theme for all variants
  static ThemeData _createDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: Colors.grey.shade800,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.grey,
        brightness: Brightness.dark,
        secondary: Colors.grey.shade700,
        tertiary: Colors.grey.shade600,
      ),
      scaffoldBackgroundColor: Colors.black,
      textTheme: GoogleFonts.latoTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.grey.shade800,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          elevation: 2,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.grey.shade900,
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade700, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade500, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade900,
      ),
      dividerColor: Colors.grey.shade700,
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.grey.shade900,
        elevation: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.grey.shade800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentTextStyle: TextStyle(
          fontFamily: GoogleFonts.lato().fontFamily,
          color: Colors.white,
        ),
      ),
    );
  }
}