import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user.dart';

class SubscriptionCard extends ConsumerWidget {
  final SubscriptionTier tier;
  final bool isSelected;
  final bool isCurrentPlan;
  final VoidCallback onSelect;
  final VoidCallback onSubscribe;

  const SubscriptionCard({
    Key? key,
    required this.tier,
    required this.isSelected,
    this.isCurrentPlan = false,
    required this.onSelect,
    required this.onSubscribe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Determine card styling based on tier and selection state
    final isGold = tier == SubscriptionTier.premium || tier == SubscriptionTier.premiumYearly;

    final baseColor = isGold
        ? const Color(0xFFD4AF37)
        : tier == SubscriptionTier.basic
        ? theme.primaryColor
        : Colors.grey.shade700;

    final cardColor = isSelected
        ? baseColor.withOpacity(0.15)
        : theme.brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.white;

    final borderColor = isSelected
        ? baseColor
        : theme.brightness == Brightness.dark
        ? Colors.grey.shade700
        : Colors.grey.shade300;

    // Convert subscription tier to readable strings
    final tierName = tier.name;
    final price = tier.price;
    final features = tier.features;

    // Popular tag for yearly plan
    final isPopular = tier == SubscriptionTier.premiumYearly;

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: baseColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Stack(
          children: [
            // Popular tag
            if (isPopular)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                  child: Text(
                    'BEST VALUE',
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

            // Current plan indicator
            if (isCurrentPlan)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'CURRENT PLAN',
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Tier icon
                      Icon(
                        _getTierIcon(),
                        color: baseColor,
                        size: 28,
                      ),
                      const SizedBox(width: 12),

                      // Tier name
                      Expanded(
                        child: Text(
                          tierName,
                          style: GoogleFonts.playfairDisplay(
                            color: baseColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),

                      // Selected indicator
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: baseColor,
                          size: 24,
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Price
                  Text(
                    price,
                    style: GoogleFonts.lato(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Features list
                  ...features.map((feature) => _buildFeatureItem(context, feature, baseColor)),

                  const SizedBox(height: 20),

                  // CTA button - only show if selected
                  if (isSelected && !isCurrentPlan)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onSubscribe,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: baseColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Text(
                          tier == SubscriptionTier.free ? 'Current Plan' : 'Subscribe',
                          style: GoogleFonts.lato(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                  // Current plan indicator
                  if (isCurrentPlan)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      alignment: Alignment.center,
                      child: Text(
                        'Your Current Plan',
                        style: GoogleFonts.lato(
                          color: baseColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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

  IconData _getTierIcon() {
    switch (tier) {
      case SubscriptionTier.free:
        return Icons.star_border;
      case SubscriptionTier.basic:
        return Icons.star_half;
      case SubscriptionTier.premium:
      case SubscriptionTier.premiumYearly:
        return Icons.workspace_premium;
    }
  }

  Widget _buildFeatureItem(BuildContext context, String text, Color color) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.lato(
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}