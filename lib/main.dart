import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/firebase_options.dart';
import 'core/services/analytics_service.dart';
import 'core/services/error_service.dart';
import 'data/services/firebase_service.dart'; // Already imported, ensures sharedPreferencesProvider is available

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await dotenv.load(fileName: ".env");

  String? firebaseErrorMessage;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    errorService.logInfo("Firebase initialized successfully");
  } catch (e) {
    firebaseErrorMessage = errorService.handleFirebaseInitError(e);
  }

  final firebaseService = FirebaseService();
  await firebaseService.initialize();

  final prefs = await SharedPreferences.getInstance();
  final analyticsService = AnalyticsService();

  final isFirstRun = prefs.getBool('is_first_run') ?? true;

  runApp(
    ProviderScope(
      overrides: [
        firebaseServiceProvider.overrideWithValue(firebaseService),
        sharedPreferencesProvider.overrideWithValue(prefs), // Now resolved via import
        analyticsServiceProvider.overrideWithValue(analyticsService),
      ],
      child: IkigaiApp(
        isFirstRun: isFirstRun,
        firebaseErrorMessage: firebaseErrorMessage,
      ),
    ),
  );
}