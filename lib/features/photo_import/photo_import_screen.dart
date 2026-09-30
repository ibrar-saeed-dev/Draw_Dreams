import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../app/router.dart';
import '../../core/utils/image_utils.dart';
import '../paywall/paywall_provider.dart';
import '../templates/user_uploads_provider.dart';
import '../favourites/favourites_provider.dart';

class PhotoImportScreen extends ConsumerStatefulWidget {
  const PhotoImportScreen({super.key});

  @override
  ConsumerState<PhotoImportScreen> createState() => _PhotoImportScreenState();
}

class _PhotoImportScreenState extends ConsumerState<PhotoImportScreen> {
  final ImagePicker _picker = ImagePicker();
  
  String? _selectedImagePath;
  Uint8List? _outlineBytes;
  bool _isProcessing = false;
  bool _showOutline = true; // Toggle between original and outline view

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (pickedFile == null) return;

      // Crop the image to focus on target sketch area
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop & Rotate',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFFBB86FC),
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop & Rotate',
            aspectRatioLockEnabled: false,
          ),
        ],
      );

      final String imagePath = croppedFile?.path ?? pickedFile.path;

      setState(() {
        _selectedImagePath = imagePath;
        _isProcessing = true;
      });

      // Generate Sobel edge detection outline
      final outlineBytes = await ImageUtils.convertToOutline(imagePath);

      setState(() {
        _outlineBytes = outlineBytes;
        _isProcessing = false;
        _showOutline = true;
      });
    } catch (e) {
      debugPrint("Error picking/cropping image: $e");
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load image: $e')),
        );
      }
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImagePath = null;
      _outlineBytes = null;
      _isProcessing = false;
    });
  }

  Future<void> _startTracing() async {
    if (_selectedImagePath == null) return;

    try {
      String tracePath;
      String? outlinePath;

      if (_showOutline && _outlineBytes != null) {
        // Save the generated outline bytes to system temporary directory
        final tempDir = Directory.systemTemp;
        final tempFile = File(
          '${tempDir.path}/outline_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await tempFile.writeAsBytes(_outlineBytes!);
        tracePath = tempFile.path;
        outlinePath = tempFile.path;
      } else {
        // Trace original cropped photo
        tracePath = _selectedImagePath!;
      }

      // Save upload persistently so it's reusable in "My Uploads" and Favorites
      try {
        final upload = await ref.read(userUploadsProvider.notifier).addUpload(
          imagePath: _selectedImagePath!,
          outlinePath: outlinePath,
        );
        ref.read(favouritesProvider.notifier).toggleFavourite(upload.id);
      } catch (e) {
        debugPrint("Error persisting user upload: $e");
      }

      if (mounted) {
        Navigator.of(context).pushNamed(
          AppRouter.trace,
          arguments: {
            'imagePath': tracePath,
            'isAsset': false,
          },
        );
      }
    } catch (e) {
      debugPrint("Failed to write outline temporary file: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to prepare drawing canvas. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Import Photo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (_selectedImagePath != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white54),
              onPressed: _clearImage,
            )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildMainContent(),
              ),
              const SizedBox(height: 24),
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isProcessing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBB86FC)),
            ),
            const SizedBox(height: 16),
            Text(
              'Converting photo to tracing outline...',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_selectedImagePath == null) {
      return _buildPickerEmptyState();
    }

    return _buildPreviewState();
  }

  Widget _buildPickerEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10, style: BorderStyle.solid),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFBB86FC).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: Color(0xFFBB86FC),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Import a Sketch or Reference',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a drawing, coloring page, or photograph. Our sketch converter will instantly extract outlines for you to trace.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildEmptyStateButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEmptyStateButton(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white10),
      ),
    ).build(
      context,
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPreviewState() {
    final imageToShow = (_showOutline && _outlineBytes != null)
        ? Image.memory(_outlineBytes!, fit: BoxFit.contain)
        : Image.file(File(_selectedImagePath!), fit: BoxFit.contain);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            maxScale: 4.0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(child: imageToShow),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _showOutline ? 'Sketch Outline Mode' : 'Original Photo Mode',
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    if (_selectedImagePath == null || _isProcessing) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode Selector (Outline vs Original)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildSegmentButton(
                  label: 'Outline Sketch',
                  isSelected: _showOutline,
                  onPressed: () => setState(() => _showOutline = true),
                ),
              ),
              Expanded(
                child: _buildSegmentButton(
                  label: 'Original Color',
                  isSelected: !_showOutline,
                  onPressed: () => setState(() => _showOutline = false),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Start Tracing Action button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFBB86FC),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
          onPressed: _startTracing,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.gesture, size: 20),
              SizedBox(width: 8),
              Text(
                'Start Tracing in AR',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFBB86FC) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// Extension to help build custom elevated buttons cleanly
extension on ButtonStyle {
  Widget build(BuildContext context, {required VoidCallback onPressed, required Widget child}) {
    return ElevatedButton(style: this, onPressed: onPressed, child: child);
  }
}
