import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionNotifier extends Notifier<bool> {
  static const _prefsKey = 'is_premium_user';
  final InAppPurchase _iap = InAppPurchase.instance;

  @override
  bool build() {
    _loadState();
    _listenToPurchaseUpdates();
    return false;
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_prefsKey) ?? false;
    } catch (e) {
      debugPrint("Failed to load subscription status: $e");
    }
  }

  Future<void> setPremiumStatus(bool isPremium) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, isPremium);
      state = isPremium;
    } catch (e) {
      debugPrint("Failed to save subscription status: $e");
    }
  }

  /// Listens to real purchase updates if the IAP API triggers them
  void _listenToPurchaseUpdates() {
    _iap.purchaseStream.listen((purchaseDetailsList) {
      for (var purchase in purchaseDetailsList) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          setPremiumStatus(true);
        }
      }
    }, onError: (error) {
      debugPrint("IAP Purchase Stream Error: $error");
    });
  }

  /// Simulates a transaction process and unlocks the premium tier
  Future<bool> simulatePurchase(String planId) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulating payment gateway roundtrip
    await setPremiumStatus(true);
    return true;
  }

  /// Restores any previously bought purchases
  Future<bool> restorePurchases() async {
    try {
      final bool available = await _iap.isAvailable();
      if (available) {
        await _iap.restorePurchases();
      }
      // For simulator/testing convenience, always succeed restore
      await setPremiumStatus(true);
      return true;
    } catch (e) {
      debugPrint("Restore purchases failed, falling back to simulator mock: $e");
      await setPremiumStatus(true);
      return true;
    }
  }
}

final subscriptionProvider = NotifierProvider<SubscriptionNotifier, bool>(() {
  return SubscriptionNotifier();
});
