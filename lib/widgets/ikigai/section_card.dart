import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/section.dart';
import '../../providers/auth_provider.dart';

class SectionCard extends ConsumerWidget {
  final Section section;
  final bool isCompleted;
  final VoidCallback onTap;

  const SectionCard({
    Key? key,
    required this.section,
    required this.isCompleted,
    required this.onTap,
  }) : super(key: key);

  List<Color> _getGradientColors(BuildContext context, Color primaryColor) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (section.isPremium) {
      return [
        const Color(0xFFD4AF37).withOpacity(isDarkMode ? 0.3 : 0.2),
        const Color(0xFFE8C36D).withOpacity(isDarkMode ? 0.2 : 0.1),
      ];
    }

    if (primaryColor == Colors.deepOrange) {
      return [
        Colors.deepOrange.shade100.withOpacity(isDarkMode ? 0.3 : 1.0),
        Colors.deepOrange.shade50.withOpacity(isDarkMode ? 0.2 : 1.0),
      ];
    }

    if (primaryColor == Colors.deepPurple) {
      return [
        Colors.deepPurple.shade100.withOpacity(isDarkMode ? 0.3 : 1.0),
        Colors.deepPurple.shade50.withOpacity(isDarkMode ? 0.2 : 1.0),
      ];
    }

    if (primaryColor == Colors.blueAccent) {
      return [
        Colors.blue.shade100.withOpacity(isDarkMode ? 0.3 : 1.0),
        Colors.blue.shade50.withOpacity(isDarkMode ? 0.2 : 1.0),
      ];
    }

    if (primaryColor == Colors.black) {
      return [
        Colors.grey.shade900,
        Colors.grey.shade800,
      ];
    }

    return [
      Colors.blue.shade100.withOpacity(isDarkMode ? 0.3 : 1.0),
      Colors.blue.shade50.withOpacity(isDarkMode ? 0.2 : 1.0),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPremiumUser = ref.watch(authProvider).user?.isPremium ?? false;

    // Check if section is locked
    final isLocked = section.isPremium && !isPremiumUser;

    return GestureDetector(
      onTap: isLocked ? _showUpgradeDialog(context) : onTap,
      child: Card(
        elevation: theme.brightness == Brightness.dark ? 4 : 8,
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: theme.brightness == Brightness.dark ? Colors.grey.shade800 : null,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _getGradientColors(context, theme.primaryColor),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Section icon
              Icon(
                section.icon,
                size: 30,
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : theme.primaryColor,
              ),
              const SizedBox(width: 16),

              // Section info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Section title
                        Expanded(
                          child: Text(
                            section.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontFamily: GoogleFonts.lato().fontFamily,
                              fontWeight: FontWeight.bold,
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white
                                  : theme.primaryColor,
                            ),
                          ),
                        ),

                        // Premium icon or completed icon
                        if (section.isPremium)
                          Icon(
                            Icons.workspace_premium,
                            color: isPremiumUser
                                ? const Color(0xFFD4AF37)
                                : Colors.grey,
                            size: 20,
                          )
                        else if (isCompleted)
                          Icon(
                            Icons.check_circle,
                            color: theme.brightness == Brightness.dark
                                ? Colors.white
                                : theme.primaryColor,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Section description
                    Text(
                      section.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: GoogleFonts.lato().fontFamily,
                        color: theme.brightness == Brightness.dark
                            ? Colors.white70
                            : null,
                      ),
                    ),

                    // Locked message
                    if (isLocked)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '🔒 Upgrade to premium to unlock',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : theme.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Function() _showUpgradeDialog(BuildContext context) {
    return () {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Premium Feature'),
          content: const Text(
            'This section is available exclusively to premium subscribers. '
                'Upgrade to access premium sections and get deeper insights into your Ikigai.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/subscription');
              },
              child: const Text('See Premium Plans'),
            ),
          ],
        ),
      );
    };
  }
}