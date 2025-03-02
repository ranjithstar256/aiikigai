import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/insight.dart';

class InsightCard extends ConsumerWidget {
  final String title;
  final List<String> items;
  final IconData icon;
  final bool isPremium;
  final bool useNumbering;
  final VoidCallback? onTap;
  final bool expanded;
  final bool isLoading;

  const InsightCard({
    Key? key,
    required this.title,
    required this.items,
    required this.icon,
    this.isPremium = false,
    this.useNumbering = false,
    this.onTap,
    this.expanded = false,
    this.isLoading = false,
  }) : super(key: key);

  // Factory constructor to create from insight data
  factory InsightCard.fromInsightField({
    required String title,
    required List<String> items,
    required IconData icon,
    bool isPremium = false,
    bool useNumbering = false,
    VoidCallback? onTap,
    bool expanded = false,
  }) {
    return InsightCard(
      title: title,
      items: items,
      icon: icon,
      isPremium: isPremium,
      useNumbering: useNumbering,
      onTap: onTap,
      expanded: expanded,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Card gradient colors
    final List<Color> gradientColors = isPremium
        ? [
      const Color(0xFFD4AF37).withOpacity(0.3),
      const Color(0xFFFFDF00).withOpacity(0.1),
    ]
        : [
      theme.colorScheme.primary.withOpacity(0.2),
      theme.colorScheme.primary.withOpacity(0.05),
    ];

    return Card(
      elevation: theme.brightness == Brightness.dark ? 4 : 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: isPremium
              ? Border.all(
            color: const Color(0xFFD4AF37).withOpacity(0.3),
            width: 1.5,
          )
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with title and icon
                  Row(
                    children: [
                      Icon(
                        icon,
                        color: isPremium
                            ? const Color(0xFFD4AF37)
                            : theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isPremium
                                ? const Color(0xFFD4AF37)
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      if (isPremium)
                        Icon(
                          Icons.workspace_premium,
                          color: const Color(0xFFD4AF37),
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Loading state
                  if (isLoading)
                    Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isPremium
                                  ? const Color(0xFFD4AF37)
                                  : theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Generating insights...',
                            style: GoogleFonts.lato(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    )

                  // Empty state
                  else if (items.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'No data available',
                          style: GoogleFonts.lato(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    )

                  // Content items
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show all items if expanded, otherwise show only first 2
                        ...List.generate(
                          expanded ? items.length : items.length.clamp(0, 2),
                              (index) => _buildItem(context, items[index], index),
                        ),

                        // Show "See more" if not expanded and there are more items
                        if (!expanded && items.length > 2)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Center(
                              child: TextButton.icon(
                                onPressed: onTap,
                                icon: const Icon(Icons.expand_more),
                                label: const Text('See more'),
                                style: TextButton.styleFrom(
                                  foregroundColor: isPremium
                                      ? const Color(0xFFD4AF37)
                                      : theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, String text, int index) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bullet point or number
          SizedBox(
            width: 25,
            child: Text(
              useNumbering ? '${index + 1}.' : '•',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isPremium
                    ? const Color(0xFFD4AF37)
                    : theme.colorScheme.primary,
              ),
            ),
          ),

          // Item text
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.lato(
                fontSize: 15,
                height: 1.4,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}