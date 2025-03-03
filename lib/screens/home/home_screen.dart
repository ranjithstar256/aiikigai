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
    final isPremium = ref.watch(authProvider).user?.isPremium ?? true;

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
                ElevatedButton(
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
                )
              ])
            ),
          ],
        ),
      ),
    );
  }

  // New method to test Firebase connectivity by saving dummy sections
  // Test Firebase connection by saving dummy sections
  Future<void> _testFirebaseConnection() async {
    try {
      print("Starting Firebase connection test...");
      final firebaseService = ref.read(firebaseServiceProvider);

      // Create dummy sections directly here instead of accessing the private method
      final dummySections = [
        Section(
          id: 'love',
          title: 'Finding What You Love ❤️',
          description: 'Explore your deepest passions.',
          iconName: 'favorite',
          questions: [
            Question(
              id: 'q1',
              text: 'Imagine you wake up tomorrow, and you have unlimited money & time for the next 10 years. What would you spend your days doing?',
            ),
            Question(
              id: 'q2',
              text: 'A genie appears and says, "You can only do one activity for the rest of your life—but it will make you incredibly happy." What do you choose?',
            ),
          ],
          isPremium: false,
          order: 1,
        ),
        Section(
          id: 'strengths',
          title: 'Discovering Your Strengths 💪',
          description: 'Uncover your natural talents.',
          iconName: 'star',
          questions: [
            Question(
              id: 'q1',
              text: 'You are in a survival game where each person must contribute a unique skill to win. What skill do you offer?',
            ),
            Question(
              id: 'q2',
              text: 'Your closest friends need urgent help with something—something only YOU can do better than anyone else. What is it?',
            ),
          ],
          isPremium: false,
          order: 2,
        ),
        Section(
          id: 'world_needs',
          title: 'What the World Needs 🌍',
          description: 'Make a meaningful impact.',
          iconName: 'public',
          questions: [
            Question(
              id: 'q1',
              text: 'You are given the power to solve ONE major global issue instantly. What problem do you fix?',
            ),
            Question(
              id: 'q2',
              text: 'If a billionaire gave you unlimited resources to improve the world in ONE way, what would you do?',
            ),
          ],
          isPremium: false,
          order: 3,
        ),
        Section(
          id: 'paid_for',
          title: 'What You Can Be Paid For 💰',
          description: 'Turn skills into opportunities.',
          iconName: 'attach_money',
          questions: [
            Question(
              id: 'q1',
              text: 'If you were suddenly forced to earn money using ONLY your knowledge & talents, how would you do it?',
            ),
            Question(
              id: 'q2',
              text: 'A new "Talent Auction" is created where companies bid for the best skills. What skill would companies bid the highest amount for in YOU?',
            ),
          ],
          isPremium: false,
          order: 4,
        ),
      ];

      print("Created ${dummySections.length} default sections");

      // Reference to the Firestore sections collection
      final sectionsCollection = FirebaseFirestore.instance.collection('sections');

      // Save each section to Firestore
      for (var section in dummySections) {
        print("Saving section: ${section.id}");
        await sectionsCollection.doc(section.id).set({
          'id': section.id,
          'title': section.title,
          'description': section.description,
          'iconName': section.iconName,
          'questions': section.questions.map((q) => {
            'id': q.id,
            'text': q.text,
            'order': q.order,
          }).toList(),
          'isPremium': section.isPremium,
          'order': section.order,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print("Saved section: ${section.id} to Firestore");
      }

      // Refresh sections after saving
      await ref.read(questionsProvider.notifier).loadSections();
      print("Sections reloaded after saving dummy data");

      // Add this line to force a rebuild
      setState(() {});
      print("Sections reloaded after saving dummy data");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sections successfully saved to Firebase!')),
      );
    } catch (e) {
      print("Error saving sections to Firebase: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save sections: $e')),
      );
    }
  }
}