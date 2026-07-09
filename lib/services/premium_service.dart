import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'billing_service.dart';

/// App-wide premium state manager.
///
/// The local cache is used only to make startup fast. The durable entitlement
/// is restored through Google Play Billing purchase/restore events.
class PremiumService extends ChangeNotifier {
  PremiumService._();

  static final PremiumService instance = PremiumService._();

  static const String _premiumCacheKey = 'premium_lifetime_cache';

  bool _isPremium = false;
  bool _isInitialized = false;
  bool _isLoading = false;

  bool get isPremium => _isPremium;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading || BillingService.instance.isLoading;

  bool get adsDisabled => _isPremium;
  bool get premiumWallpapersUnlocked => _isPremium;
  bool get fourKWallpapersUnlocked => _isPremium;
  bool get restrictionsRemoved => _isPremium;

  /// Loads cached entitlement, then initializes Google Play Billing.
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_premiumCacheKey) ?? false;
    notifyListeners();

    await BillingService.instance.initialize(
      onPremiumVerified: _unlockFromVerifiedPurchase,
    );

    BillingService.instance.addListener(notifyListeners);
    _isInitialized = true;
    _setLoading(false);
  }

  Future<void> buyPremium() => BillingService.instance.buyPremium();

  Future<void> restorePurchases() => BillingService.instance.restorePurchases();

  /// Called only after BillingService receives and verifies a Play Billing
  /// purchased/restored transaction for premium_lifetime.
  Future<void> _unlockFromVerifiedPurchase(PurchaseDetails purchase) async {
    if (purchase.productID != BillingService.premiumLifetimeProductId) return;

    _isPremium = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumCacheKey, true);
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
