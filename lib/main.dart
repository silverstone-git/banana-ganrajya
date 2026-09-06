import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/api_config.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.resolveDebugBaseUrl();
  runApp(const ProviderScope(child: BananaGanrajyaApp()));
}

class BananaGanrajyaApp extends ConsumerWidget {
  const BananaGanrajyaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Dynamically calculate if dark mode is active based on the user's manual 
    // overrides (light/dark) or default to the platform brightness (system).
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final bool isDarkActive = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && platformBrightness == Brightness.dark);

    // Apply the active state to the dynamic AppColors engine
    AppColors.isDark = isDarkActive;

    return MaterialApp.router(
      title: 'BananaGanrajya',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
