import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/services/analytics_service.dart';
import '../../data/services/in_app_purchase_service.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/premium/subscription_card.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  SubscriptionTier _selectedTier = SubscriptionTier.premium;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Log page view
    ref.read(analyticsServiceProvider).logScreenView('subscription_screen');

    // Initialize in-app purchases
    _initializePurchases();
  }

  Future<void> _initializePurchases() async {
    final inAppPurchase = ref.read(inAppPurchaseServiceProvider);

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load products
      await inAppPurchase.loadProducts();

      // Listen to purchase updates
      inAppPurchase.purchaseStatusStream.listen((status) {
        switch (status) {
          case PurchaseStatus.pending:
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
            break;
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            setState(() {
              _isLoading = false;
              _errorMessage = null;
            });
            // Show success message
            _showSuccessDialog();
            break;
          case PurchaseStatus.canceled:
            setState(() {
              _isLoading = false;
              _errorMessage = null;
            });
            break;
          case PurchaseStatus.error:
            setState(() {
              _isLoading = false;
              _errorMessage = 'An error occurred. Please try again.';
            });
            break;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load subscription plans: $e';
      });
    }
  }

  void _selectTier(SubscriptionTier tier) {
    setState(() {
      _selectedTier = tier;
    });
  }

  Future<void> _subscribe() async {
    if (_selectedTier == SubscriptionTier.free) {
      // Can't subscribe to free tier
      return;
    }

    final inAppPurchase = ref.read(inAppPurchaseServiceProvider);
    final auth = ref.read(authProvider);

    // Check if user is logged in
    if (!auth.isLoggedIn) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Log event
      ref.read(analyticsServiceProvider).logEvent(
        'start_subscription',
        parameters: {
          'tier': _selectedTier.name,
        },
      );

      // Get product ID based on selected tier
      String productId;
      switch (_selectedTier) {
        case SubscriptionTier.basic:
          productId = 'ikigai_basic_monthly';
          break;
        case SubscriptionTier.premium:
          productId = 'ikigai_premium_monthly';
          break;
        case SubscriptionTier.premiumYearly:
          productId = 'ikigai_premium_yearly';
          break;
        default:
          throw Exception('Invalid subscription tier');
      }

      // Get product details
      final product = inAppPurchase.getProductById(productId);

      if (product == null) {
        throw Exception('Product not found: $productId');
      }

      // Initiate purchase
      await inAppPurchase.buyProduct(product);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initiate purchase: $e';
      });
    }
  }

  Future<void> _restorePurchases() async {
    final inAppPurchase = ref.read(inAppPurchaseServiceProvider);

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Log event
      ref.read(analyticsServiceProvider).logEvent('restore_purchases');

      await inAppPurchase.restorePurchases();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to restore purchases: $e';
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subscription Successful'),
        content: const Text(
          'Thank you for subscribing! You now have access to premium features.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;
    final currentTier = user?.subscriptionTier ?? SubscriptionTier.free;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Subscription Plans',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                backgroundBlendMode: BlendMode.overlay,
                image: DecorationImage(
                  image: AssetImage(
                    theme.brightness == Brightness.dark
                        ? 'assets/images/pattern_dark.png'
                        : 'assets/images/pattern_light.png',
                  ),
                  fit: BoxFit.cover,
                  opacity: 0.05,
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal:
                      24),
                      child: Text(
                        'Choose Your Ikigai Journey',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Unlock premium features to deepen your self-discovery and find your purpose.',
                        style: GoogleFonts.lato(
                          fontSize: 15,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error message if any
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Card(
                          color: theme.colorScheme.error.withOpacity(0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.lato(
                                color: theme.colorScheme.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),

                    // Subscription cards
                    SubscriptionCard(
                      tier: SubscriptionTier.free,
                      isSelected: _selectedTier == SubscriptionTier.free,
                      isCurrentPlan: currentTier == SubscriptionTier.free,
                      onSelect: () => _selectTier(SubscriptionTier.free),
                      onSubscribe: () {}, // No action for free tier
                    ),
                    SubscriptionCard(
                      tier: SubscriptionTier.basic,
                      isSelected: _selectedTier == SubscriptionTier.basic,
                      isCurrentPlan: currentTier == SubscriptionTier.basic,
                      onSelect: () => _selectTier(SubscriptionTier.basic),
                      onSubscribe: _subscribe,
                    ),
                    SubscriptionCard(
                      tier: SubscriptionTier.premium,
                      isSelected: _selectedTier == SubscriptionTier.premium,
                      isCurrentPlan: currentTier == SubscriptionTier.premium,
                      onSelect: () => _selectTier(SubscriptionTier.premium),
                      onSubscribe: _subscribe,
                    ),
                    SubscriptionCard(
                      tier: SubscriptionTier.premiumYearly,
                      isSelected: _selectedTier == SubscriptionTier.premiumYearly,
                      isCurrentPlan: currentTier == SubscriptionTier.premiumYearly,
                      onSelect: () => _selectTier(SubscriptionTier.premiumYearly),
                      onSubscribe: _subscribe,
                    ),

                    // Restore purchases button
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: TextButton(
                        onPressed: _isLoading ? null : _restorePurchases,
                        child: Text(
                          'Restore Purchases',
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),

                    // Terms and privacy
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'By subscribing, you agree to our Terms of Service and Privacy Policy. '
                            'Subscriptions will automatically renew unless canceled at least 24 hours before the end of the current period.',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}