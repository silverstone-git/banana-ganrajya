import 'package:flutter/material.dart';

import 'palette/app_palette.dart';
import 'palette/dark_palette.dart';
import 'palette/light_palette.dart';

/// Design tokens facade for Banana Ganrajya.
///
/// Delegates all semantic color queries to the active [AppPalette] implementation,
/// providing clean separation of concerns and high modularity.
class AppColors {
  AppColors._();

  static const AppPalette lightPalette = LightPalette();
  static const AppPalette darkPalette = DarkPalette();

  /// Reactive state setter to drive the theme mode change across static colors
  static bool isDark = false;

  /// Current active palette based on the [isDark] state
  static AppPalette get currentPalette => isDark ? darkPalette : lightPalette;

  // Surfaces
  static Color get surface => currentPalette.surface;
  static Color get surfaceDim => currentPalette.surfaceDim;
  static Color get surfaceBright => currentPalette.surfaceBright;
  static Color get surfaceContainerLowest => currentPalette.surfaceContainerLowest;
  static Color get surfaceContainerLow => currentPalette.surfaceContainerLow;
  static Color get surfaceContainer => currentPalette.surfaceContainer;
  static Color get surfaceContainerHigh => currentPalette.surfaceContainerHigh;
  static Color get surfaceContainerHighest => currentPalette.surfaceContainerHighest;

  static Color get onSurface => currentPalette.onSurface;
  static Color get onSurfaceVariant => currentPalette.onSurfaceVariant;
  static Color get inverseSurface => currentPalette.inverseSurface;
  static Color get inverseOnSurface => currentPalette.inverseOnSurface;

  // Outline
  static Color get outline => currentPalette.outline;
  static Color get outlineVariant => currentPalette.outlineVariant;
  static Color get surfaceVariant => currentPalette.surfaceVariant;

  // Primary Accent
  static Color get primary => currentPalette.primary;
  static Color get onPrimary => currentPalette.onPrimary;
  static Color get primaryContainer => currentPalette.primaryContainer;
  static Color get onPrimaryContainer => currentPalette.onPrimaryContainer;
  static Color get inversePrimary => currentPalette.inversePrimary;
  static Color get primaryFixed => currentPalette.primaryFixed;
  static Color get primaryFixedDim => currentPalette.primaryFixedDim;
  static Color get onPrimaryFixed => currentPalette.onPrimaryFixed;
  static Color get onPrimaryFixedVariant => currentPalette.onPrimaryFixedVariant;
  static Color get surfaceTint => currentPalette.surfaceTint;

  // Secondary Accent
  static Color get secondary => currentPalette.secondary;
  static Color get onSecondary => currentPalette.onSecondary;
  static Color get secondaryContainer => currentPalette.secondaryContainer;
  static Color get onSecondaryContainer => currentPalette.onSecondaryContainer;
  static Color get secondaryFixed => currentPalette.secondaryFixed;
  static Color get secondaryFixedDim => currentPalette.secondaryFixedDim;
  static Color get onSecondaryFixed => currentPalette.onSecondaryFixed;
  static Color get onSecondaryFixedVariant => currentPalette.onSecondaryFixedVariant;

  // Tertiary
  static Color get tertiary => currentPalette.tertiary;
  static Color get onTertiary => currentPalette.onTertiary;
  static Color get tertiaryContainer => currentPalette.tertiaryContainer;
  static Color get onTertiaryContainer => currentPalette.onTertiaryContainer;
  static Color get tertiaryFixed => currentPalette.tertiaryFixed;
  static Color get tertiaryFixedDim => currentPalette.tertiaryFixedDim;
  static Color get onTertiaryFixed => currentPalette.onTertiaryFixed;
  static Color get onTertiaryFixedVariant => currentPalette.onTertiaryFixedVariant;

  // Error
  static Color get error => currentPalette.error;
  static Color get onError => currentPalette.onError;
  static Color get errorContainer => currentPalette.errorContainer;
  static Color get onErrorContainer => currentPalette.onErrorContainer;

  // Background
  static Color get background => currentPalette.background;
  static Color get onBackground => currentPalette.onBackground;

  // FinePrint (premium subscriber) brand gradient — gold to deep purple
  static const fineprintGold = Color(0xFFDDAC2E);
  static const fineprintPurple = Color(0xFF4722A5);

  static const fineprintGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [fineprintGold, fineprintPurple],
  );
}
