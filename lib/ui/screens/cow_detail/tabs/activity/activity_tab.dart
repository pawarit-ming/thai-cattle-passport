import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/services/cow_management/cow_activity/activity_service.dart';
import 'package:th_cow_passport/services/cow_management/models/activity_model.dart';

class ActivityTab extends ConsumerWidget {
  final int cowId;
  const ActivityTab({super.key, required this.cowId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesProvider(cowId));

    return activitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Error: $error')),
      data: (activities) {
        if (activities.isEmpty) {
          return const Center(child: Text('ไม่มีกิจกรรม'));
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(activitiesProvider(cowId).future),
          child: ListView.builder(
            padding: EdgeInsets.all(16.r),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              return _buildTimelineItem(context, activities[index],
                  isLast: index == activities.length - 1);
            },
          ),
        );
      },
    );
  }

  String _getActivityTypeName(ActivityType type) {
    switch (type) {
      case ActivityType.VACCINE:
        return 'ฉีดวัคซีน';
      case ActivityType.BIRTH:
        return 'การเกิด';
      case ActivityType.TREATMENT:
        return 'การรักษา';
      case ActivityType.EDIT_LOG:
        return 'ประวัติการแก้ไข';
      case ActivityType.PREGNANCY_CHECK:
        return 'ตรวจการตั้งท้อง';
      case ActivityType.BREEDING:
        return 'ผสมพันธุ์';
      case ActivityType.WEIGHT_UPDATE:
        return 'ปรับปรุงน้ำหนัก';
      case ActivityType.SOLD:
        return 'ขาย';
      case ActivityType.DEATH:
        return 'ตายแล้ว';
    }
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
      default:
        return key;
    }
  }

  Widget _buildTimelineItem(BuildContext context, Activity item,
      {required bool isLast}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    IconData icon;
    Color color;
    switch (item.activityType) {
      case ActivityType.VACCINE:
        icon = Icons.medical_services_outlined;
        color = Colors.blue;
        break;
      case ActivityType.BIRTH:
        icon = Icons.child_friendly;
        color = Colors.pink;
        break;
      case ActivityType.TREATMENT:
        icon = Icons.healing;
        color = Colors.orange;
        break;
      case ActivityType.EDIT_LOG:
        icon = Icons.edit_note;
        color = Colors.purple;
        break;
      case ActivityType.PREGNANCY_CHECK:
        icon = Icons.pregnant_woman;
        color = Colors.green;
        break;
      case ActivityType.WEIGHT_UPDATE:
        icon = Icons.monitor_weight;
        color = Colors.teal;
        break;
      case ActivityType.SOLD:
        icon = Icons.sell;
        color = Colors.brown;
        break;
      case ActivityType.BREEDING:
        icon = Icons.favorite;
        color = Colors.red;
        break;
      case ActivityType.DEATH:
        icon = Icons.close_outlined;
        color = Colors.grey;
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.3)),
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
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${item.activityDate.day}/${item.activityDate.month}/${item.activityDate.year}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '${item.activityDate.hour}:${item.activityDate.minute.toString().padLeft(2, '0')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _getActivityTypeName(item.activityType),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  if (item.description != null && item.description!.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        item.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                  if (item.data.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    _buildDataCard(context, item.data),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final entries = data.entries
        .where((entry) => entry.value != null && entry.value.toString().isNotEmpty)
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
}