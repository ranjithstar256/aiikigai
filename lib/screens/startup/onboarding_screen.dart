/*
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/services/analytics_service.dart';


class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
  {
  'title': 'Discover Your Ikigai',
  'description': 'Ikigai is a Japanese concept meaning "a reason for being." It lies at the intersection of what you love, what you are good at, what the world needs, and what you can be paid for.',
  'image': 'assets/images/onboarding_1.png',
  'icon': Icons.emoji_objects,
},
{
'title': 'Answer Thoughtful Questions',
'description': 'Journey through carefully crafted questions designed to reveal your passions, strengths, values, and potential income sources.',
'image': 'assets/images/onboarding_2.png',
'icon': Icons.question_answer,
},
{
'title': 'Connect The Dots',
'description': 'Our AI-powered analysis will connect the dots between your answers, providing insights about your unique Ikigai and actionable steps to pursue it.',
'image': 'assets/images/onboarding_3.png',
'icon': Icons.psychology,
},
{
'title': 'Start Your Journey Today',
'description': 'Take the first step toward a fulfilling life aligned with your purpose. Your Ikigai journey begins now!',
'image': 'assets/images/onboarding_4.png',
'icon': Icons.rocket_launch,
},
];

@override
void dispose() {
  _pageController.dispose();
  super.dispose();
}

void _onPageChanged(int page) {
  setState(() {
    _currentPage = page;
  });
}

void _navigateToHome() {
  // Log completed onboarding
  ref.read(analyticsServiceProvider).logEvent('onboarding_completed');
  context.go('/home');
}

@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final size = MediaQuery.of(context).size;

  return Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          // Skip button
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0, right: 16.0),
              child: TextButton(
                onPressed: _navigateToHome,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Page content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon or image
                      Container(
                        height: size.height * 0.3,
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            page['icon'] as IconData,
                            size: 100,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Title
                      Text(
                        page['title'],
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Description
                      Text(
                        page['description'],
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Page indicator and buttons
          Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: Column(
              children: [
                // Page indicator
                SmoothPageIndicator(
                  controller: _pageController,
                  count: _pages.length,
                  effect: ExpandingDotsEffect(
                    dotHeight: 10,
                    dotWidth: 10,
                    activeDotColor: theme.primaryColor,
                    dotColor: Colors.grey.shade300,
                  ),
                ),
                const SizedBox(height: 32),

                // Navigation buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button (hidden on first page)
                      _currentPage > 0
                          ? TextButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Text(
                          'Back',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontSize: 16,
                          ),
                        ),
                      )
                          : const SizedBox(width: 80),

                      // Next/Get Started button
                      ElevatedButton(
                        onPressed: () {
                          if (_currentPage < _pages.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _navigateToHome();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          _currentPage < _pages.length - 1
                              ? 'Next'
                              : 'Get Started',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}*/


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/services/analytics_service.dart';


class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Discover Your Ikigai',
      'description': 'Ikigai is a Japanese concept meaning "a reason for being." It lies at the intersection of what you love, what you are good at, what the world needs, and what you can be paid for.',
      'image': 'assets/images/onboarding_1.png',
      'icon': Icons.emoji_objects,
    },
    {
      'title': 'Answer Thoughtful Questions',
      'description': 'Journey through carefully crafted questions designed to reveal your passions, strengths, values, and potential income sources.',
      'image': 'assets/images/onboarding_2.png',
      'icon': Icons.question_answer,
    },
    {
      'title': 'Connect The Dots',
      'description': 'Our AI-powered analysis will connect the dots between your answers, providing insights about your unique Ikigai and actionable steps to pursue it.',
      'image': 'assets/images/onboarding_3.png',
      'icon': Icons.psychology,
    },
    {
      'title': 'Start Your Journey Today',
      'description': 'Take the first step toward a fulfilling life aligned with your purpose. Your Ikigai journey begins now!',
      'image': 'assets/images/onboarding_4.png',
      'icon': Icons.rocket_launch,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _navigateToHome() {
    // Log completed onboarding
    ref.read(analyticsServiceProvider).logEvent('onboarding_completed');
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0, right: 16.0),
                child: TextButton(
                  onPressed: _navigateToHome,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // Page content (wrapped in Expanded to prevent overflow)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon or image
                          Container(
                            height: size.height * 0.25, // Reduced height
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                page['icon'] as IconData,
                                size: 80, // Reduced size
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24), // Reduced space

                          // Title
                          Text(
                            page['title'],
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 24, // Reduced size
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16), // Reduced space

                          // Description
                          Text(
                            page['description'],
                            style: GoogleFonts.lato(
                              fontSize: 15, // Reduced size
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Page indicator and buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0), // Reduced padding
              child: Column(
                children: [
                  // Page indicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      dotHeight: 8, // Reduced size
                      dotWidth: 8, // Reduced size
                      activeDotColor: theme.primaryColor,
                      dotColor: Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(height: 24), // Reduced space

                  // Navigation buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button (hidden on first page)
                        _currentPage > 0
                            ? TextButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Text(
                            'Back',
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontSize: 16,
                            ),
                          ),
                        )
                            : const SizedBox(width: 80),

                        // Next/Get Started button
                        ElevatedButton(
                          onPressed: () {
                            if (_currentPage < _pages.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              _navigateToHome();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12, // Reduced padding
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            _currentPage < _pages.length - 1
                                ? 'Next'
                                : 'Get Started',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}