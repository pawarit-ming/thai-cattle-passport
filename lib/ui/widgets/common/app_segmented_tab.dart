import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppSegmentedTab extends StatelessWidget {
  final TabController controller;
  final List<Tab> tabs;

  const AppSegmentedTab({
    super.key,
    required this.controller,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: theme.cardColor, // Background color for the unselected track
        borderRadius: BorderRadius.circular(25.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: controller,
        tabs: tabs,
        labelColor: colorScheme.onPrimary,
        unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
        indicatorSize: TabBarIndicatorSize.tab, // Fill the segment
        dividerColor: Colors.transparent, // Remove the default bottom line
        indicator: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(25.r),
        ),
        splashBorderRadius: BorderRadius.circular(25.r),
      ),
    );
  }
}
