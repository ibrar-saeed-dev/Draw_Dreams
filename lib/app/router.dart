import 'package:flutter/material.dart';
import '../features/splash/splash_screen.dart';
import '../features/camera_overlay/camera_overlay_screen.dart';
import '../features/templates/templates_screen.dart';
import '../features/photo_import/photo_import_screen.dart';
import '../features/gallery/save_export_screen.dart';
import '../features/paywall/paywall_screen.dart';
import '../features/paywall/trial_offer_screen.dart';
import '../features/paywall/discount_offer_screen.dart';
import '../features/lessons/lessons_screen.dart';
import '../features/favourites/favourites_screen.dart';
import '../features/settings/settings_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String mainShell = '/main';
  static const String photoImport = '/photo-import';
  static const String trace = '/trace';
  static const String saveExport = '/save-export';
  static const String paywall = '/paywall';
  static const String trialOffer = '/trial-offer';
  static const String discountOffer = '/discount-offer';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
        );
      case mainShell:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainNavigationShell(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
        );
      case photoImport:
        return MaterialPageRoute(builder: (_) => const PhotoImportScreen());
      case trace:
        final args = settings.arguments as Map<String, dynamic>?;
        final imagePath = args?['imagePath'] as String?;
        final isAsset = args?['isAsset'] as bool? ?? true;
        return MaterialPageRoute(
          builder: (_) => CameraOverlayScreen(
            imagePath: imagePath,
            isAsset: isAsset,
          ),
        );
      case saveExport:
        final args = settings.arguments as Map<String, dynamic>?;
        final capturedImagePath = args?['capturedImagePath'] as String;
        final templateImagePath = args?['templateImagePath'] as String?;
        final isTemplateAsset = args?['isTemplateAsset'] as bool? ?? true;
        return MaterialPageRoute(
          builder: (_) => SaveExportScreen(
            capturedImagePath: capturedImagePath,
            templateImagePath: templateImagePath,
            isTemplateAsset: isTemplateAsset,
          ),
        );
      case paywall:
      case trialOffer:
        return PageRouteBuilder(
          opaque: false,
          pageBuilder: (context, animation, secondaryAnimation) => const TrialOfferScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        );
      case discountOffer:
        return PageRouteBuilder(
          opaque: false,
          pageBuilder: (context, animation, secondaryAnimation) => const DiscountOfferScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TemplatesScreen(),
    const LessonsScreen(),
    const FavouritesScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? const Color(0xFFBB86FC) : Theme.of(context).primaryColor;
    final unselectedColor = isDark ? Colors.white38 : Colors.black38;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: borderColor,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Theme.of(context).cardColor,
          selectedItemColor: selectedColor,
          unselectedItemColor: unselectedColor,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Templates',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              activeIcon: Icon(Icons.school),
              label: 'Lessons',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'My Drawings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

