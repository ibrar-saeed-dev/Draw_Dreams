import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/router.dart';
import '../../app/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleTextColor = isDark ? Colors.white : Colors.black87;
    final scaffoldBgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F7);
    final cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final cardBorderColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.transparent;
    final dividerColor = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.settings,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: titleTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Top Banner Card
                GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed(AppRouter.paywall),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Unlock Your\nCreativity',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  'Get PRO',
                                  style: const TextStyle(
                                    color: Color(0xFF7C3AED),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                'assets/images/app_logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  LucideIcons.palette,
                                  color: Colors.white54,
                                  size: 64,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Level/progress bar below the banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            LucideIcons.sparkles,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Lv. 1 · Beginner',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '0/20',
                          style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Settings list container
                Container(
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: cardBorderColor),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            )
                          ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _buildSettingsRow(
                        icon: LucideIcons.share2,
                        label: 'Share',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sharing AR Draw & Trace...')),
                          );
                        },
                      ),
                      Divider(height: 1, color: dividerColor, indent: 16, endIndent: 16),
                      _buildSettingsRow(
                        icon: LucideIcons.mail,
                        label: 'Contact us',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Support email: support@artrace.com')),
                          );
                        },
                      ),
                      Divider(height: 1, color: dividerColor, indent: 16, endIndent: 16),
                      _buildSettingsRow(
                        icon: LucideIcons.fileText,
                        label: 'Terms of use',
                        onTap: () async {
                          final uri = Uri.parse('https://ibrar-saeed-dev.github.io/Draw-AR-Sketch-app-legal/terms.html');
                          try {
                            bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                            if (!launched) {
                              launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
                            }
                            if (!launched && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not open link')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error launching link: $e')),
                              );
                            }
                          }
                        },
                      ),
                      Divider(height: 1, color: dividerColor, indent: 16, endIndent: 16),
                      _buildSettingsRow(
                        icon: LucideIcons.shieldCheck,
                        label: 'Privacy policy',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Opening Privacy Policy...')),
                          );
                        },
                      ),
                      Divider(height: 1, color: dividerColor, indent: 16, endIndent: 16),
                      _buildSettingsRow(
                        icon: LucideIcons.star,
                        label: 'Rate us',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Thank you for your rating!')),
                          );
                        },
                      ),
                      Divider(height: 1, color: dividerColor, indent: 16, endIndent: 16),
                      _buildSettingsRow(
                        icon: LucideIcons.messageSquare,
                        label: 'How to use AR Draw & Trace',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Opening drawing guide...')),
                          );
                        },
                      ),
                      const SizedBox(height: 8), // No divider before Notification
                      _buildSettingsRow(
                        icon: LucideIcons.bell,
                        label: 'Notification',
                        trailing: Switch(
                          value: _notificationsEnabled,
                          onChanged: (val) {
                            setState(() {
                              _notificationsEnabled = val;
                            });
                          },
                          activeThumbColor: const Color(0xFF7C3AED),
                          activeTrackColor: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: const Color(0xFFD1D5DB),
                        ),
                      ),
                      Divider(height: 1, color: dividerColor, indent: 16, endIndent: 16),
                      _buildSettingsRow(
                        icon: themeMode == ThemeMode.dark ? LucideIcons.moon : LucideIcons.sun,
                        label: 'Theme',
                        trailing: Switch(
                          value: themeMode == ThemeMode.dark,
                          onChanged: (val) {
                            ref.read(themeModeProvider.notifier).toggleTheme(val);
                          },
                          activeThumbColor: const Color(0xFF7C3AED),
                          activeTrackColor: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: const Color(0xFFD1D5DB),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white : const Color(0xFF1F2937);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Icon(
                  icon,
                  color: const Color(0xFF7C3AED),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            trailing ??
                const Icon(
                  LucideIcons.chevronRight,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }
}
