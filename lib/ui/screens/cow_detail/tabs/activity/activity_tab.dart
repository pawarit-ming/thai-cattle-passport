import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/services/cow_management/cow_activity/activity_service.dart';
import 'package:th_cow_passport/services/cow_management/models/activity_model.dart';
import 'package:th_cow_passport/ui/screens/activity/widgets/activity_card.dart';

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
                      onRefresh: () =>
                          ref.refresh(activitiesProvider(widget.cowId).future),
                      child: ListView.builder(
                        padding: EdgeInsets.all(16.r),
                        itemCount: filteredActivities.length,
                        itemBuilder: (context, index) {
                          return ActivityCard(
                            activity: filteredActivities[index],
                            isLast: index == filteredActivities.length - 1,
                          );
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
      if (_selectedMonth != null &&
          activity.activityDate.month != _selectedMonth) {
        return false;
      }
      if (_selectedYear != null &&
          activity.activityDate.year != _selectedYear) {
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
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
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
              ...ActivityType.values
                  .map((type) => DropdownMenuItem<ActivityType>(
                        value: type,
                        child: Text(_getActivityLabel(type)),
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
                flex: 3,
                child: DropdownButtonFormField<int>(
                  isExpanded:
                      true, // Fix overflow by allowing text to truncate/wrap if needed
                  initialValue: _selectedMonth,
                  decoration: InputDecoration(
                    labelText: 'เดือน',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
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
                    ...List.generate(12, (index) => index + 1)
                        .map((month) => DropdownMenuItem<int>(
                              value: month,
                              child: Text(_getMonthName(month),
                                  overflow: TextOverflow.ellipsis),
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
                flex: 2,
                child: DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _selectedYear,
                  decoration: InputDecoration(
                    labelText: 'ปี',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
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
                    ...List.generate(5, (index) => DateTime.now().year - index)
                        .map((year) => DropdownMenuItem<int>(
                              value: year,
                              child: Text(
                                  (year + 543).toString()), // Buddhist Year
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
          if (_selectedType != null ||
              _selectedMonth != null ||
              _selectedYear != null) ...[
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

  String _getActivityLabel(ActivityType type) {
    switch (type) {
      case ActivityType.VACCINE:
        return 'ฉีดวัคซีน';
      case ActivityType.TREATMENT:
        return 'รักษาโรค';
      case ActivityType.BIRTH:
        return 'การเกิด';
      case ActivityType.WEIGHT_UPDATE:
        return 'ชั่งน้ำหนัก';
      case ActivityType.BREEDING:
        return 'ผสมพันธุ์';
      case ActivityType.PREGNANCY_CHECK:
        return 'ตรวจท้อง';
      case ActivityType.DEATH:
        return 'ตาย';
      case ActivityType.SOLD:
        return 'ขายออก';
      case ActivityType.EDIT_LOG:
        return 'แก้ไขประวัติ';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.'
    ];
    return months[month - 1];
  }
}
