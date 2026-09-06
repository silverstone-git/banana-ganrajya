import 'package:flutter/material.dart';

/// Abstract contract defining all color tokens for Banana Ganrajya.
/// Implementations (e.g. [LightPalette], [DarkPalette]) provide concrete values
/// ensuring clean separation of concerns and modularity.
abstract class AppPalette {
  const AppPalette();

  Brightness get brightness;

  // Primary
  Color get primary;
  Color get onPrimary;
  Color get primaryContainer;
  Color get onPrimaryContainer;
  Color get inversePrimary;
  Color get primaryFixed;
  Color get primaryFixedDim;
  Color get onPrimaryFixed;
  Color get onPrimaryFixedVariant;
  Color get surfaceTint;

  // Secondary
  Color get secondary;
  Color get onSecondary;
  Color get secondaryContainer;
  Color get onSecondaryContainer;
  Color get secondaryFixed;
  Color get secondaryFixedDim;
  Color get onSecondaryFixed;
  Color get onSecondaryFixedVariant;

  // Tertiary
  Color get tertiary;
  Color get onTertiary;
  Color get tertiaryContainer;
  Color get onTertiaryContainer;
  Color get tertiaryFixed;
  Color get tertiaryFixedDim;
  Color get onTertiaryFixed;
  Color get onTertiaryFixedVariant;

  // Surface & Containers
  Color get surface;
  Color get surfaceDim;
  Color get surfaceBright;
  Color get surfaceContainerLowest;
  Color get surfaceContainerLow;
  Color get surfaceContainer;
  Color get surfaceContainerHigh;
  Color get surfaceContainerHighest;
  Color get surfaceVariant;

  Color get onSurface;
  Color get onSurfaceVariant;
  Color get inverseSurface;
  Color get inverseOnSurface;

  // Outline
  Color get outline;
  Color get outlineVariant;

  // Error
  Color get error;
  Color get onError;
  Color get errorContainer;
  Color get onErrorContainer;

  // Background
  Color get background;
  Color get onBackground;

  // FinePrint Brand (Editorial Gold to Deep Purple)
  Color get fineprintGold => const Color(0xFFDDAC2E);
  Color get fineprintPurple => const Color(0xFF4722A5);

  LinearGradient get fineprintGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [fineprintGold, fineprintPurple],
      );
}
