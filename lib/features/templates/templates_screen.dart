import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/services/connectivity_service.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/models/category.dart';
import '../../data/models/template.dart';
import '../paywall/paywall_provider.dart';
import 'templates_provider.dart';
import 'user_uploads_provider.dart';
import '../favourites/favourites_provider.dart';

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

String _getCategoryDisplayName(String name) {
  final emoji = _categoryEmojis[name];
  if (emoji != null) {
    return '$emoji $name';
  }
  return name;
}


class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  final ScrollController _mainScrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};

  @override
  void dispose() {
    _mainScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final userUploadsAsync = ref.watch(userUploadsProvider);
    final isPremiumUser = ref.watch(subscriptionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isOnline = ref.watch(isOnlineProvider);
    final titleTextColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            if (!isOnline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                color: Colors.amber.shade900,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white, size: 14),
                    SizedBox(width: 8),
                    Text(
                      'Offline — showing cached content',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            // 1. Top Header Bar (Fixed at top)
            _buildTopHeader(context, isDark, isPremiumUser, titleTextColor),

            // 2. Main Scrollable Body
            Expanded(
              child: CustomScrollView(
                controller: _mainScrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Quick Actions Row (Gallery + AI Creator)
                  SliverToBoxAdapter(
                    child: _buildQuickActionRow(context),
                  ),

                  // User Uploads Section (if any uploads exist)
                  userUploadsAsync.when(
                    data: (uploads) {
                      if (uploads.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                      return SliverToBoxAdapter(
                        child: _buildMyUploadsSection(context, ref, uploads, isDark, titleTextColor),
                      );
                    },
                    loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                    error: (err, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                  ),

                  // Category Sections Feed
                  categoriesAsync.when(
                    data: (categories) {
                      return SliverToBoxAdapter(
                        child: Column(
                          children: List.generate(categories.length, (index) {
                            final category = categories[index];
                            final key = _sectionKeys.putIfAbsent(category.id, () => GlobalKey());
                            return KeyedSubtree(
                              key: key,
                              child: _buildHorizontalSection(context, ref, category, ''),
                            );
                          }),
                        ),
                      );
                    },
                    loading: () => SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    error: (err, stack) => SliverToBoxAdapter(
                      child: Center(
                        child: Text('Error loading categories: $err', style: const TextStyle(color: Colors.redAccent)),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Top Header Bar Widget
  Widget _buildTopHeader(BuildContext context, bool isDark, bool isPremiumUser, Color titleTextColor) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: App Logo Icon + Title
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
                  LucideIcons.penTool,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Draw Dreams',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: titleTextColor,
                ),
              ),
            ],
          ),

          // Right: "PRO" Badge (taps through to Paywall)
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(AppRouter.paywall),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isPremiumUser ? Colors.amber.withValues(alpha: 0.15) : primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isPremiumUser ? Colors.amber : primaryColor,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.sparkles,
                    size: 14,
                    color: isPremiumUser ? Colors.amber : primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'PRO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isPremiumUser ? Colors.amber : primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Quick Action Two-Card Row (Gallery + AI Creator)
  Widget _buildQuickActionRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = context.appColors.primaryLight;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          // Gallery Card
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pushNamed(AppRouter.photoImport),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isDark ? null : [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.image,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gallery',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Upload your image',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // AI Creator Card
          Expanded(
            child: GestureDetector(
              onTap: () => _showAiCreatorComingSoon(context),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isDark ? null : [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.wand2,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Creator',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Create picture with AI',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAiCreatorComingSoon(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(LucideIcons.sparkles, color: primaryColor),
            const SizedBox(width: 8),
            const Text('AI Creator'),
          ],
        ),
        content: const Text(
          'Generate custom line art and tracing references using AI! This feature will be available in the next update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  // 3. My Uploads Section
  Widget _buildMyUploadsSection(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> uploads,
    bool isDark,
    Color titleTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Text(
            'My Uploads',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: titleTextColor,
            ),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: uploads.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final upload = uploads[index];
              final template = upload.toTemplate();
              return SizedBox(
                width: 140,
                child: buildTemplateCard(
                  context,
                  ref,
                  template,
                  isUpload: true,
                  onDelete: () => confirmDeleteUpload(context, ref, upload.id),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // 4. Horizontal Section Widget
  Widget _buildHorizontalSection(
    BuildContext context,
    WidgetRef ref,
    Category category,
    String searchQuery,
  ) {
    final templatesAsync = ref.watch(categoryTemplatesProvider(category.id));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleTextColor = isDark ? Colors.white : Colors.black87;
    final activeColor = Theme.of(context).colorScheme.primary;

    return templatesAsync.when(
      data: (templates) {
        final filtered = templates.where((t) {
          final query = searchQuery.toLowerCase().trim();
          if (query.isEmpty) return true;
          final titleMatch = t.title.toLowerCase().contains(query);
          final catMatch = category.name.toLowerCase().contains(query);
          return titleMatch || catMatch;
        }).toList();

        if (filtered.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getCategoryDisplayName(category.name),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: titleTextColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CategoryGridScreen(category: category),
                        ),
                      );
                    },
                    child: Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: activeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Horizontal list of Pure Image Cards
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filtered.length,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final template = filtered[index];
                  return SizedBox(
                    width: 140,
                    child: buildTemplateCard(context, ref, template),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: titleTextColor,
                  ),
                ),
                Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: activeColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 3,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) => Container(
                width: 140,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}

class CategoryGridScreen extends StatelessWidget {
  final Category category;
  const CategoryGridScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final templatesAsync = ref.watch(categoryTemplatesProvider(category.id));
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final titleTextColor = isDark ? Colors.white : Colors.black87;
        final subtitleTextColor = isDark ? Colors.white54 : Colors.black54;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header with back button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 20, 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            color: titleTextColor,
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getCategoryDisplayName(category.name),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: titleTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Grid View of templates
                templatesAsync.when(
                  data: (templates) {
                    if (templates.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_search, size: 64, color: isDark ? Colors.white30 : Colors.black26),
                              const SizedBox(height: 12),
                              Text('No templates found', style: TextStyle(color: subtitleTextColor, fontSize: 16)),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final template = templates[index];
                            return buildTemplateCard(context, ref, template);
                          },
                          childCount: templates.length,
                        ),
                      ),
                    );
                  },
                  loading: () => SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  error: (err, stack) => SliverFillRemaining(
                    child: Center(
                      child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Pure Image Card Widget Function (No title or label text overlays)
Widget buildTemplateCard(
  BuildContext context,
  WidgetRef ref,
  Template template, {
  bool isUpload = false,
  VoidCallback? onDelete,
}) {
  final bool isAsset = template.imageUrl.startsWith('assets/');
  final bool isFile = template.imageUrl.startsWith('/') || template.imageUrl.startsWith('file:');
  final bool isUploadCard = isUpload || template.id.startsWith('upload_') || isFile;
  final bool isPremiumUser = ref.watch(subscriptionProvider);
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final cardBgColor = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white;
  final cardBorderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black12;

  return GestureDetector(
    onTap: () {
      if (template.isPremium && !isPremiumUser) {
        Navigator.of(context).pushNamed(AppRouter.paywall);
      } else {
        Navigator.of(context).pushNamed(
          AppRouter.trace,
          arguments: {
            'imagePath': template.imageUrl,
            'isAsset': isAsset,
          },
        );
      }
    },
    child: Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorderColor),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Pure Image Tile
          _buildCardImage(template.imageUrl, isDark, Theme.of(context).colorScheme.primary),

          // Favorite Heart Button (Top Left)
          Positioned(
            top: 6,
            left: 6,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                icon: Icon(
                  ref.watch(favouritesProvider).contains(template.id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: ref.watch(favouritesProvider).contains(template.id)
                      ? Colors.redAccent
                      : Color(0xFF7C3AED),
                  size: 20,
                ),
                onPressed: () {
                  ref.read(favouritesProvider.notifier).toggleFavourite(template.id);
                },
              ),
            ),
          ),

          // Red Delete Button for User Uploads (Top Right)
          if (isUploadCard)
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  onPressed: onDelete ?? () => confirmDeleteUpload(context, ref, template.id),
                ),
              ),
            ),
          // Green "Free" Badge (Bottom Left - when is_premium == false)
          if (!isUploadCard && !template.isPremium)
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981), // Vibrant Emerald Green
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
          // Premium Lock Badge (Bottom Right - when is_premium == true)
          else if (template.isPremium)
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
    ),
  );
}

void confirmDeleteUpload(BuildContext context, WidgetRef ref, String uploadId) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Delete Upload'),
      content: const Text('Are you sure you want to delete this picture from your uploads?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            ref.read(userUploadsProvider.notifier).deleteUpload(uploadId);
            if (ref.read(favouritesProvider).contains(uploadId)) {
              ref.read(favouritesProvider.notifier).toggleFavourite(uploadId);
            }
          },
          child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    ),
  );
}

Widget _buildCardImage(String imageUrl, bool isDark, Color primaryColor) {
  if (imageUrl.isEmpty) {
    return Container(
      color: isDark ? Colors.black38 : Colors.grey.shade200,
      child: const Icon(Icons.broken_image, color: Colors.white30, size: 32),
    );
  }

  String resolvedUrl = imageUrl;
  if (!resolvedUrl.startsWith('assets/') &&
      !resolvedUrl.startsWith('http://') &&
      !resolvedUrl.startsWith('https://') &&
      !resolvedUrl.startsWith('file:') &&
      !resolvedUrl.startsWith('/')) {
    try {
      resolvedUrl = Supabase.instance.client.storage.from('templates').getPublicUrl(resolvedUrl);
    } catch (_) {}
  }

  if (resolvedUrl.startsWith('assets/')) {
    return Image.asset(resolvedUrl, fit: BoxFit.cover);
  }

  if (resolvedUrl.startsWith('http://') || resolvedUrl.startsWith('https://')) {
    return CachedNetworkImage(
      imageUrl: resolvedUrl,
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

  // Local File (starts with file: or /)
  final File file = imageUrl.startsWith('file:')
      ? File.fromUri(Uri.parse(imageUrl))
      : File(imageUrl);

  return Image.file(
    file,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) {
      debugPrint("Failed to load local file image ($imageUrl): $error");
      return Container(
        color: isDark ? Colors.black38 : Colors.grey.shade200,
        child: const Icon(Icons.broken_image, color: Colors.white30, size: 32),
      );
    },
  );
}
