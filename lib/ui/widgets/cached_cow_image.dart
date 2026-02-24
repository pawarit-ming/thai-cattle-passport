import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A reusable cached image widget for displaying cow photos.
///
/// Uses [CachedNetworkImage] for disk & memory caching, lazy loading,
/// shimmer placeholder, and smooth fade-in animation.
class CachedCowImage extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final Widget? fallbackWidget;

  const CachedCowImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallback(theme);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius.r),
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width.r,
        height: height.r,
        fit: BoxFit.cover,
        // Smooth fade-in when image loads
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
        // Placeholder: subtle shimmer/skeleton
        placeholder: (context, url) => Container(
          width: width.r,
          height: height.r,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(borderRadius.r),
          ),
          child: Center(
            child: SizedBox(
              width: 20.r,
              height: 20.r,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        // Error fallback
        errorWidget: (context, url, error) => _buildFallback(theme),
      ),
    );
  }

  Widget _buildFallback(ThemeData theme) {
    if (fallbackWidget != null) return fallbackWidget!;

    return Container(
      width: width.r,
      height: height.r,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(borderRadius.r),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Image.asset(
          'assets/images/cow.png',
          width: (width * 0.6).r,
          height: (height * 0.6).r,
        ),
      ),
    );
  }
}
