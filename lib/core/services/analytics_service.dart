import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider definition
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

class AnalyticsService {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  // Track screen views
  Future<void> logScreenView(String screenName) async {
    await analytics.logScreenView(screenName: screenName);
  }

  // Track app events
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
   // await analytics.logEvent(name: name, parameters: parameters);
  }

  // Track section completion
  Future<void> logSectionCompleted(String sectionId, String sectionTitle) async {
    await analytics.logEvent(
      name: 'section_completed',
      parameters: {
        'section_id': sectionId,
        'section_title': sectionTitle,
      },
    );
  }

// Track insight generation
  Future<void> logInsightGenerated(bool isPremium) async {
    await analytics.logEvent(
      name: 'insight_generated',
      parameters: {
        'is_premium': isPremium ? 1 : 0, // Convert boolean to integer
      },
    );
  }

  // Track PDF download
  Future<void> logPdfDownloaded() async {
    await analytics.logEvent(name: 'pdf_downloaded');
  }

  // Track subscription events
  Future<void> logSubscription(String subscriptionType, double price) async {
    await analytics.logPurchase(
      currency: 'INR',
      value: price,
      items: [
        AnalyticsEventItem(
          itemName: subscriptionType,
          itemCategory: 'subscription',
          price: price,
        ),
      ],
    );
  }

  // Track user sign-up
  Future<void> logSignUp(String method) async {
    await analytics.logSignUp(signUpMethod: method);
  }

  // Track user login
  Future<void> logLogin(String method) async {
    await analytics.logLogin(loginMethod: method);
  }

  // Set user properties
  Future<void> setUserProperties({
    required String userId,
    required String userRole,
  }) async {
    await analytics.setUserId(id: userId);
    await analytics.setUserProperty(name: 'user_role', value: userRole);
  }

  // Track app open
  Future<void> logAppOpen() async {
    await analytics.logAppOpen();
  }
}