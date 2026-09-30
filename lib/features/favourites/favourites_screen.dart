import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../app/router.dart';
import '../../data/repositories/gallery_repository.dart';
import '../gallery/gallery_screen.dart';
import '../paywall/paywall_provider.dart';
import '../templates/templates_screen.dart';
import 'favourites_provider.dart';

class FavouritesScreen extends ConsumerStatefulWidget {
  const FavouritesScreen({super.key});

  @override
  ConsumerState<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends ConsumerState<FavouritesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favTemplatesAsync = ref.watch(favouritedTemplatesProvider);
    final savedDrawingsAsync = ref.watch(savedDrawingsProvider);
    final isPremiumUser = ref.watch(subscriptionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final titleTextColor = isDark ? Colors.white : Colors.black87;
    final subtitleTextColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Bar
            Padding(
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
                                colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
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
                              LucideIcons.heart,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Favorites & Creations',
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
                    'Your saved drawings and bookmarked templates',
                    style: TextStyle(
                      fontSize: 14,
                      color: subtitleTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Custom Section Switcher (Matches DifficultySelector UI)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, child) {
                        final selectedIndex = _tabController.index;
                        return Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _tabController.animateTo(0),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: selectedIndex == 0 ? primaryColor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: selectedIndex == 0 && !isDark
                                        ? [
                                            BoxShadow(
                                              color: primaryColor.withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    'Saved',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: selectedIndex == 0
                                          ? Colors.white
                                          : (isDark ? Colors.white70 : Colors.black87),
                                      fontWeight: selectedIndex == 0 ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _tabController.animateTo(1),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: selectedIndex == 1 ? primaryColor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: selectedIndex == 1 && !isDark
                                        ? [
                                            BoxShadow(
                                              color: primaryColor.withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    'Favorite',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: selectedIndex == 1
                                          ? Colors.white
                                          : (isDark ? Colors.white70 : Colors.black87),
                                      fontWeight: selectedIndex == 1 ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Tab Views Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: My Drawings Section
                  savedDrawingsAsync.when(
                    data: (drawings) {
                      if (drawings.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.image, size: 64, color: subtitleTextColor.withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              Text(
                                'No drawings saved yet',
                                style: TextStyle(color: titleTextColor, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Complete a drawing to save it here automatically.',
                                style: TextStyle(color: subtitleTextColor, fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }

                      return GridView.builder(
                        physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: drawings.length,
                          itemBuilder: (context, index) {
                            final filePath = drawings[index];
                            return GalleryTile(
                              filePath: filePath,
                              onTap: () {
                                GalleryScreen.openFullScreenPreview(context, ref, filePath);
                              },
                              onShare: () => GalleryScreen.shareDrawing(context, filePath),
                              onDelete: () => GalleryScreen.confirmDelete(context, ref, filePath),
                            );
                          },
                        );
                    },
                    loading: () => Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                    error: (err, stack) => Center(
                      child: Text('Error loading drawings: $err', style: const TextStyle(color: Colors.redAccent)),
                    ),
                  ),

                  // Tab 2: Favorited Items Section
                  favTemplatesAsync.when(
                    data: (templates) {
                      if (templates.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.favorite_border, size: 64, color: subtitleTextColor.withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              Text(
                                'No favorites added yet',
                                style: TextStyle(color: titleTextColor, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the heart icon on any template to add it here.',
                                style: TextStyle(color: subtitleTextColor, fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }

                      return GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: templates.length,
                        itemBuilder: (context, index) {
                          final template = templates[index];
                          return buildTemplateCard(context, ref, template);
                        },
                      );
                    },
                    loading: () => Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                    error: (err, stack) => Center(
                      child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
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
}
