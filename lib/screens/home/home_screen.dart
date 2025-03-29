import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/analytics_service.dart';
import '../../data/services/firebase_service.dart';
import '../../models/question.dart';
import '../../models/section.dart';
import '../../providers/answers_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/questions_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/ikigai/section_card.dart';
import '../../widgets/premium/premium_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Log screen view
    ref.read(analyticsServiceProvider).logScreenView('home_screen');

    // Add this to load sections when screen first appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(questionsProvider.notifier).loadSections().then((_) {
        // Force rebuild after sections are loaded
        if (mounted) setState(() {});
      });
    });
  }

  void _navigateToSection(Section section) {
    // Log section selected
    ref.read(analyticsServiceProvider).logEvent(
      'section_selected',
      parameters: {'section_id': section.id},
    );

    context.push('/section/${section.id}');
  }

  void _navigateToConnectingDots() {
    final allComplete = ref.read(allRequiredSectionsCompleteProvider);

    if (allComplete) {
      context.push('/connecting-dots');
    } else {
      _showCompleteSectionsDialog();
    }
  }

  void _showCompleteSectionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete All Sections'),
        content: const Text(
          'Please complete all four basic sections before connecting the dots.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showThemeMenu() {
    final themeNotifier = ref.read(themeProvider.notifier);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose Theme',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.color_lens, color: Colors.blueAccent),
                title: const Text('Classic Blue'),
                onTap: () {
                  themeNotifier.setTheme('Classic');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.color_lens, color: Colors.deepOrange),
                title: const Text('Orange Theme'),
                onTap: () {
                  themeNotifier.setTheme('Orange');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.color_lens, color: Colors.deepPurple),
                title: const Text('Purple Theme'),
                onTap: () {
                  themeNotifier.setTheme('Purple');
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Toggle Dark Mode'),
                onTap: () {
                  themeNotifier.toggleDarkMode();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get available sections based on subscription
    final sections = ref.watch(availableSectionsProvider);

    // Get completed sections count
    final completedCount = ref.watch(completedSectionsCountProvider);

    // Get premium status
    final isPremium = ref.watch(authProvider).user?.isPremium ?? false;

    // Loading state
    final isLoading = ref.watch(questionsProvider).isLoading;

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Discover Your Ikigai",
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 5,
        actions: [
          IconButton(
            icon: const Icon(Icons.color_lens, color: Colors.white),
            onPressed: _showThemeMenu,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Progress: $completedCount/${sections.length} sections completed.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontFamily: GoogleFonts.lato().fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Premium banner if not premium
            if (!isPremium) const PremiumBanner(),



            // Sections list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  final section = sections[index];
                  final isComplete = ref.watch(
                      sectionCompleteProvider(section)
                  );

                  return SectionCard(
                    section: section,
                    isCompleted: isComplete,
                    onTap: () => _navigateToSection(section),
                  );
                },
              ),
            ),

            // Connect the dots button
            Padding(
              padding: const EdgeInsets.all(16),
              child:
              Column(children: [ElevatedButton(
                onPressed: _navigateToConnectingDots,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 40,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "Connect the Dots",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontFamily: GoogleFonts.lato().fontFamily,
                    fontSize: 18,
                  ),
                ),
              ),
                // In your HomeScreen build method
                /*ElevatedButton(
                  onPressed: _testFirebaseConnection,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    backgroundColor: Colors.green, // A distinct color
                  ),
                  child: Text(
                    "Test Firebase",
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontFamily: GoogleFonts.lato().fontFamily,
                      fontSize: 18,
                    ),
                  ),
                )*/
              ])
            ),
          ],
        ),
      ),
    );
  }

  // New method to test Firebase connectivity by saving dummy sections
  // Test Firebase connection by saving dummy sections
  /*//b4 deep thinkng code
  Future<void> _testFirebaseConnection() async {
    try {
      print("Starting Firebase connection test...");

      // First, try to read from Firestore to check if you can access the database
      final sectionsCollection = FirebaseFirestore.instance.collection('sections');
      final snapshot = await sectionsCollection.get();

      print("Successfully connected to Firestore!");
      print("Found ${snapshot.docs.length} sections in the database");

      if (snapshot.docs.isNotEmpty) {
        // Print the first document to see its structure
        print("Sample document data: ${snapshot.docs.first.data()}");
      }

      // Rest of your existing code to save sections...
      // ...
    } catch (e) {
      print("Error in Firebase test: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firebase test error: $e')),
      );
    }
  }*/

 /* Future<void> _testFirebaseConnection() async {
    try {
      print("Starting Firebase connection test...");

      // Try to read from Firestore
      final sectionsCollection = FirebaseFirestore.instance.collection('sections');
      print("Attempting to query 'sections' collection...");

      final snapshot = await sectionsCollection.limit(5).get();

      print("Successfully connected to Firestore!");
      print("Found ${snapshot.docs.length} sections in the database");

      if (snapshot.docs.isNotEmpty) {
        // Print the first document structure to debug
        final firstDoc = snapshot.docs.first;
        print("Sample document ID: ${firstDoc.id}");
        print("Sample document fields: ${firstDoc.data().keys.join(', ')}");

        // Check for questions field
        if (firstDoc.data().containsKey('questions')) {
          final questions = firstDoc.data()['questions'];
          print("Questions field type: ${questions.runtimeType}");
          if (questions is List) {
            print("Questions count: ${questions.length}");
            if (questions.isNotEmpty) {
              print("First question structure: ${questions.first.runtimeType}");
            }
          }
        } else {
          print("WARNING: 'questions' field is missing in the document!");
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firebase test successful! Check console for details.'))
      );
    } catch (e) {
      print("Error in Firebase test: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firebase test error: $e'))
      );
    }
  }*/
}