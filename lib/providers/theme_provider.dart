import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/services/firebase_service.dart';


// Theme state class
class ThemeState {
  final ThemeData lightTheme;
  final ThemeData darkTheme;
  final ThemeMode themeMode;
  final String currentThemeName;

  ThemeState({
    required this.lightTheme,
    required this.darkTheme,
    required this.themeMode,
    required this.currentThemeName,
  });

  ThemeState copyWith({
    ThemeData? lightTheme,
    ThemeData? darkTheme,
    ThemeMode? themeMode,
    String? currentThemeName,
  }) {
    return ThemeState(
      lightTheme: lightTheme ?? this.lightTheme,
      darkTheme: darkTheme ?? this.darkTheme,
      themeMode: themeMode ?? this.themeMode,
      currentThemeName: currentThemeName ?? this.currentThemeName,
    );
  }
}

// Theme provider notifier
class ThemeNotifier extends StateNotifier<ThemeState> {
  final SharedPreferences _prefs;

  ThemeNotifier(this._prefs)
      : super(
    ThemeState(
      lightTheme: _getTheme("Classic"),
      darkTheme: _getDarkTheme(),
      themeMode: ThemeMode.light,
      currentThemeName: "Classic",
    ),
  ) {
    _loadThemePreferences();
  }

  void _loadThemePreferences() {
    final themeName = _prefs.getString('selectedTheme') ?? 'Classic';
    final isDarkMode = _prefs.getBool('isDarkMode') ?? false;

    state = state.copyWith(
      lightTheme: _getTheme(themeName),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      currentThemeName: themeName,
    );
  }

  Future<void> setTheme(String themeName) async {
    await _prefs.setString('selectedTheme', themeName);

    state = state.copyWith(
      lightTheme: _getTheme(themeName),
      currentThemeName: themeName,
    );
  }

  Future<void> toggleDarkMode() async {
    final isDarkMode = state.themeMode == ThemeMode.dark;
    await _prefs.setBool('isDarkMode', !isDarkMode);

    state = state.copyWith(
      themeMode: isDarkMode ? ThemeMode.light : ThemeMode.dark,
    );
  }

  static ThemeData _getTheme(String themeName) {
    switch (themeName) {
      case "Orange":
        return _createTheme(
          primaryColor: Colors.deepOrange,
          secondaryColor: Colors.deepOrangeAccent,
          tertiaryColor: Colors.pinkAccent,
        );
      case "Purple":
        return _createTheme(
          primaryColor: Colors.deepPurple,
          secondaryColor: Colors.deepPurpleAccent,
          tertiaryColor: Colors.purpleAccent,
        );
      case "Premium":
        return _createPremiumTheme();
      case "Classic":
      default:
        return _createTheme(
          primaryColor: Colors.blueAccent,
          secondaryColor: Colors.blue,
          tertiaryColor: Colors.lightBlueAccent,
        );
    }
  }

  static ThemeData _createTheme({
    required Color primaryColor,
    required Color secondaryColor,
    required Color tertiaryColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
      ),
      textTheme: GoogleFonts.latoTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 6,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  static ThemeData _createPremiumTheme() {
    final goldColor = Color(0xFFD4AF37);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: goldColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: goldColor,
        secondary: Color(0xFFE8C36D),
        tertiary: Color(0xFF8B7D41),
      ),
      textTheme: GoogleFonts.playfairDisplayTextTheme(),
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
        ),
      ),
      cardTheme: CardTheme(
        elevation: 8,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  static ThemeData _getDarkTheme() {
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
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.grey.shade800,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    );
  }
}

// Provider definition
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});