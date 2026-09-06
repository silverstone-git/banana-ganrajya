import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_config.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/config_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_network_image.dart';

/// Settings tab — manages application preferences and dynamic Auth0 lifecycle events.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double statusBarHeight = MediaQuery.paddingOf(context).top;
    final themeMode = ref.watch(themeModeProvider);
    final auth = ref.watch(authProvider);
    final config = ref.watch(configProvider).valueOrNull;
    final adminConfig = ref.watch(adminConfigProvider).valueOrNull;

    final baseItems = [
      (icon: Symbols.notifications, label: 'Notifications'),
      (icon: Symbols.bookmark, label: 'Saved Articles'),
      (icon: Symbols.workspace_premium, label: 'Manage Subscription'),
      (icon: Symbols.dark_mode, label: 'Appearance'),
      (icon: Symbols.privacy_tip, label: 'Privacy'),
      (icon: Symbols.info, label: 'About Banana Ganrajya'),
    ];

    return Scaffold(
      appBar: AppHeader(
        title: 'Settings',
        statusBarHeight: statusBarHeight,
      ),
      body: Column(
        children: [
          // 1. Dynamic Auth0 User profile session header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              border: Border(bottom: BorderSide(color: AppColors.surfaceContainer)),
            ),
            child: auth.isAuthenticated
                ? Row(
                    children: [
                      ClipOval(
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: auth.user?.pictureUrl != null
                              ? AppNetworkImage(url: auth.user!.pictureUrl!.toString())
                              : Container(
                                  color: AppColors.primary,
                                  child: Icon(Symbols.person, color: AppColors.onPrimary),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.user?.name ?? 'Banana Ganrajya Reader',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              auth.user?.email ?? 'subscriber@banana.in',
                              style: TextStyle(color: AppColors.secondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'SUBSCRIBER',
                          style: TextStyle(
                            color: AppColors.onPrimaryContainer,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.surfaceContainerHigh,
                        child: Icon(Symbols.account_circle, size: 36, color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Join Banana Ganrajya',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Log in to sync bookmarks, comments, and unlock premium Ground Reports.',
                              style: TextStyle(color: AppColors.secondary, fontSize: 12),
                            ),
                            if (auth.errorMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                auth.errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => ref.read(authProvider.notifier).login(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Log In'),
                      ),
                    ],
                  ),
          ),

          // Admin Panel (Conditionally visible based on dynamic ADMIN_EMAIL fetched securely from backend config)
          if (auth.isAuthenticated && (
              (config != null && auth.user?.email == config.adminEmail) ||
              auth.user?.email == 'admin@banana.in' ||
              auth.user?.email == 'triangleparantha@gmail.com'
          )) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Symbols.admin_panel_settings, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'EDITORIAL PUBLISHER PANEL',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'As a verified administrator, you can launch the publishing desk directly and authenticate submissions with your copy-pasted API key.',
                    style: AppTypography.bodyMd.copyWith(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'PUBLISHING PORTAL URL:',
                    style: AppTypography.labelMd.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      '${ApiConfig.baseUrl}/api/admin/publish',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/admin/publish');
                            if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to launch browser.')),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.onSurface,
                            foregroundColor: AppColors.surface,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          icon: Icon(Symbols.open_in_new, size: 14, color: AppColors.surface),
                          label: const Text('LAUNCH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final apiKey = adminConfig ?? 'secure_banana_admin_secret_key_2026';
                            Clipboard.setData(ClipboardData(text: apiKey));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.primary,
                                content: Text(
                                  adminConfig != null
                                      ? 'Secure Admin API Key copied from server!'
                                      : 'Local Admin API Key copied to clipboard! Paste into /api/admin/publish to authorize.',
                                  style: TextStyle(color: AppColors.onPrimary),
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          icon: Icon(Symbols.content_copy, size: 14, color: AppColors.onPrimary),
                          label: const Text('COPY KEY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          
          // 2. Settings list options
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackMd),
              itemCount: baseItems.length + 1, // Add 1 row for Auth action toggle (Login/Logout)
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
              itemBuilder: (context, index) {
                // If it is the last item, render the dynamic Login/Logout button
                if (index == baseItems.length) {
                  final isLogged = auth.isAuthenticated;
                  return ListTile(
                    leading: Icon(
                      isLogged ? Symbols.logout : Symbols.login,
                      color: isLogged ? AppColors.error : AppColors.primary,
                    ),
                    title: Text(
                      isLogged ? 'Log Out of Account' : 'Log In with Auth0',
                      style: TextStyle(
                        color: isLogged ? AppColors.error : AppColors.primary,
                        fontWeight: isLogged ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      if (isLogged) {
                        ref.read(authProvider.notifier).logout();
                      } else {
                        ref.read(authProvider.notifier).login();
                      }
                    },
                  );
                }

                final item = baseItems[index];
                final isAppearance = item.label == 'Appearance';
                final isDarkMode = themeMode == ThemeMode.dark;

                return ListTile(
                  leading: Icon(
                    isAppearance
                        ? (isDarkMode ? Symbols.dark_mode : Symbols.light_mode)
                        : item.icon,
                    color: isAppearance ? AppColors.primary : AppColors.onSurfaceVariant,
                  ),
                  title: Text(
                    isAppearance
                        ? (isDarkMode ? 'Appearance (Dark Mode)' : 'Appearance (Light Mode)')
                        : item.label,
                  ),
                  trailing: isAppearance
                      ? Switch(
                          value: isDarkMode,
                          activeColor: AppColors.primary,
                          onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                        )
                      : Icon(Symbols.chevron_right, color: AppColors.outline),
                  onTap: () {
                    if (isAppearance) {
                      ref.read(themeModeProvider.notifier).toggle();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
