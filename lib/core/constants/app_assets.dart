import '../theme/app_colors.dart';

/// Centralized catalog for static local assets used across Banana Ganrajya.
class AppAssets {
  AppAssets._();

  /// Square favicon icon
  static const String favicon = 'assets/images/banana_favicon.png';

  /// Horizontal header logo for light backgrounds
  static const String headerLogoLight = 'assets/banana_logo_header.png';

  /// Transparent horizontal header logo for dark mode
  static const String headerLogoDark = 'assets/banana_logo_header_transparent.png';

  /// Dynamic resolver: In dark mode, uses 'assets/banana_logo_header_transparent.png'.
  /// In light mode, uses 'assets/banana_logo_header.png'.
  static String headerLogo([bool? isDark]) {
    final dark = isDark ?? AppColors.isDark;
    return dark ? headerLogoDark : headerLogoLight;
  }
}
