import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'templates_provider.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  String? _selectedDifficulty;
  String? _selectedColorType;

  @override
  void initState() {
    super.initState();
    final currentFilter = ref.read(templateFilterProvider);
    _selectedDifficulty = currentFilter.difficulty;
    _selectedColorType = currentFilter.colorType;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle bar at top center
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title: "Filter" - large, bold, ~32px, left-aligned
            const Text(
              'Filter',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 28),

            // Section label: "Difficulty level" - medium weight, ~18px
            const Text(
              'Difficulty level',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 14),

            // Three-segment row: Easy / Medium / Hard
            Row(
              children: [
                _buildSegmentButton(
                  label: 'Easy',
                  isSelected: _selectedDifficulty == 'easy',
                  onTap: () {
                    setState(() {
                      _selectedDifficulty = _selectedDifficulty == 'easy' ? null : 'easy';
                    });
                  },
                ),
                const SizedBox(width: 12),
                _buildSegmentButton(
                  label: 'Medium',
                  isSelected: _selectedDifficulty == 'medium',
                  onTap: () {
                    setState(() {
                      _selectedDifficulty = _selectedDifficulty == 'medium' ? null : 'medium';
                    });
                  },
                ),
                const SizedBox(width: 12),
                _buildSegmentButton(
                  label: 'Hard',
                  isSelected: _selectedDifficulty == 'hard',
                  onTap: () {
                    setState(() {
                      _selectedDifficulty = _selectedDifficulty == 'hard' ? null : 'hard';
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Section label: "Color type"
            const Text(
              'Color type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 14),

            // Two-segment row: Black and White / Colorful
            Row(
              children: [
                _buildSegmentButton(
                  label: 'Black and White',
                  isSelected: _selectedColorType == 'bw',
                  onTap: () {
                    setState(() {
                      _selectedColorType = _selectedColorType == 'bw' ? null : 'bw';
                    });
                  },
                ),
                const SizedBox(width: 12),
                _buildSegmentButton(
                  label: 'Colorful',
                  isSelected: _selectedColorType == 'colorful',
                  onTap: () {
                    setState(() {
                      _selectedColorType = _selectedColorType == 'colorful' ? null : 'colorful';
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 36),

            // Bottom row, two buttons side by side: Reset and Apply
            Row(
              children: [
                // Reset (white background, purple text, no border)
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF7C3AED),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedDifficulty = null;
                        _selectedColorType = null;
                      });
                      ref.read(templateFilterProvider.notifier).reset();
                    },
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Apply (filled purple background, white text)
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      ref.read(templateFilterProvider.notifier).setFilter(
                        difficulty: _selectedDifficulty,
                        colorType: _selectedColorType,
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const purpleColor = Color(0xFF7C3AED);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? purpleColor : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? purpleColor : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
