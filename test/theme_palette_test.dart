import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:banana/core/constants/app_assets.dart';
import 'package:banana/core/providers/theme_provider.dart';
import 'package:banana/core/theme/app_colors.dart';
import 'package:banana/core/theme/app_theme.dart';
import 'package:banana/core/theme/palette/dark_palette.dart';
import 'package:banana/core/theme/palette/light_palette.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Theme Palette Architecture Unit Tests', () {
    test('LightPalette should define Dark Green primary and Yellow secondary', () {
      const palette = LightPalette();

      expect(palette.brightness, Brightness.light);
      expect(palette.primary, const Color(0xFF0A3B2A)); // Dark green
      expect(palette.secondary, const Color(0xFFE6C925)); // Yellow
      expect(palette.onPrimary, const Color(0xFFFFFFFF)); // Crisp white text
      expect(palette.onSecondary, const Color(0xFF1A1C1C)); // Dark text on yellow
    });

    test('DarkPalette should flip accents: Yellow primary and Light Green secondary', () {
      const palette = DarkPalette();

      expect(palette.brightness, Brightness.dark);
      expect(palette.primary, const Color(0xFFFFE135)); // Flipped yellow for dark contrast
      expect(palette.secondary, const Color(0xFF16805B)); // Lighter green
      expect(palette.onPrimary, const Color(0xFF121313)); // Dark charcoal text on yellow
      expect(palette.onSecondary, const Color(0xFFFFFFFF)); // White text on green
    });

    test('AppColors facade should dynamically route between light and dark palettes', () {
      // Light mode test
      AppColors.isDark = false;
      expect(AppColors.primary, const Color(0xFF0A3B2A));
      expect(AppColors.secondary, const Color(0xFFE6C925));
      expect(AppColors.onPrimary, const Color(0xFFFFFFFF));

      // Dark mode test
      AppColors.isDark = true;
      expect(AppColors.primary, const Color(0xFFFFE135));
      expect(AppColors.secondary, const Color(0xFF16805B));
      expect(AppColors.onPrimary, const Color(0xFF121313));

      // Reset
      AppColors.isDark = false;
    });

    test('AppAssets should dynamically resolve transparent header logo in dark mode', () {
      expect(
        AppAssets.headerLogo(false),
        'assets/banana_logo_header.png',
      );
      expect(
        AppAssets.headerLogo(true),
        'assets/banana_logo_header_transparent.png',
      );

      // Using active AppColors state
      AppColors.isDark = false;
      expect(AppAssets.headerLogo(), 'assets/banana_logo_header.png');

      AppColors.isDark = true;
      expect(AppAssets.headerLogo(), 'assets/banana_logo_header_transparent.png');

      AppColors.isDark = false;
    });

    testWidgets('AppTheme should build valid ThemeData with matching color schemes', (tester) async {
      final lightTheme = AppTheme.light;
      final darkTheme = AppTheme.dark;

      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.colorScheme.primary, const Color(0xFF0A3B2A));
      expect(lightTheme.colorScheme.secondary, const Color(0xFFE6C925));

      expect(darkTheme.brightness, Brightness.dark);
      expect(darkTheme.colorScheme.primary, const Color(0xFFFFE135));
      expect(darkTheme.colorScheme.secondary, const Color(0xFF16805B));
    });

    test('ThemeModeNotifier should default to dark mode and toggle to light mode', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Default state must be dark mode
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(AppColors.isDark, isTrue);

      // Manually toggle in settings
      await container.read(themeModeProvider.notifier).toggle();
      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(AppColors.isDark, isFalse);

      // Toggle back to dark
      await container.read(themeModeProvider.notifier).toggle();
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(AppColors.isDark, isTrue);
    });
  });
}
