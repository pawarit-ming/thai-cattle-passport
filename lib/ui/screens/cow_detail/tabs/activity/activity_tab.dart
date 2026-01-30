import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/services/cow_management/cow_activity/activity_service.dart';
import 'package:th_cow_passport/services/cow_management/models/activity_model.dart';

class ActivityTab extends ConsumerStatefulWidget {
  final int cowId;
  const ActivityTab({super.key, required this.cowId});

  @override
  ConsumerState<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends ConsumerState<ActivityTab> {
  ActivityType? _selectedType;
  int? _selectedMonth;
  int? _selectedYear;

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(activitiesProvider(widget.cowId));

    return activitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Error: $error')),
      data: (activities) {
        final filteredActivities = _filterActivities(activities);

        return Column(
          children: [
            _buildFilters(context),
            Expanded(
              child: filteredActivities.isEmpty
                  ? const Center(child: Text('ไม่มีกิจกรรม'))
                  : RefreshIndicator(
                      onRefresh: () => ref.refresh(activitiesProvider(widget.cowId).future),
                      child: ListView.builder(
                        padding: EdgeInsets.all(16.r),
                        itemCount: filteredActivities.length,
                        itemBuilder: (context, index) {
                          return _buildTimelineItem(context, filteredActivities[index],
                              isLast: index == filteredActivities.length - 1);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  List<Activity> _filterActivities(List<Activity> activities) {
    return activities.where((activity) {
      // Filter by type
      if (_selectedType != null && activity.activityType != _selectedType) {
        return false;
      }

      // Filter by month and year
      if (_selectedMonth != null && activity.activityDate.month != _selectedMonth) {
        return false;
      }
      if (_selectedYear != null && activity.activityDate.year != _selectedYear) {
        return false;
      }

      return true;
    }).toList();
  }

  Widget _buildFilters(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'กรองกิจกรรม',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),
          // Activity Type Dropdown (Full Width)
          DropdownButtonFormField<ActivityType>(
            initialValue: _selectedType,
            decoration: InputDecoration(
              labelText: 'ประเภทกิจกรรม',
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              prefixIcon: const Icon(Icons.category),
            ),
            items: [
              const DropdownMenuItem<ActivityType>(
                value: null,
                child: Text('ทั้งหมด'),
              ),
              ...ActivityType.values.map((type) => DropdownMenuItem<ActivityType>(
                    value: type,
                    child: Text(_getActivityTypeName(type)),
                  )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedType = value;
              });
            },
          ),
          SizedBox(height: 12.h),
          // Month and Year Row
          Row(
            children: [
              // Month Dropdown
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedMonth,
                  decoration: InputDecoration(
                    labelText: 'เดือน',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    prefixIcon: const Icon(Icons.calendar_view_month),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('ทั้งหมด'),
                    ),
                    ...List.generate(12, (index) => index + 1).map((month) => DropdownMenuItem<int>(
                          value: month,
                          child: Text(_getMonthName(month)),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedMonth = value;
                    });
                  },
                ),
              ),
              SizedBox(width: 12.w),
              // Year Dropdown
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedYear,
                  decoration: InputDecoration(
                    labelText: 'ปี',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('ทั้งหมด'),
                    ),
                    ...List.generate(10, (index) => DateTime.now().year - index).map((year) => DropdownMenuItem<int>(
                          value: year,
                          child: Text(year.toString()),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedYear = value;
                    });
                  },
                ),
              ),
            ],
          ),
          if (_selectedType != null || _selectedMonth != null || _selectedYear != null) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedType = null;
                      _selectedMonth = null;
                      _selectedYear = null;
                    });
                  },
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('ล้างตัวกรอง'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    textStyle: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    return months[month - 1];
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