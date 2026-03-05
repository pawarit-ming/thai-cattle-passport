import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppBadge extends StatelessWidget {
  final Widget child;
  final int count;
  final bool showBadge;
  final Color? badgeColor;

  const AppBadge({
    super.key,
    required this.child,
    this.count = 0,
    this.showBadge = true,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBadge || count == 0) {
      return child;
    }

    final effectiveColor = badgeColor ?? Theme.of(context).colorScheme.error;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -4.h,
          right: -8.w,
          child: Container(
            padding: EdgeInsets.all(4.r),
            decoration: BoxDecoration(
              color: effectiveColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 1.5,
              ),
            ),
            constraints: BoxConstraints(
              minWidth: 16.r,
              minHeight: 16.r,
            ),
            child: Center(
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
