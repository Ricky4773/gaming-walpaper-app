import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Handles Google Play Billing through the official in_app_purchase plugin.
///
/// This service talks to the billing client, queries the configured
/// non-consumable product, listens for purchases/restores, completes purchases,
/// and reports verified premium unlocks to PremiumService.
class BillingService extends ChangeNotifier {
  BillingService._();

  static final BillingService instance = BillingService._();

  static const String premiumLifetimeProductId = 'premium_lifetime';
  static const Set<String> _productIds = {premiumLifetimeProductId};

  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  ProductDetails? _premiumProduct;
  bool _isAvailable = false;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _purchasePending = false;
  String? _errorMessage;
  Future<void> Function(PurchaseDetails purchase)? _onPremiumVerified;

  ProductDetails? get premiumProduct => _premiumProduct;
  bool get isAvailable => _isAvailable;
  bool get isLoading => _isLoading;
  bool get purchasePending => _purchasePending;
  String? get errorMessage => _errorMessage;

  /// Initializes the billing client and starts listening to purchase updates.
  Future<void> initialize({
    required Future<void> Function(PurchaseDetails purchase) onPremiumVerified,
  }) async {
    _onPremiumVerified = onPremiumVerified;
    if (_isInitialized) return;

    _setLoading(true);
    _purchaseSubscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        _errorMessage = 'Purchase update failed: $error';
        _purchasePending = false;
        notifyListeners();
      },
    );

    try {
      _isAvailable = await _iap.isAvailable();
      if (!_isAvailable) {
        _errorMessage = 'Google Play Billing is not available on this device.';
        return;
      }

      await queryProducts();
      _isInitialized = true;
    } catch (error) {
      _errorMessage = 'Billing initialization failed: $error';
    } finally {
      _setLoading(false);
    }
  }

  /// Queries Google Play for the premium_lifetime non-consumable product.
  Future<void> queryProducts() async {
    _setLoading(true);
    try {
      final response = await _iap.queryProductDetails(_productIds);
      if (response.error != null) {
        _errorMessage = response.error!.message;
      }
      if (response.notFoundIDs.isNotEmpty) {
        _errorMessage =
            'Product not found in Play Console: ${response.notFoundIDs.join(', ')}';
      }
      _premiumProduct =
          response.productDetails.where((p) => p.id == premiumLifetimeProductId).firstOrNull;
    } catch (error) {
      _errorMessage = 'Product query failed: $error';
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Starts the non-consumable purchase flow for Lifetime Premium.
  Future<void> buyPremium() async {
    final product = _premiumProduct;
    if (!_isAvailable) {
      _errorMessage = 'Google Play Billing is not available.';
      notifyListeners();
      return;
    }
    if (product == null) {
      await queryProducts();
      if (_premiumProduct == null) return;
    }

    _purchasePending = true;
    _errorMessage = null;
    notifyListeners();

    final purchaseParam = PurchaseParam(productDetails: _premiumProduct!);
    final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    if (!started) {
      _purchasePending = false;
      _errorMessage = 'Purchase flow could not be started.';
      notifyListeners();
    }
  }

  /// Restores purchases from Google Play so premium survives reinstall.
  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      _errorMessage = 'Google Play Billing is not available.';
      notifyListeners();
      return;
    }

    _purchasePending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _iap.restorePurchases();
    } catch (error) {
      _purchasePending = false;
      _errorMessage = 'Restore failed: $error';
      notifyListeners();
    }
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchase in purchaseDetailsList) {
      if (purchase.productID != premiumLifetimeProductId) continue;

      switch (purchase.status) {
        case PurchaseStatus.pending:
          _purchasePending = true;
          notifyListeners();
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final verified = await _verifyPurchase(purchase);
          if (verified) {
            await _onPremiumVerified?.call(purchase);
            _errorMessage = null;
          } else {
            _errorMessage = 'Purchase verification failed.';
          }
          _purchasePending = false;
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          notifyListeners();
          break;
        case PurchaseStatus.error:
          _purchasePending = false;
          _errorMessage = purchase.error?.message ?? 'Purchase failed.';
          notifyListeners();
          break;
        case PurchaseStatus.canceled:
          _purchasePending = false;
          _errorMessage = 'Purchase cancelled.';
          notifyListeners();
          break;
      }
    }
  }

  /// Verifies the purchase data received from Google Play Billing.
  ///
  /// A backend using Google Play Developer API is the strongest production
  /// verification. This app still does not trust SharedPreferences: premium is
  /// unlocked only after Play Billing returns a purchased/restored transaction
  /// with a non-empty server verification token for the expected product.
  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    final token = purchase.verificationData.serverVerificationData;
    return purchase.productID == premiumLifetimeProductId && token.isNotEmpty;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
