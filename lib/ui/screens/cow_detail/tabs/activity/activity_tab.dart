import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/services/cow_management/cow_activity/activity_service.dart';
import 'package:th_cow_passport/services/cow_management/cow_list/cow_list_service.dart';
import 'package:th_cow_passport/services/cow_management/models/activity_model.dart';
import 'package:th_cow_passport/ui/screens/activity/widgets/activity_card.dart';
import 'package:th_cow_passport/ui/widgets/common/app_dropdown.dart';

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
        // Build cow lookup for display
        final allCows = ref.watch(cowServiceProvider).cows;
        final cowLookup = {
          for (final c in allCows)
            if (c.animalId != null) c.animalId!: c.nidNumber,
        };

        return RefreshIndicator(
          onRefresh: () => ref.refresh(activitiesProvider(widget.cowId).future),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            // เพิ่มจำนวน itemCount อีก 1 สำหรับตัวกรอง
            itemCount:
                filteredActivities.isEmpty ? 2 : filteredActivities.length + 1,
            itemBuilder: (context, index) {
              // --- ลำดับที่ 0: แสดงตัวกรอง (จะเลื่อนหายไปเมื่อ scroll) ---
              if (index == 0) {
                return _buildFilters(context);
              }

              // --- กรณีไม่มีข้อมูลกิจกรรม ( index == 1 และรายการว่าง) ---
              if (filteredActivities.isEmpty) {
                return SizedBox(
                  height: 300.h,
                  child: const Center(child: Text('ไม่มีกิจกรรม')),
                );
              }

              // --- รายการกิจกรรม ( index เริ่มที่ 1, 2, 3... ) ---
              final activity = filteredActivities[index - 1];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: ActivityCard(
                  activity: activity,
                  isLast: index - 1 == filteredActivities.length - 1,
                  cowLookup: cowLookup,
                ),
              );
            },
          ),
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 12.h),
          // Activity Type Dropdown (Full Width)
          AppDropdown<ActivityType>(
            label: 'ประเภทกิจกรรม',
            value: _selectedType,
            prefixIcon: const Icon(Icons.category),
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
          // Month and Year Row
          Row(
            children: [
              // Month Dropdown
              Expanded(
                flex: 1,
                child: AppDropdown<int>(
                  label: 'เดือน',
                  value: _selectedMonth,
                  prefixIcon: const Icon(Icons.calendar_view_month),
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
                flex: 1,
                child: AppDropdown<int>(
                  label: 'ปี',
                  value: _selectedYear,
                  prefixIcon: const Icon(Icons.calendar_today),
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
      case ActivityType.SICKNESS:
        return 'บันทึกการป่วย';
      case ActivityType.TREATMENT:
        return 'การรักษา';
      case ActivityType.BIRTH:
        return 'คลอดลูก';
      case ActivityType.WEIGHT_UPDATE:
        return 'บันทึกน้ำหนัก';
      case ActivityType.BREEDING:
        return 'ผสมพันธุ์';
      case ActivityType.PREGNANCY_CHECK:
        return 'การตรวจครรภ์';
      case ActivityType.DEATH:
        return 'ตาย';
      case ActivityType.SOLD:
        return 'ขาย';
      case ActivityType.EDIT_LOG:
        return 'ประวัติการแก้ไข';
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
