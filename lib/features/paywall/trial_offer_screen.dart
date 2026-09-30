import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../app/router.dart';
import 'paywall_provider.dart';

class TrialOfferScreen extends ConsumerStatefulWidget {
  const TrialOfferScreen({super.key});

  @override
  ConsumerState<TrialOfferScreen> createState() => _TrialOfferScreenState();
}

class _TrialOfferScreenState extends ConsumerState<TrialOfferScreen> {
  int _selectedOptionIndex = 0; // 0: FREE / 3 days, 1: Paid / 1 week
  bool _remindMe = false;
  bool _isProcessing = false;
  ProductDetails? _weeklyProduct;

  @override
  void initState() {
    super.initState() ;
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final iap = InAppPurchase.instance;
    final bool available = await iap.isAvailable();
    if (available) {
      final response = await iap.queryProductDetails({'weekly_sub'});
      if (response.productDetails.isNotEmpty && mounted) {
        setState(() {
          _weeklyProduct = response.productDetails.first;
        });
      }
    }
  }

  void _dismissScreen() {
    Navigator.of(context).pushReplacementNamed(AppRouter.discountOffer);
  }

  Future<void> _handlePurchase() async {
    setState(() => _isProcessing = true);
    final String productId = 'weekly_sub';

    try {
      final iap = InAppPurchase.instance;
      final bool available = await iap.isAvailable();

      if (available && _weeklyProduct != null) {
        final purchaseParam = PurchaseParam(productDetails: _weeklyProduct!);
        await iap.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        // Fallback simulation for emulator / dev testing
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
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    // Primary Purple accent matching theme #7C3AED / #BB86FC
    const primaryPurple = Color(0xFF7C3AED);
    const bgDark = Color(0xFF0F0F12);

    final weeklyPrice = _weeklyProduct?.price ?? 'Rs 890.00';
    final isFreeTrialSelected = _selectedOptionIndex == 0;

    return WillPopScope(
      onWillPop: () async {
        _dismissScreen();
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
                        'Processing your trial request...',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    // Main Scrollable Body
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 50),

                          // Hero Image Graphic
                          Center(
                            child: Container(
                              height: 140,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: primaryPurple.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: primaryPurple.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: const BoxDecoration(
                                      color: primaryPurple,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.auto_awesome,
                                      size: 36,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'AR Tracing & AI Studio',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Title
                          const Text(
                            'Design your trial',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Subtitle
                          Text(
                            'Create from any photo or AI • Easy step-by-step • Unlimited templates',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.6),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Two Selectable Option Cards
                          _buildOptionCard(
                            index: 0,
                            title: 'FREE / 3 days',
                            subtitle: '3 days free, then $weeklyPrice / week',
                            badge: 'RECOMMENDED',
                          ),
                          const SizedBox(height: 10),
                          _buildOptionCard(
                            index: 1,
                            title: '$weeklyPrice / 1 week',
                            subtitle: 'Billed weekly • Cancel anytime',
                            badge: null,
                          ),
                          const SizedBox(height: 16),

                          // Toggle Row: Remind me before trial ends
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.notifications_active_outlined, color: primaryPurple, size: 18),
                                    SizedBox(width: 10),
                                    Text(
                                      'Remind me before trial ends',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                Switch.adaptive(
                                  value: _remindMe,
                                  activeColor: primaryPurple,
                                  onChanged: (val) {
                                    setState(() {
                                      _remindMe = val;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Trust Line
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.verified_user_outlined, color: Color(0xFF22C55E), size: 15),
                              SizedBox(width: 6),
                              Text(
                                'No payment. Cancel anytime.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Large CTA Button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 6,
                            ),
                            onPressed: _handlePurchase,
                            child: Text(
                              isFreeTrialSelected
                                  ? 'Redeem 3 days for PKR 0.00'
                                  : 'Start 1 Week for $weeklyPrice',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Dynamic Fine Print
                          Text(
                            isFreeTrialSelected
                                ? '3 days free, then $weeklyPrice / week'
                                : 'Recurring billing • Cancel anytime in store settings',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Footer Links
                          _buildFooterLinks(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),

                    // Top Close (X) Button (On top of Stack so tap registers)
                    Positioned(
                      top: 10,
                      right: 16,
                      child: SafeArea(
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 28),
                          onPressed: _dismissScreen,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required int index,
    required String title,
    required String subtitle,
    required String? badge,
  }) {
    final isSelected = _selectedOptionIndex == index;
    const primaryPurple = Color(0xFF7C3AED);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOptionIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? primaryPurple : Colors.white38,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryPurple,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12,
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
