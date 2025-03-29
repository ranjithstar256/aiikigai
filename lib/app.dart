import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/services/analytics_service.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/home/connecting_dots_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/section_screen.dart';
import 'screens/premium/subscription_screen.dart';
import 'screens/startup/onboarding_screen.dart';
import 'screens/startup/splash_screen.dart';

class IkigaiApp extends ConsumerWidget {
  final bool isFirstRun;
  final String? firebaseErrorMessage;

  const IkigaiApp({
    Key? key,
    required this.isFirstRun,
    this.firebaseErrorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final analytics = ref.watch(analyticsServiceProvider).analytics;

    // Set up router
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/section/:id',
          builder: (context, state) {
            final sectionId = state.pathParameters['id']!;
            return SectionScreen(sectionId: sectionId);
          },
        ),
        GoRoute(
          path: '/connecting-dots',
          builder: (context, state) => const ConnectingDotsScreen(),
        ),
        GoRoute(
          path: '/chat',
          builder: (context, state) => const ChatScreen(),
        ),
        GoRoute(
          path: '/subscription',
          builder: (context, state) => const SubscriptionScreen(),
        ),
      ],
      redirect: (context, state) {
        // Handle initial redirects
        if (state.fullPath == '/') {
          return isFirstRun ? '/onboarding' : '/home';
        }

        // Check if user is authenticated for protected routes
        final isLoggedIn = ref.read(authProvider).isLoggedIn;
        final isAuthRoute = state.fullPath == '/login' || state.fullPath == '/signup';

        // Protected routes
        final protectedRoutes = ['/connecting-dots', '/chat', '/subscription'];

        if (!isLoggedIn && protectedRoutes.contains(state.fullPath)) {
          return '/login';
        }

        if (isLoggedIn && isAuthRoute) {
          return '/home';
        }

        return null;
      },
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text(
            'Page not found: ${state.fullPath}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
      observers: [
        FirebaseAnalyticsObserver(analytics: analytics),
      ],
    );

    return MaterialApp.router(
      title: 'Ikigai Journey',
      debugShowCheckedModeBanner: false,
      theme: themeState.lightTheme.copyWith(
        textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme),
      ),
      darkTheme: themeState.darkTheme.copyWith(
        textTheme: GoogleFonts.latoTextTheme(ThemeData.dark().textTheme),
      ),
      themeMode: themeState.themeMode,
      routerConfig: router,
    );
  }
}