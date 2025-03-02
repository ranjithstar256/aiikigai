import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Base card with consistent styling
class BaseCard extends StatelessWidget {
  final Widget child;
  final double elevation;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius? borderRadius;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final Border? border;

  const BaseCard({
    Key? key,
    required this.child,
    this.elevation = 4,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    this.borderRadius,
    this.color,
    this.gradient,
    this.onTap,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = borderRadius ?? BorderRadius.circular(16);

    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: color ?? (gradient != null ? null : theme.cardColor),
        gradient: gradient,
        border: border,
      ),
      child: child,
    );

    if (onTap != null) {
      return Card(
        elevation: elevation,
        shape: RoundedRectangleBorder(borderRadius: radius),
        margin: margin,
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: cardContent,
          ),
        ),
      );
    }

    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(borderRadius: radius),
      margin: margin,
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: cardContent,
    );
  }
}

/// Feature card with icon, title, and description
class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;
  final Gradient? gradient;
  final bool isPremium;

  const FeatureCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.iconColor,
    this.titleColor,
    this.gradient,
    this.isPremium = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final effectiveIconColor = isPremium
        ? const Color(0xFFD4AF37)
        : iconColor ?? theme.primaryColor;

    final effectiveTitleColor = isPremium
        ? const Color(0xFFD4AF37)
        : titleColor ?? theme.colorScheme.primary;

    final effectiveGradient = gradient ?? (isPremium
        ? LinearGradient(
      colors: [
        const Color(0xFFD4AF37).withOpacity(0.2),
        const Color(0xFFD4AF37).withOpacity(0.05),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    )
        : null);

    final effectiveBorder = isPremium
        ? Border.all(
      color: const Color(0xFFD4AF37).withOpacity(0.3),
      width: 1.5,
    )
        : null;

    return BaseCard(
      gradient: effectiveGradient,
      onTap: onTap,
      border: effectiveBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: effectiveIconColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: effectiveTitleColor,
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
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.lato(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Information card with title and content
class InfoCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData? icon;
  final Color? accentColor;
  final VoidCallback? onTap;

  const InfoCard({
    Key? key,
    required this.title,
    required this.content,
    this.icon,
    this.accentColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.primaryColor;

    return BaseCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with optional icon
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: color),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: color.withOpacity(0.2)),
          ),

          // Content
          Text(
            content,
            style: GoogleFonts.lato(
              fontSize: 14,
              height: 1.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status card with color-coded status and content
class StatusCard extends StatelessWidget {
  final String title;
  final String status;
  final StatusType statusType;
  final String? description;
  final VoidCallback? onAction;
  final String? actionLabel;

  const StatusCard({
    Key? key,
    required this.title,
    required this.status,
    required this.statusType,
    this.description,
    this.onAction,
    this.actionLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get status color based on type
    final Color statusColor = _getStatusColor(theme);

    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),

          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(),
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),

          // Description if provided
          if (description != null) ...[
            const SizedBox(height: 12),
            Text(
              description!,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],

          // Action button if provided
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: statusColor,
                ),
                child: Text(
                  actionLabel!,
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(ThemeData theme) {
    switch (statusType) {
      case StatusType.success:
        return Colors.green;
      case StatusType.warning:
        return Colors.amber;
      case StatusType.error:
        return Colors.red;
      case StatusType.info:
        return theme.primaryColor;
      case StatusType.pending:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon() {
    switch (statusType) {
      case StatusType.success:
        return Icons.check_circle;
      case StatusType.warning:
        return Icons.warning;
      case StatusType.error:
        return Icons.error;
      case StatusType.info:
        return Icons.info;
      case StatusType.pending:
        return Icons.pending;
    }
  }
}

/// Status types for StatusCard
enum StatusType {
  success,
  warning,
  error,
  info,
  pending,
}