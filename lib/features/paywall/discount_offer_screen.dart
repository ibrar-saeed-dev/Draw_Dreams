import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'paywall_provider.dart';

class DiscountOfferScreen extends ConsumerStatefulWidget {
  const DiscountOfferScreen({super.key});

  @override
  ConsumerState<DiscountOfferScreen> createState() => _DiscountOfferScreenState();
}

class _DiscountOfferScreenState extends ConsumerState<DiscountOfferScreen> {
  static const _timerPrefsKey = 'discount_offer_start_timestamp';
  int _selectedPlanIndex = 0; // 0: 90% Off, 1: 50% Off
  bool _isProcessing = false;
  ProductDetails? _discountProduct;

  Timer? _timer;
  Duration _remainingTime = const Duration(minutes: 15, seconds: 0);

  @override
  void initState() {
    super.initState();
    _initPersistedCountdown();
    _fetchProducts();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Live 15-minute countdown timer
  void _initPersistedCountdown() {
    _remainingTime = const Duration(minutes: 15, seconds: 0);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _fetchProducts() async {
    final iap = InAppPurchase.instance;
    final bool available = await iap.isAvailable();
    if (available) {
      final response = await iap.queryProductDetails({'discounted_sub'});
      if (response.productDetails.isNotEmpty && mounted) {
        setState(() {
          _discountProduct = response.productDetails.first;
        });
      }
    }
  }

  void _closeScreen() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _dismissToHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _handlePurchase() async {
    setState(() => _isProcessing = true);
    final productId = 'discounted_sub';

    try {
      final iap = InAppPurchase.instance;
      final bool available = await iap.isAvailable();

      if (available && _discountProduct != null) {
        final purchaseParam = PurchaseParam(productDetails: _discountProduct!);
        await iap.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        final success = await ref
            .read(subscriptionProvider.notifier)
            .simulatePurchase(productId);
        if (success && mounted) {
          _onPurchaseSuccess();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _onPurchaseSuccess() {
    ref.read(subscriptionProvider.notifier).setPremiumStatus(true);
    _dismissToHome();
  }

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF7C3AED);
    const highlightGold = Color(0xFFFBBF24);
    const bgDark = Color(0xFF0F0F12);

    final minutesStr = (_remainingTime.inMinutes % 60).toString().padLeft(2, '0');
    final secondsStr = (_remainingTime.inSeconds % 60).toString().padLeft(2, '0');

    final plan90Price = _discountProduct?.price ?? 'Rs 89.00';
    const plan50OriginalPrice = '16,800 PKR';
    const plan50DiscountedPrice = 'Rs 8,400';

    return WillPopScope(
      onWillPop: () async {
        _closeScreen();
        return false;
      },
      child: Scaffold(
        backgroundColor: bgDark,
        body: SafeArea(
          child: _isProcessing
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryPurple),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Unlocking Pro offer...',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    // Main Content
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 40),

                          // Decorative Icon / Graphic at top (Lightning Bolt)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: highlightGold.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: highlightGold.withValues(alpha: 0.4), width: 2),
                              ),
                              child: const Icon(
                                Icons.electric_bolt_rounded,
                                size: 44,
                                color: highlightGold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Title: Unlock PRO at 90% Off!
                          RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Unlock PRO at ',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                TextSpan(
                                  text: '90% Off!',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: highlightGold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Countdown Label + Boxes
                          const Text(
                            'OFFER ENDS IN:',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildCountdownBox(minutesStr, 'MINS'),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  ':',
                                  style: TextStyle(color: primaryPurple, fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                              ),
                              _buildCountdownBox(secondsStr, 'SECS'),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Two Plan Cards Side by Side
                          Row(
                            children: [
                              Expanded(
                                child: _buildSidePlanCard(
                                  index: 0,
                                  discountBadge: '90% OFF',
                                  badgeColor: highlightGold,
                                  badgeTextColor: Colors.black,
                                  originalPrice: 'Rs 890',
                                  discountedPrice: plan90Price,
                                  period: '1 week',
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildSidePlanCard(
                                  index: 1,
                                  discountBadge: '50% OFF',
                                  badgeColor: Colors.white24,
                                  badgeTextColor: Colors.white,
                                  originalPrice: plan50OriginalPrice,
                                  discountedPrice: plan50DiscountedPrice,
                                  period: 'lifetime',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // CTA Button: "Continue" with "Cancel anytime"
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 6,
                            ),
                            onPressed: _handlePurchase,
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Cancel anytime',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Dynamic Fine Print
                          Text(
                            _selectedPlanIndex == 0
                                ? 'Billed weekly at $plan90Price • Auto-renews until cancelled'
                                : 'One-time payment of $plan50DiscountedPrice for lifetime access',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Footer Links
                          _buildFooterLinks(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),

                    // Top Close (X) Button (On top of Stack inside SafeArea)
                    Positioned(
                      top: 10,
                      right: 16,
                      child: SafeArea(
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 28),
                          onPressed: _closeScreen,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCountdownBox(String val, String label) {
    const primaryPurple = Color(0xFF7C3AED);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: primaryPurple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryPurple, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidePlanCard({
    required int index,
    required String discountBadge,
    required Color badgeColor,
    required Color badgeTextColor,
    required String originalPrice,
    required String discountedPrice,
    required String period,
  }) {
    final isSelected = _selectedPlanIndex == index;
    const primaryPurple = Color(0xFF7C3AED);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryPurple.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryPurple : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    discountBadge,
                    style: TextStyle(
                      color: badgeTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_off,
                  color: isSelected ? primaryPurple : Colors.white38,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              originalPrice,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 13,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              discountedPrice,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '/$period',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton(
          onPressed: () async {
            setState(() => _isProcessing = true);
            await ref.read(subscriptionProvider.notifier).restorePurchases();
            if (mounted) setState(() => _isProcessing = false);
          },
          child: Text(
            'Restore',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
          ),
        ),
        Text('|', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11)),
        TextButton(
          onPressed: () {},
          child: Text(
            'Terms of Use',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
          ),
        ),
        Text('|', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11)),
        TextButton(
          onPressed: () {},
          child: Text(
            'Privacy Policy',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
          ),
        ),
      ],
    );
  }
}
