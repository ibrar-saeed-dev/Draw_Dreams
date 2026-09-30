import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'paywall_provider.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  int _selectedPlanIndex = 1; // Default to Monthly plan
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'weekly_sub',
      'title': 'Weekly Access',
      'price': '\$2.99',
      'period': 'week',
      'badge': null,
    },
    {
      'id': 'monthly_sub',
      'title': 'Monthly Membership',
      'price': '\$7.99',
      'period': 'month',
      'badge': 'MOST POPULAR',
    },
    {
      'id': 'lifetime_sub',
      'title': 'Lifetime Artist',
      'price': '\$29.99',
      'period': 'one-time',
      'badge': 'BEST VALUE',
    },
  ];

  Future<void> _subscribe() async {
    setState(() => _isProcessing = true);
    final plan = _plans[_selectedPlanIndex];
    
    try {
      final success = await ref
          .read(subscriptionProvider.notifier)
          .simulatePurchase(plan['id'] as String);

      if (success && mounted) {
        _showSuccessDialog();
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

  Future<void> _restore() async {
    setState(() => _isProcessing = true);
    try {
      final success = await ref.read(subscriptionProvider.notifier).restorePurchases();
      if (success && mounted) {
        _showSuccessDialog(title: 'Purchases Restored!');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessDialog({String title = 'Welcome to PRO!'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16161A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white10),
        ),
        title: Row(
          children: [
            const Icon(Icons.stars, color: Color(0xFFBB86FC)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'All premium features, custom outlines, and overlays are now completely unlocked.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss dialog
              Navigator.of(context).pop(); // Exit paywall screen
            },
            child: const Text(
              'Start Creating',
              style: TextStyle(color: Color(0xFFBB86FC), fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12).withValues(alpha: 0.95),
      body: SafeArea(
        child: _isProcessing
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBB86FC)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Processing your transaction...',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  // Dismiss button (Top Right)
                  Positioned(
                    top: 10,
                    right: 16,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                  // Main Scrolling Paywall Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 50),
                        // Stars icon
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFBB86FC).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.stars_outlined, size: 36, color: Color(0xFFBB86FC)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text(
                            'Unlock AR Trace Pro',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'Take your drawing and tracing skills to the next level',
                            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.45)),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Features list
                        _buildFeatureRow(Icons.check_circle, 'Unlimited access to all 50+ templates'),
                        const SizedBox(height: 12),
                        _buildFeatureRow(Icons.check_circle, 'AI-powered custom photo outline converter'),
                        const SizedBox(height: 12),
                        _buildFeatureRow(Icons.check_circle, 'Cloud backup & drawing accuracy analytics'),
                        const SizedBox(height: 32),

                        // Plans List
                        Expanded(
                          child: ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _plans.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final plan = _plans[index];
                              final isSelected = _selectedPlanIndex == index;
                              return _buildPlanCard(plan, index, isSelected);
                            },
                          ),
                        ),

                        // Action Buttons
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFBB86FC),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                          onPressed: _subscribe,
                          child: const Text(
                            'Unlock Pro Membership',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Footer Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                              onPressed: _restore,
                              child: Text(
                                'Restore Purchase',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
                              ),
                            ),
                            Text(
                              '|',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'Terms of Service',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFBB86FC), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, int index, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFBB86FC).withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFFBB86FC) : Colors.white.withValues(alpha: 0.05),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan['title'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Flexible recurring billing',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      plan['price'] as String,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFFBB86FC) : Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      '/${plan['period']}',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),

            // Plan Badge (BEST VALUE / MOST POPULAR)
            if (plan['badge'] != null)
              Positioned(
                top: -26,
                left: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFBB86FC) : const Color(0xFF1F1F27),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    plan['badge'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
