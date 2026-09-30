import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../app/router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for splash animation to show
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Check camera permission
    bool hasPermission = await _requestCameraPermission();

    if (mounted) {
      final navigator = Navigator.of(context);
      if (hasPermission) {
        navigator.pushReplacementNamed(AppRouter.mainShell);
      } else {
        // Show dialog alerting user camera is required for tracing
        _showPermissionRequiredDialog();
      }
    }
  }

  Future<bool> _requestCameraPermission() async {
    try {
      final cameras = await availableCameras();
      return cameras.isNotEmpty;
    } catch (e) {
      debugPrint("Camera permission error: $e");
      return false;
    }
  }

  void _showPermissionRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'This app uses your camera to overlay tracing lines on your paper. Please enable camera access in your device settings to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              navigator.pop();
              bool retried = await _requestCameraPermission();
              if (retried && mounted) {
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed(AppRouter.mainShell);
                }
              } else {
                if (mounted) {
                  _showPermissionRequiredDialog();
                }
              }
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6D42CF),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Premium Logo Card
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              const Text(
                'DRAW DREAMS',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bring your imagination to paper',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
