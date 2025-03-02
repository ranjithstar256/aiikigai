import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/utils/error_handler.dart';
import '../../models/user.dart';
import '../repositories/user_repository.dart';

/// Provider for the In-App Purchase Service
final inAppPurchaseServiceProvider = Provider<InAppPurchaseService>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return InAppPurchaseService(userRepository);
});

/// Service for handling in-app purchases
class InAppPurchaseService {
  final UserRepository _userRepository;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  // Stream controllers
  final StreamController<List<ProductDetails>> _productsStreamController =
  StreamController<List<ProductDetails>>.broadcast();
  final StreamController<PurchaseStatus> _purchaseStatusStreamController =
  StreamController<PurchaseStatus>.broadcast();

  // State variables
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  bool _isAvailable = false;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  // Product IDs
  static const Set<String> _productIds = {
    'ikigai_basic_monthly',
    'ikigai_premium_monthly',
    'ikigai_premium_yearly',
  };

  // Constructor
  InAppPurchaseService(this._userRepository) {
    // Initialize service if not on web
    if (!kIsWeb) {
      _initialize();
    }
  }

  // Getters
  Stream<List<ProductDetails>> get productsStream => _productsStreamController.stream;
  Stream<PurchaseStatus> get purchaseStatusStream => _purchaseStatusStreamController.stream;
  List<ProductDetails> get products => _products;
  List<PurchaseDetails> get purchases => _purchases;
  bool get isAvailable => _isAvailable;

  // Initialize the service
  Future<void> _initialize() async {
    final bool available = await _inAppPurchase.isAvailable();
    _isAvailable = available;

    if (!available) {
      _productsStreamController.add([]);
      return;
    }

    // Configure the service for each platform
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
      _inAppPurchase.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(null);
    }

    // Listen to purchase updates
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        _purchaseStatusStreamController.add(PurchaseStatus.error);
      },
    );

    // Load products
    await loadProducts();
  }

  // Load available products
  Future<List<ProductDetails>> loadProducts() async {
    try {
      if (!_isAvailable || kIsWeb) {
        return [];
      }

      final ProductDetailsResponse response =
      await _inAppPurchase.queryProductDetails(_productIds);

      if (response.notFoundIDs.isNotEmpty) {
        print('Products not found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      _productsStreamController.add(_products);

      return _products;
    } catch (e) {
      throw AppException('Failed to load products: $e', original: e);
    }
  }

  // Get product details by ID
  ProductDetails? getProductById(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  // Make a purchase
  Future<void> buyProduct(ProductDetails product) async {
    try {
      if (!_isAvailable || kIsWeb) {
        throw AppException('In-app purchases are not available');
      }

      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);

      if (product.id.contains('_monthly') || product.id.contains('_yearly')) {
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      throw AppException('Failed to initiate purchase: $e', original: e);
    }
  }

  // Restore purchases
  Future<void> restorePurchases() async {
    try {
      if (!_isAvailable || kIsWeb) {
        throw AppException('In-app purchases are not available');
      }

      await _inAppPurchase.restorePurchases();
    } catch (e) {
      throw AppException('Failed to restore purchases: $e', original: e);
    }
  }

  // Handle purchase updates
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    _purchases = purchaseDetailsList;

    for (var purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _purchaseStatusStreamController.add(PurchaseStatus.pending);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndDeliverPurchase(purchaseDetails);
          break;
        case PurchaseStatus.error:
          print('Purchase error: ${purchaseDetails.error!.message}');
          _purchaseStatusStreamController.add(PurchaseStatus.error);
          break;
        case PurchaseStatus.canceled:
          _purchaseStatusStreamController.add(PurchaseStatus.canceled);
          break;
      }

      // Mark purchase as complete if needed
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  // Verify and deliver a purchase
  Future<void> _verifyAndDeliverPurchase(PurchaseDetails purchase) async {
    try {
      // Verify receipt (in production you might want to verify with server)
      // Here we're just assuming it's valid

      // Get current user
      final currentUser = await _userRepository.getCurrentUser();

      if (currentUser == null) {
        throw AppException('User not logged in');
      }

      // Determine subscription tier and expiry based on the product ID
      SubscriptionTier tier;
      DateTime? expiryDate;

      switch (purchase.productID) {
        case 'ikigai_basic_monthly':
          tier = SubscriptionTier.basic;
          expiryDate = DateTime.now().add(const Duration(days: 30));
          break;
        case 'ikigai_premium_monthly':
          tier = SubscriptionTier.premium;
          expiryDate = DateTime.now().add(const Duration(days: 30));
          break;
        case 'ikigai_premium_yearly':
          tier = SubscriptionTier.premiumYearly;
          expiryDate = DateTime.now().add(const Duration(days: 365));
          break;
        default:
          throw AppException('Unknown product: ${purchase.productID}');
      }

      // Update user subscription
      await _userRepository.updateSubscription(
        userId: currentUser.id,
        tier: tier,
        expiryDate: expiryDate,
      );

      _purchaseStatusStreamController.add(PurchaseStatus.purchased);
    } catch (e) {
      print('Error verifying purchase: $e');
      _purchaseStatusStreamController.add(PurchaseStatus.error);
    }
  }

  // Dispose resources
  void dispose() {
    _purchaseSubscription?.cancel();
    _productsStreamController.close();
    _purchaseStatusStreamController.close();
  }
}