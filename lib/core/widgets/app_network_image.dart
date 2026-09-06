import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';

/// [Image.network] with a consistent loading shimmer-ish placeholder and
/// error state, matching the muted `surface-container` fill used behind
/// every photo slot in the mockups before it loads.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
  });

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerHighest,
      child: Image.network(
        url,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Center(
          child: Icon(Symbols.image, color: AppColors.outline),
        ),
      ),
    );
  }
}
