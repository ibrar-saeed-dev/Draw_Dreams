import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/router.dart';
import '../../data/repositories/gallery_repository.dart';

class SaveExportScreen extends ConsumerStatefulWidget {
  final String capturedImagePath;
  final String? templateImagePath;
  final bool isTemplateAsset;

  const SaveExportScreen({
    super.key,
    required this.capturedImagePath,
    this.templateImagePath,
    this.isTemplateAsset = true,
  });

  @override
  ConsumerState<SaveExportScreen> createState() => _SaveExportScreenState();
}

class _SaveExportScreenState extends ConsumerState<SaveExportScreen> {
  double _templateOpacity = 0.0;
  bool _isSaving = false;

  Future<void> _saveLocal() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(galleryRepositoryProvider);
      final result = await repo.saveLocalDrawing(widget.capturedImagePath);

      ref.invalidate(savedDrawingsProvider);

      if (mounted) {
        if (result.isLocalSaveSuccessful && result.isNativeExportSuccessful) {
          _showSuccessDialog(
            title: 'Drawing Saved & Exported!',
          );
        } else if (result.isLocalSaveSuccessful) {
          _showSuccessDialog(
            title: 'Saved to App Gallery',
            isWarning: true,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save drawing to local storage.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save drawing: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSuccessDialog({
    required String title,
    bool isWarning = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRouter.mainShell,
              (route) => false,
            );
          }
        });

        return AlertDialog(
          backgroundColor: const Color(0xFF16161A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white10),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isWarning ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                  color: isWarning ? Colors.orangeAccent : const Color(0xFFBB86FC),
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
          'Preview & Export',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _isSaving
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBB86FC)),
                      ),
                      SizedBox(height: 16),
                      Text('Saving your drawing...', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Interactive stack overlay comparison
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // 1. User's hand-drawn sketch photo
                            InteractiveViewer(
                              maxScale: 3.0,
                              child: Image.file(
                                File(widget.capturedImagePath),
                                fit: BoxFit.contain,
                              ),
                            ),

                            // 2. Reference Template Overlay (Accuracy checking)
                            if (widget.templateImagePath != null)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Opacity(
                                    opacity: _templateOpacity,
                                    child: _buildTemplateOverlayImage(),
                                  ),
                                ),
                              ),

                            // Indicator Badge
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Your Drawing',
                                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Accuracy checking slider
                    if (widget.templateImagePath != null) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Compare Accuracy Overlay',
                                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${(_templateOpacity * 100).toInt()}%',
                                style: const TextStyle(color: Color(0xFFBB86FC), fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Slider(
                            value: _templateOpacity,
                            onChanged: (val) {
                              setState(() {
                                _templateOpacity = val;
                              });
                            },
                            activeColor: const Color(0xFFBB86FC),
                            inactiveColor: Colors.white12,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Single Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBB86FC),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        onPressed: _saveLocal,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_alt, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Save Drawing',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTemplateOverlayImage() {
    final path = widget.templateImagePath!;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(path, fit: BoxFit.contain);
    } else if (widget.isTemplateAsset || path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.contain);
    } else {
      return Image.file(File(path), fit: BoxFit.contain);
    }
  }
}
