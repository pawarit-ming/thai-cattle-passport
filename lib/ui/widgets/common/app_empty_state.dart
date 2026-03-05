import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? imageAsset;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const AppEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.imageAsset,
    this.buttonText,
    this.onButtonPressed,
  }) : assert(icon != null || imageAsset != null,
            'Either an icon or an imageAsset must be provided.');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image or Icon
            if (imageAsset != null)
              Opacity(
                opacity: 0.3, // Faded look for empty state
                child: Image.asset(
                  imageAsset!,
                  width: 120.r,
                  height: 120.r,
                  fit: BoxFit.contain,
                ),
              )
            else
              Icon(
                icon,
                size: 80.r,
                color: theme.disabledColor.withValues(alpha: 0.5),
              ),
            SizedBox(height: 24.h),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),

            // Subtitle
            if (subtitle != null) ...[
              SizedBox(height: 8.h),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],

            // Action Button
            if (buttonText != null && onButtonPressed != null) ...[
              SizedBox(height: 32.h),
              OutlinedButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.refresh),
                label: Text(buttonText!),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
