import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/router.dart';
import 'camera_overlay_provider.dart';

class CameraOverlayScreen extends ConsumerStatefulWidget {
  final String? imagePath;
  final bool isAsset;

  const CameraOverlayScreen({
    super.key,
    this.imagePath,
    this.isAsset = true,
  });

  @override
  ConsumerState<CameraOverlayScreen> createState() => _CameraOverlayScreenState();
}

class _CameraOverlayScreenState extends ConsumerState<CameraOverlayScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _hasCameraError = false;
  bool _isCapturing = false;

  double _previousScale = 1.0;
  double _previousRotation = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTimeSetup();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    // App state changed before we set up the controller
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _hasCameraError = true;
        });
        return;
      }

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _hasCameraError = false;
        });
      }
    } catch (e) {
      debugPrint("Camera initialization failed: $e");
      if (mounted) {
        setState(() {
          _hasCameraError = true;
        });
      }
    }
  }

  void _toggleFlash() async {
    if (_cameraController == null || !_isCameraInitialized) return;
    final notifier = ref.read(cameraOverlayProvider.notifier);
    final state = ref.read(cameraOverlayProvider);

    final newFlashState = !state.isFlashOn;
    notifier.setFlash(newFlashState);

    try {
      await _cameraController!.setFlashMode(
        newFlashState ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      debugPrint("Failed to toggle flash: $e");
      notifier.setFlash(!newFlashState); // revert
    }
  }

  Future<void> _checkFirstTimeSetup() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('has_seen_setup_guide') ?? false;
    if (!hasSeen && mounted) {
      _showSetupGuide();
    }
  }

  void _showSetupGuide() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return const SetupGuideDialog();
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overlayState = ref.watch(cameraOverlayProvider);
    final overlayNotifier = ref.read(cameraOverlayProvider.notifier);

    // Default to the generated cat outline if no image is selected
    final String imageToShow = widget.imagePath ?? 'assets/templates/cat_outline.png';
    final bool isAssetToShow = widget.imagePath == null ? true : widget.isAsset;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Live Feed or Fallback Background
          _buildCameraPreview(),

          // 2. Gesture Detector Box for image manipulation
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onScaleStart: (details) {
                _previousScale = 1.0;
                _previousRotation = 0.0;
              },
              onScaleUpdate: (details) {
                if (overlayState.isLocked) return;

                // Position update
                overlayNotifier.updatePosition(details.focalPointDelta);

                // Scale update
                if (details.scale != 1.0) {
                  final scaleFactor = details.scale / _previousScale;
                  _previousScale = details.scale;
                  overlayNotifier.updateScale(scaleFactor);
                }

                // Rotation update
                if (details.rotation != 0.0) {
                  final rotationDelta = details.rotation - _previousRotation;
                  _previousRotation = details.rotation;
                  overlayNotifier.updateRotation(rotationDelta);
                }
              },
              child: Stack(
                children: [
                  Center(
                    child: Transform.translate(
                      offset: overlayState.position,
                      child: Transform.rotate(
                        angle: overlayState.rotation,
                        child: Transform.scale(
                          scale: overlayState.scale,
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.diagonal3Values(
                                overlayState.isFlipped ? -1.0 : 1.0, 1.0, 1.0),
                            child: Opacity(
                              opacity: overlayState.opacity,
                              child: _buildOverlayImage(imageToShow, isAssetToShow),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Overlay Toolbar (Top Bar)
          if (!overlayState.isLocked)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircularButton(
                    icon: Icons.arrow_back,
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  Row(
                    children: [
                      _buildCircularButton(
                        icon: overlayState.isFlashOn ? Icons.flash_on : Icons.flash_off,
                        onPressed: _toggleFlash,
                        iconColor: overlayState.isFlashOn ? Colors.amber : Colors.white,
                      ),
                      const SizedBox(width: 12),
                      _buildCircularButton(
                        icon: Icons.refresh,
                        onPressed: () {
                          overlayNotifier.reset();
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildCircularButton(
                        icon: Icons.help_outline,
                        onPressed: _showSetupGuide,
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // 4. Floating Action Controls (Bottom Bar & Panel)
          if (!overlayState.isLocked)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Opacity Slider Bar (Glassmorphic look)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.opacity, color: Colors.white70, size: 20),
                        Expanded(
                          child: Slider(
                            value: overlayState.opacity,
                            min: 0.05,
                            max: 1.0,
                            onChanged: (val) {
                              overlayNotifier.setOpacity(val);
                            },
                          ),
                        ),
                        Text(
                          '${(overlayState.opacity * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action buttons panel
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTextActionButton(
                        icon: Icons.lock_open,
                        label: 'Lock',
                        onPressed: () {
                          overlayNotifier.toggleLock();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Screen Locked! All buttons locked.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        isActive: false,
                      ),
                      _buildTextActionButton(
                        icon: Icons.flip,
                        label: 'Flip',
                        onPressed: () {
                          overlayNotifier.toggleFlip();
                        },
                        isActive: overlayState.isFlipped,
                      ),
                      _buildTextActionButton(
                        icon: Icons.check,
                        label: 'Done',
                        onPressed: () async {
                          if (_isCapturing) return;

                          final navigator = Navigator.of(context);
                          final scaffoldMessenger = ScaffoldMessenger.of(context);

                          if (_cameraController != null && _isCameraInitialized) {
                            setState(() {
                              _isCapturing = true;
                            });
                            try {
                              final XFile photo = await _cameraController!.takePicture();
                              if (!mounted) return;
                              navigator.pushNamed(
                                AppRouter.saveExport,
                                arguments: {
                                  'capturedImagePath': photo.path,
                                  'templateImagePath': widget.imagePath,
                                  'isTemplateAsset': widget.isAsset,
                                },
                              );
                            } catch (e) {
                              debugPrint("Error taking picture: $e");
                              if (!mounted) return;
                              scaffoldMessenger.showSnackBar(
                                SnackBar(content: Text('Failed to capture photo: $e')),
                              );
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isCapturing = false;
                                });
                              }
                            }
                          } else {
                            // Mock/Fallback for Emulator
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('Camera not ready. Mocking capture...')),
                            );
                            if (!mounted) return;
                            navigator.pushNamed(
                              AppRouter.saveExport,
                              arguments: {
                                'capturedImagePath': widget.imagePath ?? '',
                                'templateImagePath': widget.imagePath,
                                'isTemplateAsset': widget.isAsset,
                              },
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // 5. Hard Lock Mode: Full Screen Touch Shield + Only Unlock Floating Action Button
          if (overlayState.isLocked) ...[
            // AbsorbPointer intercepts any touch anywhere on the screen
            const Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: SizedBox.expand(),
              ),
            ),
            // The single Unlock button positioned above the AbsorbPointer
            Positioned(
              bottom: 30,
              right: 20,
              child: FloatingActionButton.extended(
                backgroundColor: const Color(0xFFBB86FC),
                foregroundColor: Colors.black,
                elevation: 8,
                onPressed: () {
                  overlayNotifier.toggleLock();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Screen Unlocked.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.lock, size: 20),
                label: const Text(
                  'Unlock Screen',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
          if (_isCapturing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBB86FC)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Capturing your drawing...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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

  Widget _buildCameraPreview() {
    if (_hasCameraError) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white54),
                SizedBox(height: 16),
                Text(
                  'Camera unavailable on this device',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'You can still test image transformations, opacity scaling, and toolbar actions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBB86FC)),
          ),
        ),
      );
    }

    // Wrap the camera preview in a FittedBox to fill the screen properly
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize!.height,
              height: _cameraController!.value.previewSize!.width,
              child: CameraPreview(_cameraController!),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverlayImage(String path, bool isAsset) {
    const double imgSize = 300;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        width: imgSize,
        height: imgSize,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const SizedBox(
            width: imgSize,
            height: imgSize,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBB86FC)),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(
            width: imgSize,
            height: imgSize,
            child: Center(
              child: Icon(Icons.broken_image, color: Colors.white30, size: 48),
            ),
          );
        },
      );
    } else if (isAsset || path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.contain,
        width: imgSize,
        height: imgSize,
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.contain,
        width: imgSize,
        height: imgSize,
      );
    }
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color iconColor = Colors.white,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white10),
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildTextActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? const Color(0xFFBB86FC) : Colors.black.withValues(alpha: 0.6),
        foregroundColor: isActive ? Colors.black : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(
            color: isActive ? const Color(0xFFBB86FC) : Colors.white10,
          ),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class SetupGuideDialog extends StatefulWidget {
  const SetupGuideDialog({super.key});

  @override
  State<SetupGuideDialog> createState() => _SetupGuideDialogState();
}

class _SetupGuideDialogState extends State<SetupGuideDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _steps = [
    {
      'icon': Icons.stay_primary_portrait,
      'title': '1. Elevate Phone',
      'desc': 'Place your phone on a stand, glass, or stack of books 4-6 inches above your drawing paper.',
    },
    {
      'icon': Icons.description_outlined,
      'title': '2. Align Paper',
      'desc': 'Place your physical paper flat on the table, centering it under the camera view.',
    },
    {
      'icon': Icons.gesture,
      'title': '3. Look & Trace',
      'desc': 'Look through the screen, adjust the opacity slider, and trace the projected lines with your pencil!',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF16161A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'How to Trace',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              width: double.maxFinite,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(step['icon'] as IconData, size: 48, color: const Color(0xFFBB86FC)),
                      const SizedBox(height: 16),
                      Text(
                        step['title'] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step['desc'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _steps.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index ? const Color(0xFFBB86FC) : Colors.white24,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  TextButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Text('Back', style: TextStyle(color: Colors.white38)),
                  )
                else
                  const SizedBox.shrink(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBB86FC),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (_currentPage < _steps.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('has_seen_setup_guide', true);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  child: Text(_currentPage == _steps.length - 1 ? 'Got it!' : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
