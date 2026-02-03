import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/services/cow_management/models/activity_model.dart';
import 'package:th_cow_passport/ui/screens/activity/activity_extensions.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final bool isLast;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = activity.activityType.color;
    final icon = activity.activityType.icon;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimelineLine(color, icon),
          SizedBox(width: 16.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme, colorScheme),
                  SizedBox(height: 4.h),
                  Text(
                    activity.activityType.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  _buildDescription(theme),
                  if (activity.data.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    _buildDataCard(context, activity.data),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineLine(Color color, IconData icon) {
    return Column(
      children: [
        Container(
          width: 40.r,
          height: 40.r,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 20.r),
        ),
        if (!isLast)
          Expanded(
            child: Container(
              width: 2.w,
              color: Colors.grey.shade300,
              margin: EdgeInsets.symmetric(vertical: 4.h),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Text(
          '${activity.activityDate.day}/${activity.activityDate.month}/${activity.activityDate.year}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          '${activity.activityDate.hour}:${activity.activityDate.minute.toString().padLeft(2, '0')}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(ThemeData theme) {
    if (activity.description != null && activity.description!.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 4.h),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            activity.description!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDataCard(BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final entries = data.entries
        .where(
            (entry) => entry.value != null && entry.value.toString().isNotEmpty)
        .toList();

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: entries.map((entry) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getTranslatedDataKey(entry.key)}: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold, color: theme.hintColor),
                ),
                Expanded(
                  child: Text(
                    '${entry.value}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getTranslatedDataKey(String key) {
    switch (key) {
      case 'vaccine_name':
        return 'ชื่อวัคซีน';
      case 'calf_gender':
        return 'เพศลูกวัว';
      case 'calf_nid':
        return 'เลขประจำตัวลูกวัว';
      case 'calf_birth_weight':
        return 'น้ำหนักแรกเกิด (กก.)';
      case 'symptoms':
        return 'อาการ';
      case 'treatment_details':
        return 'รายละเอียดการรักษา';
      case 'details':
        return 'รายละเอียด';
      default:
        return key;
    }
  }
}
