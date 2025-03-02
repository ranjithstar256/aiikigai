import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/config/app_config.dart';

class IkigaiAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool showThemeSelector;
  final Widget? leading;
  final double elevation;
  final Color? backgroundColor;
  final bool centerTitle;

  const IkigaiAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.showThemeSelector = false,
    this.leading,
    this.elevation = 4.0,
    this.backgroundColor,
    this.centerTitle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AppBar(
      title: Text(
        title,
        style: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: centerTitle,
      elevation: elevation,
      backgroundColor: backgroundColor ?? theme.primaryColor,
      leading: _buildLeading(context),
      actions: _buildActions(context, ref),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) {
      return leading;
    }

    if (showBackButton) {
      return IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: onBackPressed ?? () => context.pop(),
      );
    }

    return null;
  }

  List<Widget> _buildActions(BuildContext context, WidgetRef ref) {
    final List<Widget> widgetActions = [...?actions];

    if (showThemeSelector) {
      widgetActions.add(
        PopupMenuButton<String>(
          icon: const Icon(Icons.color_lens, color: Colors.white),
          onSelected: (theme) => _handleThemeSelection(theme, ref),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: AppConfig.classicTheme,
              child: const Text("Classic Blue"),
            ),
            PopupMenuItem(
              value: AppConfig.orangeTheme,
              child: const Text("Orange Theme"),
            ),
            PopupMenuItem(
              value: AppConfig.purpleTheme,
              child: const Text("Purple Theme"),
            ),
            if (ref.watch(authProvider).user?.isPremium ?? false)
              PopupMenuItem(
                value: AppConfig.premiumTheme,
                child: const Text("Premium Gold"),
              ),
            const PopupMenuItem(
              value: "dark_mode",
              child: Text("Toggle Dark Mode"),
            ),
          ],
        ),
      );
    }

    return widgetActions;
  }

  void _handleThemeSelection(String themeName, WidgetRef ref) {
    if (themeName == "dark_mode") {
      ref.read(themeProvider.notifier).toggleDarkMode();
    } else {
      ref.read(themeProvider.notifier).setTheme(themeName);
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}