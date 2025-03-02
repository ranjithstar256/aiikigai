import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration constants for the application
class AppConfig {
  // App information
  static const String appName = 'Ikigai Journey';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Theme names
  static const String classicTheme = 'Classic';
  static const String orangeTheme = 'Orange';
  static const String purpleTheme = 'Purple';
  static const String premiumTheme = 'Premium';

  // API configuration
  static String get apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static const String apiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String apiBaseUrl = 'https://ikigai-api.example.com/api/v1';

  // In-app purchase product IDs
  static const String basicMonthlyProductId = 'ikigai_basic_monthly';
  static const String premiumMonthlyProductId = 'ikigai_premium_monthly';
  static const String premiumYearlyProductId = 'ikigai_premium_yearly';

  // Subscription plans
  static const Map<String, Map<String, dynamic>> subscriptionPlans = {
    'free': {
      'name': 'Free',
      'price': '₹0',
      'description': 'Basic features',
      'features': [
        'Access to 4 basic sections',
        'Generate basic insights',
        'Download PDF report',
      ],
    },
    'basic': {
      'name': 'Basic',
      'price': '₹299/month',
      'priceId': 'ikigai_basic_monthly',
      'description': 'Enhanced experience',
      'features': [
        'Access to all sections',
        'Generate detailed insights',
        'Download PDF report',
        'Chat with AI assistant',
      ],
    },
    'premium': {
      'name': 'Premium',
      'price': '₹499/month',
      'priceId': 'ikigai_premium_monthly',
      'description': 'Premium experience',
      'features': [
        'All Basic plan features',
        'Advanced analytics',
        'Personalized recommendations',
        'Exclusive premium sections',
        'Priority support',
      ],
    },
    'premium_yearly': {
      'name': 'Premium Yearly',
      'price': '₹3,999/year',
      'priceId': 'ikigai_premium_yearly',
      'description': 'Save 33% with yearly billing',
      'features': [
        'All Premium plan features',
        '33% discount with yearly subscription',
      ],
    },
  };

  // URL constants
  static const String privacyPolicyUrl = 'https://www.androidmanifester.in/privacy-policy';
  static const String termsOfServiceUrl = 'https://www.androidmanifester.in/terms-of-service';
  static const String helpCenterUrl = 'https://www.androidmanifester.in/help-center';

  // Local storage keys
  static const String isFirstRunKey = 'is_first_run';
  static const String darkModeKey = 'dark_mode';
  static const String selectedThemeKey = 'selected_theme';
  static const String userKey = 'user';
  static const String answersKey = 'answers';
  static const String insightKey = 'insight';
  static const String authTokenKey = 'auth_token';

  // Firebase collection names
  static const String usersCollection = 'users';
  static const String sectionsCollection = 'sections';
  static const String answersCollection = 'answers';
  static const String insightsCollection = 'insights';

  // Default onboarding pages
  static const List<Map<String, String>> onboardingPages = [
      {
  'title': 'Discover Your Ikigai',
  'description': 'Ikigai is a Japanese concept meaning "a reason for being." It lies at the intersection of what you love, what you are  good at, what the world needs, and what you can be paid for.',
  'image': 'assets/images/onboarding_1.png',
},
{
'title': 'Answer Thoughtful Questions',
'description': 'Journey through carefully crafted questions designed to reveal your passions, strengths, values, and potential income sources.',
'image': 'assets/images/onboarding_2.png',
},
{
'title': 'Connect The Dots',
'description': 'Our AI-powered analysis will connect the dots between your answers, providing insights about your unique Ikigai and actionable steps to pursue it',
'image': 'assets/images/onboarding_3.png',
},
{
'title': 'Start Your Journey Today',
'description': 'Take the first step toward a fulfilling life aligned with your purpose. Your Ikigai journey begins now!',
'image': 'assets/images/onboarding_4.png',
},
];

// App font families
static const String primaryFontFamily = 'Lato';
static const String headingFontFamily = 'PlayfairDisplay';
static const String bodyFontFamily = 'Lora';

// Animation durations
static const Duration shortAnimationDuration = Duration(milliseconds: 300);
static const Duration mediumAnimationDuration = Duration(milliseconds: 600);
static const Duration longAnimationDuration = Duration(seconds: 1);

// Layout constants
static const double defaultPadding = 16.0;
static const double defaultMargin = 16.0;
static const double defaultRadius = 16.0;
static const double defaultButtonHeight = 56.0;
static const double defaultCardElevation = 6.0;

// Default sections data (fallback if Firebase fails)
static const List<Map<String, dynamic>> defaultSections = [
{
'id': 'love',
'title': 'Finding What You Love ❤️',
'description': 'Explore your deepest passions.',
'iconName': 'favorite',
'questions': [
{
'id': 'q1',
'text': 'Imagine you wake up tomorrow, and you have unlimited money & time for the next 10 years. What would you spend your days doing?',
},
{
'id': 'q2',
'text': 'A genie appears and says, "You can only do one activity for the rest of your life—but it will make you incredibly happy." What do you choose?',
},
{
'id': 'q3',
'text': 'You find yourself on a mystical island with unlimited resources. What would you create?',
},
{
'id': 'q4',
'text': 'If you had to teach a class that would inspire the world, what topic would you teach?',
},
{
'id': 'q5',
'text': 'You get the power to master any skill instantly—no effort, no practice. What skill would you choose?',
},
],
'isPremium': false,
'order': 1,
},
{
'id': 'strengths',
'title': 'Discovering Your Strengths 💪',
'description': 'Uncover your natural talents.',
'iconName': 'star',
'questions': [
{
'id': 'q1',
'text': 'you are  in a survival game where each person must contribute a unique skill to win. What skill do you offer?',
},
{
'id': 'q2',
'text': 'Your closest friends need urgent help with something—something only YOU can do better than anyone else. What is it?',
},
{
'id': 'q3',
'text': 'A mysterious businessman offers you ₹1 Crore per month, but only if you use a skill you are  naturally good at. What is it?',
},
{
'id': 'q4',
'text': 'You wake up one day and realize one of your strengths has been amplified 100x. What is your new power?',
},
{
'id': 'q5',
'text': 'If you had to train someone to become an expert at something in 1 year, what skill would you teach?',
},
],
'isPremium': false,
'order': 2,
},
{
'id': 'world_needs',
'title': 'What the World Needs 🌍',
'description': 'Make a meaningful impact.',
'iconName': 'public',
'questions': [
{
'id': 'q1',
'text': 'You are given the power to solve ONE major global issue instantly. What problem do you fix?',
},
{
'id': 'q2',
'text': 'If a billionaire gave you unlimited resources to improve the world in ONE way, what would you do?',
},
{
'id': 'q3',
'text': 'An alien race visits Earth and says, "Tell us one thing that humans should improve about the world." What would you tell them?',
},
{
'id': 'q4',
'text': 'You meet someone struggling with life. What is one powerful lesson from your own life that you would share to help them?',
},
{
'id': 'q5',
'text': 'Imagine you have only one message to leave behind for future generations. What wisdom would you pass down?',
},
],
'isPremium': false,
'order': 3,
},
{
'id': 'paid_for',
'title': 'What You Can Be Paid For 💰',
'description': 'Turn skills into opportunities.',
'iconName': 'attach_money',
'questions': [
{
'id': 'q1',
'text': 'If you were suddenly forced to earn money using ONLY your knowledge & talents, how would you do it?',
},
{
'id': 'q2',
'text': 'A new "Talent Auction" is created where companies bid for the best skills. What skill would companies bid the highest amount for in YOU?',
},
{
'id': 'q3',
'text': 'You are hired as a consultant for a top company. What problem would you help them solve?',
},
{
'id': 'q4',
'text': 'Your younger self travels to the future and asks, "What is the fastest way I can start earning money doing something I love?" What advice would you give them?',
},
{
'id': 'q5',
'text': 'A mysterious businessman offers you ₹1 Crore per month, but only if you use a skill you are  naturally good at. What is it?',
},
],
'isPremium': false,
'order': 4,
},
{
'id': 'deeper_passion',
'title': 'Deeper Passions Analysis 🧠',
'description': 'Discover your life\'s deeper purpose.',
'iconName': 'psychology',
'questions': [
{
'id': 'q1',
'text': 'When you close your eyes and imagine your perfect life 10 years from now, what does a typical day look like in vivid detail?',
},
{
'id': 'q2',
'text': 'If you knew you had only 5 years left to live, what would you absolutely need to accomplish before your time is up?',
},
{
'id': 'q3',
'text': 'What activities make you completely lose track of time when you are  doing them?',
},
{
'id': 'q4',
'text': 'What recurring dreams or themes appear in your imagination that might indicate deeper desires?',
},
{
'id': 'q5',
'text': 'What childhood passions did you abandon that still occasionally call to you?',
},
],
'isPremium': true,
'order': 5,
},
{
'id': 'hidden_talents',
'title': 'Hidden Talents Analysis 🎯',
'description': 'Uncover your undiscovered abilities.',
'iconName': 'auto_awesome',
'questions': [
{
'id': 'q1',
'text': 'What tasks do others find difficult that seem surprisingly easy to you?',
},
{
'id': 'q2',
'text': 'What compliments do you regularly receive but tend to dismiss?',
},
{
'id': 'q3',
'text': 'What skills have you developed accidentally while pursuing other interests?',
},
{
'id': 'q4',
'text': 'What problems do friends and family consistently come to you to solve?',
},
{
'id': 'q5',
'text': 'If you could develop a currently underdeveloped talent to its maximum potential, what would you choose?',
},
],
'isPremium': true,
'order': 6,
},
{
'id': 'purpose_alignment',
'title': 'Purpose Alignment 🏆',
'description': 'Find your life\'s true mission.',
'iconName': 'lightbulb',
'questions': [
{
'id': 'q1',
'text': 'If you were writing the story of your life, what would be the most meaningful chapter yet to be written?',
},
{
'id': 'q2',
'text': 'What injustice or problem in the world triggers the strongest emotional response in you?',
},
{
'id': 'q3',
'text': 'What personal experience has shaped your worldview the most profoundly?',
},
{
'id': 'q4',
'text': 'If you had to dedicate your life to solving one problem, what would it be?',
},
{
'id': 'q5',
'text': 'What legacy would you like to leave that would still matter 100 years from now?',
},
],
'isPremium': true,
'order': 7,
},
];

// Debug settings
static const bool enableAnalyticsInDebug = false;
static const bool enableCrashReportingInDebug = false;
}