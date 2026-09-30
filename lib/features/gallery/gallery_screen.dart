import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import '../../app/theme.dart';
import '../../data/repositories/gallery_repository.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedDrawingsAsync = ref.watch(savedDrawingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final titleTextColor = isDark ? Colors.white : Colors.black87;
    final subtitleTextColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
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
                      LucideIcons.image,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'My Gallery',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: titleTextColor,
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: savedDrawingsAsync.when(
                data: (drawings) {
                  if (drawings.isEmpty) {
                    return _buildEmptyState(context, isDark, subtitleTextColor);
                  }

                  return GridView.builder(
                    physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                  child: Text(
                    'Error loading gallery: $err',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, Color subtitleTextColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.appColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  LucideIcons.image,
                  size: 38,
                  color: context.appColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No saved drawings yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Finish tracing something to see it here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: subtitleTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void shareDrawing(BuildContext context, String filePath) {
    Share.shareXFiles([XFile(filePath)], text: 'Check out my drawing created with AR Trace & Draw!');
  }

  static void confirmDelete(BuildContext context, WidgetRef ref, String filePath) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Delete this drawing?'),
        content: const Text("This action cannot be undone and will permanently remove the drawing from local storage."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final repo = ref.read(galleryRepositoryProvider);
              await repo.deleteDrawing(filePath);
              ref.invalidate(savedDrawingsProvider);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  static void openFullScreenPreview(BuildContext context, WidgetRef ref, String filePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenPreviewScreen(
          filePath: filePath,
          onShare: () => shareDrawing(context, filePath),
          onDelete: () => confirmDelete(context, ref, filePath),
        ),
      ),
    );
  }
}

class GalleryTile extends StatelessWidget {
  final String filePath;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const GalleryTile({
    super.key,
    required this.filePath,
    required this.onTap,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showPopupMenu(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(filePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(LucideIcons.imageOff, color: Colors.grey),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.moreVertical, color: Colors.white, size: 18),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      onPressed: () => _showPopupMenu(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPopupMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.share2, color: Color(0xFF7C3AED)),
              title: const Text('Share', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.of(context).pop();
                onShare();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: Colors.redAccent),
              title: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
              onTap: () {
                Navigator.of(context).pop();
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenPreviewScreen extends StatelessWidget {
  final String filePath;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const FullScreenPreviewScreen({
    super.key,
    required this.filePath,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2, color: Colors.white),
            onPressed: onShare,
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
            onPressed: () {
              onDelete();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            maxScale: 4.0,
            child: Image.file(
              File(filePath),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
