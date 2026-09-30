import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/models/category.dart';
import '../../data/models/category_style.dart';
import '../../data/models/lesson.dart';
import '../paywall/paywall_provider.dart';
import '../templates/templates_provider.dart';
import '../templates/filter_bottom_sheet.dart';
import 'lessons_provider.dart';

const Map<String, String> _categoryEmojis = {
  'Trending': '🔥',
  'Anime': '🎌',
  'Anatomy': '🫀',
  'Tattoo': '⚡',
  'Aesthetic': '🦋',
  'Brainrot': '🧠',
  'Love': '❤️',
  'People': '🧑',
  'Cute': '🥰',
  'Kawaii': '🎀',
  'Food': '🍔',
  'For Kids': '🧒',
  'For Beginners': '✏️',
  'Holidays': '🎄',
  'Geometry': '📐',
  'Objects': '📦',
  'Animals': '🐾',
  'Cars': '🚗',
  'Nature': '🌿',
  'Architecture': '🏛️',
};


class LessonsScreen extends ConsumerStatefulWidget {
  const LessonsScreen({super.key});

  @override
  ConsumerState<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends ConsumerState<LessonsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremiumUser = ref.watch(subscriptionProvider);
    final selectedDifficulty = ref.watch(selectedDifficultyProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final titleTextColor = isDark ? Colors.white : Colors.black87;
    final subtitleTextColor = isDark ? Colors.white54 : Colors.black54;

    // Check if user is searching
    final isSearching = _searchQuery.trim().isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: isSearching ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                secondChild: const SizedBox.shrink(),
                firstChild: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      primaryColor,
                                      primaryColor.withValues(alpha: 0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  LucideIcons.bookOpen,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Art School',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  color: titleTextColor,
                                ),
                              ),
                            ],
                          ),
                          if (!isPremiumUser)
                            GestureDetector(
                              onTap: () => Navigator.of(context).pushNamed(AppRouter.paywall),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: primaryColor,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.sparkles,
                                      size: 14,
                                      color: primaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'PRO',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: primaryColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Learn drawing step-by-step with interactive guides',
                        style: TextStyle(
                          fontSize: 14,
                          color: subtitleTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Search Bar on Lessons Screen (conditionally shown if active or text entered)
            if (_isSearchActive || isSearching)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: primaryColor,
                        width: _searchFocusNode.hasFocus ? 2.0 : 1.5,
                      ),
                      boxShadow: _searchFocusNode.hasFocus
                          ? [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.15),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Material(
                        color: Colors.transparent,
                        child: TextField(
                          focusNode: _searchFocusNode,
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Search lessons...',
                            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                            prefixIcon: Icon(LucideIcons.search, color: primaryColor),
                            suffixIcon: isSearching
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: primaryColor),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Side scrollable list of filter options
            SliverToBoxAdapter(
              child: categoriesAsync.when(
                data: (categories) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: SizedBox(
                      height: 82,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: categories.length + 3,
                        separatorBuilder: (context, index) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildFilterButton(context);
                          } else if (index == 1) {
                            return _buildSearchButton(context);
                          } else if (index == 2) {
                            return _buildCategoryIconItem(
                              context,
                              label: 'All',
                              emoji: '✨',
                              isSelected: selectedCategoryId == null,
                              style: categoryStyles['all'] ?? fallbackCategoryStyle,
                              onTap: () {
                                ref.read(selectedCategoryIdProvider.notifier).setCategory(null);
                              },
                            );
                          } else {
                            final category = categories[index - 3];
                            final style = getStyleForCategory(category.name) ?? fallbackCategoryStyle;
                            final emoji = _categoryEmojis[category.name] ?? '🎨';
                            return _buildCategoryIconItem(
                              context,
                              label: category.name,
                              emoji: emoji,
                              isSelected: selectedCategoryId == category.id,
                              style: style,
                              onTap: () {
                                ref.read(selectedCategoryIdProvider.notifier).setCategory(category.id);
                              },
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox(
                  height: 82,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => const SizedBox.shrink(),
              ),
            ),

            // Segmented Difficulty Selector
            SliverToBoxAdapter(
              child: isSearching
                  ? const SizedBox.shrink()
                  : DifficultySelector(
                      selectedDifficulty: selectedDifficulty,
                      onDifficultyChanged: (value) {
                        ref.read(selectedDifficultyProvider.notifier).setDifficulty(value);
                      },
                    ),
            ),

            // Lessons List or Search Results Slivers
            if (isSearching)
              _buildSearchResultsSliver(context, ref, isPremiumUser, isDark, subtitleTextColor)
            else
              _buildNormalLessonsSliver(context, ref, selectedDifficulty, selectedCategoryId, isPremiumUser, isDark, subtitleTextColor),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelTextColor = isDark ? Colors.white70 : Colors.black87;
    final filterState = ref.watch(templateFilterProvider);

    return GestureDetector(
      onTap: () {
        FilterBottomSheet.show(context);
      },
      child: SizedBox(
        width: 52,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.appColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: filterState.isActive
                        ? Border.all(color: const Color(0xFF7C3AED), width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.filter,
                      size: 20,
                      color: filterState.isActive
                          ? const Color(0xFF7C3AED)
                          : context.appColors.primary,
                    ),
                  ),
                ),
                if (filterState.isActive)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Filter',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: filterState.isActive ? FontWeight.bold : FontWeight.w500,
                color: filterState.isActive ? const Color(0xFF7C3AED) : labelTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelTextColor = isDark ? Colors.white70 : Colors.black87;
    final selectedRingColor = context.appColors.primary;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isSearchActive = !_isSearchActive;
          if (!_isSearchActive) {
            _searchQuery = '';
            _searchController.clear();
            _searchFocusNode.unfocus();
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _searchFocusNode.requestFocus();
            });
          }
        });
      },
      child: SizedBox(
        width: 52,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: _isSearchActive
                    ? Border.all(color: selectedRingColor, width: 2)
                    : null,
              ),
              padding: _isSearchActive ? const EdgeInsets.all(2) : EdgeInsets.zero,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.appColors.primaryLight,
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.search,
                    size: 20,
                    color: context.appColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: _isSearchActive ? FontWeight.bold : FontWeight.normal,
                color: labelTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIconItem(
    BuildContext context, {
    required String label,
    required String emoji,
    required bool isSelected,
    required CategoryStyle style,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelTextColor = isDark ? Colors.white70 : Colors.black87;
    final selectedRingColor = context.appColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 58,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: selectedRingColor, width: 2)
                    : null,
              ),
              padding: isSelected ? const EdgeInsets.all(2) : EdgeInsets.zero,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: style.backgroundColor,
                ),
                child: Center(
                  child: Opacity(
                    opacity: isSelected ? 1.0 : 0.8,
                    child: Text(
                      emoji,
                      style: const TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: labelTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsSliver(
    BuildContext context,
    WidgetRef ref,
    bool isPremiumUser,
    bool isDark,
    Color subtitleTextColor,
  ) {
    final allLessonsAsync = ref.watch(allLessonsProvider);
    final filterState = ref.watch(templateFilterProvider);

    return allLessonsAsync.when(
      data: (lessons) {
        final query = _searchQuery.toLowerCase().trim();
        final filteredLessons = lessons.where((lesson) {
          final titleMatch = lesson.title.toLowerCase().contains(query);
          final catMatch = (lesson.categoryId ?? '').toLowerCase().contains(query);
          final matchesSearch = titleMatch || catMatch;

          final matchesDifficulty = filterState.difficulty == null ||
              lesson.difficulty.toLowerCase() == filterState.difficulty!.toLowerCase();
          final matchesColorType = filterState.colorType == null ||
              (lesson.colorType != null && lesson.colorType!.toLowerCase() == filterState.colorType!.toLowerCase());

          return matchesSearch && matchesDifficulty && matchesColorType;
        }).toList();

        if (filteredLessons.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No lessons match "$_searchQuery"',
                      style: TextStyle(
                        color: subtitleTextColor,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildSearchResultsCard(context, ref, filteredLessons[index], isPremiumUser),
                );
              },
              childCount: filteredLessons.length,
            ),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, stack) => SliverToBoxAdapter(
        child: Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
        ),
      ),
    );
  }

  Widget _buildNormalLessonsSliver(
    BuildContext context,
    WidgetRef ref,
    String selectedDifficulty,
    String? selectedCategoryId,
    bool isPremiumUser,
    bool isDark,
    Color subtitleTextColor,
  ) {
    final allLessonsAsync = ref.watch(allLessonsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    return allLessonsAsync.when(
      data: (lessons) {
        final categories = categoriesAsync.asData?.value ?? [];
        final selectedCat = selectedCategoryId == null
            ? null
            : categories.firstWhere(
                (c) => c.id == selectedCategoryId,
                orElse: () => Category(id: selectedCategoryId, name: '', sortOrder: 0),
              );
        final selectedCatSlug = selectedCat != null && selectedCat.name.isNotEmpty
            ? 'cat-${selectedCat.name.toLowerCase().replaceAll(' ', '-')}'
            : null;

        final categoryLessons = selectedCategoryId == null
            ? lessons
            : lessons.where((l) {
                if (l.categoryId == selectedCategoryId) return true;
                if (selectedCatSlug != null && l.categoryId == selectedCatSlug) return true;
                return false;
              }).toList();
        return _renderLessonsSliver(
          context,
          ref,
          categoryLessons,
          isPremiumUser,
          isDark,
          subtitleTextColor,
          'No lessons available in this selection',
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, stack) => SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Error loading lessons: $err',
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _renderLessonsSliver(
    BuildContext context,
    WidgetRef ref,
    List<Lesson> lessons,
    bool isPremiumUser,
    bool isDark,
    Color subtitleTextColor,
    String emptyMessage,
  ) {
    final filterState = ref.watch(templateFilterProvider);
    final selectedDifficulty = ref.watch(selectedDifficultyProvider).toLowerCase();

    final filteredLessons = lessons.where((lesson) {
      if (lesson.difficulty.toLowerCase() != selectedDifficulty) {
        return false;
      }
      if (filterState.difficulty != null &&
          lesson.difficulty.toLowerCase() != filterState.difficulty!.toLowerCase()) {
        return false;
      }
      if (filterState.colorType != null && lesson.colorType != null &&
          lesson.colorType!.toLowerCase() != filterState.colorType!.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();

    if (filteredLessons.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 64,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
                const SizedBox(height: 12),
                Text(
                  filterState.isActive ? 'No lessons match selected filters' : emptyMessage,
                  style: TextStyle(
                    color: subtitleTextColor,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final List<Widget> listItems = [];
    for (int i = 0; i < filteredLessons.length; i++) {
      listItems.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: _buildLessonCard(context, ref, filteredLessons[i], isPremiumUser),
        ),
      );

      if (!isPremiumUser) {
        if (i == 0) {
          listItems.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildTryProBanner(context),
            ),
          );
        } else if (i == 2) {
          listItems.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildDrawLikeProBanner(context),
            ),
          );
        }
      }
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => listItems[index],
        childCount: listItems.length,
      ),
    );
  }

  Widget _buildLessonCard(
    BuildContext context,
    WidgetRef ref,
    Lesson lesson,
    bool isPremiumUser,
  ) {
    final bool locked = lesson.isPremium && !isPremiumUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleTextColor = isDark ? Colors.white : Colors.black87;
    final cardBgColor = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white;
    final cardBorderColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black12;

    Color difficultyColor;
    switch (lesson.difficulty.toLowerCase()) {
      case 'easy':
        difficultyColor = const Color(0xFF22C55E); // Green
        break;
      case 'medium':
        difficultyColor = const Color(0xFFF59E0B); // Orange
        break;
      case 'hard':
        difficultyColor = const Color(0xFFEF4444); // Reddish
        break;
      default:
        difficultyColor = const Color(0xFF22C55E);
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (locked) {
              Navigator.of(context).pushNamed(AppRouter.paywall);
            } else {
              Navigator.of(context).pushNamed(
                AppRouter.trace,
                arguments: {
                  'imagePath': lesson.thumbnailUrl,
                  'isAsset': false,
                },
              );
            }
          },
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cardBorderColor),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _buildLessonImage(lesson.thumbnailUrl, isDark, Theme.of(context).colorScheme.primary),
                    ),
                    if (!lesson.isPremium)
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981), // Emerald Green
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: const Text(
                            'Free',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      )
                    else
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFD700),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock,
                            size: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: titleTextColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: difficultyColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: difficultyColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              lesson.difficulty.toUpperCase(),
                              style: TextStyle(
                                color: difficultyColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                            ),
                            child: Text(
                              '${lesson.stepCount} Steps',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${lesson.completionCount}',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white38 : Colors.black38,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSearchResultsCard(
    BuildContext context,
    WidgetRef ref,
    Lesson lesson,
    bool isPremiumUser,
  ) {
    final bool locked = lesson.isPremium && !isPremiumUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleTextColor = isDark ? Colors.white : Colors.black87;
    final cardBgColor = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white;
    final cardBorderColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black12;

    Color difficultyColor;
    switch (lesson.difficulty.toLowerCase()) {
      case 'easy':
        difficultyColor = const Color(0xFF22C55E); // Green
        break;
      case 'medium':
        difficultyColor = const Color(0xFFF59E0B); // Orange
        break;
      case 'hard':
        difficultyColor = const Color(0xFFEF4444); // Reddish
        break;
      default:
        difficultyColor = const Color(0xFF22C55E);
    }

    return GestureDetector(
      onTap: () {
        if (locked) {
          Navigator.of(context).pushNamed(AppRouter.paywall);
        } else {
          Navigator.of(context).pushNamed(
            AppRouter.trace,
            arguments: {
              'imagePath': lesson.thumbnailUrl,
              'isAsset': false,
            },
          );
        }
      },
      child: Container(
        height: 140,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorderColor),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Left Image Thumbnail (White background for outlines)
            Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    lesson.thumbnailUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                    ),
                  ),
                ),
                if (locked)
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.lock, color: Color(0xFFFFD700), size: 24),
                    ),
                  ),
              ],
            ),

            // Right side: Info details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: titleTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Difficulty badge (solid background)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: difficultyColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            lesson.difficulty[0].toUpperCase() + lesson.difficulty.substring(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Steps badge (tinted background)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: difficultyColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${lesson.stepCount} Steps',
                            style: TextStyle(
                              color: difficultyColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Completion counter capsule at the bottom
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.favorite,
                                size: 14,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${lesson.completionCount}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTryProBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(AppRouter.paywall),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.gift,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Try PRO for Free',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unlock all outlines & guides',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Try Now',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawLikeProBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(AppRouter.paywall),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF3B1E70),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Draw like a Pro',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white70,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class DifficultySelector extends StatelessWidget {
  final String selectedDifficulty;
  final ValueChanged<String> onDifficultyChanged;

  const DifficultySelector({
    super.key,
    required this.selectedDifficulty,
    required this.onDifficultyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildTab(context, 'Easy', const Color(0xFF22C55E)),
          _buildTab(context, 'Medium', const Color(0xFFF59E0B)),
          _buildTab(context, 'Hard', const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, String title, Color activeColor) {
    final isSelected = selectedDifficulty == title.toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => onDifficultyChanged(title.toLowerCase()),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black87),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildLessonImage(String imageUrl, bool isDark, Color primaryColor) {
  if (imageUrl.isEmpty) {
    return Container(
      color: isDark ? Colors.black38 : Colors.grey.shade200,
      child: const Icon(Icons.broken_image, color: Colors.white30, size: 32),
    );
  }

  if (imageUrl.startsWith('assets/')) {
    return Image.asset(imageUrl, fit: BoxFit.cover);
  }

  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: isDark ? Colors.black38 : Colors.grey.shade200,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: isDark ? Colors.black38 : Colors.grey.shade200,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.white38, size: 28),
            SizedBox(height: 4),
            Text(
              'Offline',
              style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  final File file = imageUrl.startsWith('file:')
      ? File.fromUri(Uri.parse(imageUrl))
      : File(imageUrl);

  return Image.file(
    file,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) => Container(
      color: isDark ? Colors.black38 : Colors.grey.shade200,
      child: const Icon(Icons.broken_image, color: Colors.white30, size: 32),
    ),
  );
}
