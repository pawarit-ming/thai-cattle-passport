import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppBadge extends StatelessWidget {
  final Widget child;
  final int count;
  final bool showBadge;
  final Color? badgeColor;

  final bool isDot;

  const AppBadge({
    super.key,
    required this.child,
    this.count = 0,
    this.showBadge = true,
    this.badgeColor,
    this.isDot = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBadge || (count == 0 && !isDot)) {
      return child;
    }

    final effectiveColor = badgeColor ?? Theme.of(context).colorScheme.error;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -4.h,
          right: isDot ? -4.w : -8.w,
          child: Container(
            padding: isDot ? EdgeInsets.zero : EdgeInsets.all(4.r),
            decoration: BoxDecoration(
              color: effectiveColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 1.5,
              ),
            ),
            constraints: isDot
                ? BoxConstraints(minWidth: 10.r, minHeight: 10.r)
                : BoxConstraints(minWidth: 16.r, minHeight: 16.r),
            child: isDot
                ? null
                : Center(
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: GoogleFonts.prompt(
                        color: Colors.white,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold,
                        height: 1, // Minimize vertical padding
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
