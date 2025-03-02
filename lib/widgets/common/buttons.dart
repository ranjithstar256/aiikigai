import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Primary button with rounded corners and optional icon
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final Color? backgroundColor;
  final Color? textColor;

  const PrimaryButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 50.0,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: textColor ?? Colors.white,
          backgroundColor: backgroundColor ?? theme.primaryColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: icon != null ? 20.0 : 24.0,
            vertical: 12.0,
          ),
        ),
        child: isLoading
            ? SizedBox(
          width: 24.0,
          height: 24.0,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(
              textColor ?? Colors.white,
            ),
          ),
        )
            : Row(
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20.0),
              const SizedBox(width: 8.0),
            ],
            Text(
              text,
              style: GoogleFonts.lato(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Secondary button with outline and optional icon
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final Color? borderColor;
  final Color? textColor;

  const SecondaryButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 50.0,
    this.borderColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? theme.primaryColor,
          side: BorderSide(
            color: borderColor ?? theme.primaryColor,
            width: 2.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: icon != null ? 20.0 : 24.0,
            vertical: 12.0,
          ),
        ),
        child: isLoading
            ? SizedBox(
          width: 24.0,
          height: 24.0,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(
              textColor ?? theme.primaryColor,
            ),
          ),
        )
            : Row(
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20.0),
              const SizedBox(width: 8.0),
            ],
            Text(
              text,
              style: GoogleFonts.lato(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Social login button for platforms like Google, Facebook, etc.
class SocialButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Widget logo;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final Color backgroundColor;
  final Color textColor;

  const SocialButton({
    Key? key,
    required this.text,
    required this.onPressed,
    required this.logo,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 50.0,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black87,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: textColor,
          backgroundColor: backgroundColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 12.0,
          ),
        ),
        child: isLoading
            ? SizedBox(
          width: 24.0,
          height: 24.0,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(textColor),
          ),
        )
            : Row(
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24.0,
              height: 24.0,
              child: logo,
            ),
            const SizedBox(width: 12.0),
            Text(
              text,
              style: GoogleFonts.lato(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Factory constructor for Google button
  factory SocialButton.google({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return SocialButton(
      text: text,
      onPressed: onPressed,
      logo: Image.asset('assets/images/google_logo.png'),
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }

  // Factory constructor for Facebook button
  factory SocialButton.facebook({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return SocialButton(
      text: text,
      onPressed: onPressed,
      logo: Image.asset('assets/images/facebook_logo.png'),
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      backgroundColor: const Color(0xFF1877F2),
      textColor: Colors.white,
    );
  }

  // Factory constructor for Apple button
  factory SocialButton.apple({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return SocialButton(
      text: text,
      onPressed: onPressed,
      logo: Image.asset('assets/images/apple_logo.png'),
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      backgroundColor: Colors.black,
      textColor: Colors.white,
    );
  }
}

/// Icon button with text displayed below the icon
class IconTextButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;
  final Color? iconColor;
  final Color? textColor;
  final double iconSize;
  final double textSize;

  const IconTextButton({
    Key? key,
    required this.icon,
    required this.text,
    required this.onPressed,
    this.iconColor,
    this.textColor,
    this.iconSize = 24.0,
    this.textSize = 12.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: iconColor ?? theme.primaryColor,
              size: iconSize,
            ),
            const SizedBox(height: 4.0),
            Text(
              text,
              style: GoogleFonts.lato(
                fontSize: textSize,
                color: textColor ?? theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating action button with extended label
class ExtendedFab extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ExtendedFab({
    Key? key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(
        label,
        style: GoogleFonts.lato(
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: backgroundColor ?? theme.primaryColor,
      foregroundColor: foregroundColor ?? Colors.white,
    );
  }
}