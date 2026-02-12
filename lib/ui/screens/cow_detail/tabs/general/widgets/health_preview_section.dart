import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/services/cow_management/cow_activity/activity_service.dart';
import 'package:th_cow_passport/services/cow_management/models/activity_model.dart';
import 'package:th_cow_passport/ui/screens/activity/widgets/activity_card.dart';

class HealthPreviewSection extends ConsumerWidget {
  final int cowId;

  const HealthPreviewSection({super.key, required this.cowId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activitiesAsync = ref.watch(activitiesProvider(cowId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
          child: Text(
            'สุขภาพล่าสุด',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
        activitiesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
              child:
                  Text('Error: $error', style: TextStyle(color: Colors.red))),
          data: (activities) {
            // Filter only VACCINE and TREATMENT
            final healthActivities = activities
                .where((a) =>
                    a.activityType == ActivityType.VACCINE ||
                    a.activityType == ActivityType.TREATMENT ||
                    a.activityType == ActivityType.SICKNESS)
                .toList();

            if (healthActivities.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(16.r),
                child: Center(
                  child: Text(
                    'ไม่มีข้อมูลสุขภาพ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              );
            }

            final showViewMore = healthActivities.length > 5;
            final displayList = showViewMore
                ? healthActivities.take(5).toList()
                : healthActivities;

            return Column(
              children: [
                ...displayList.map((activity) => ActivityCard(
                      activity: activity,
                      isLast: activity == displayList.last && !showViewMore,
                    )),
                if (showViewMore)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          // Navigate to full HealthTab view
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                appBar:
                                    AppBar(title: const Text('ข้อมูลสุขภาพ')),
                                body: HealthTab(cowId: cowId),
                              ),
                            ),
                          );
                        },
                        child: const Text('ดูเพิ่มเติม'),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class HealthTab extends ConsumerWidget {
  final int cowId;

  const HealthTab({super.key, required this.cowId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: theme.scaffoldBackgroundColor,
            child: TabBar(
              labelColor: colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: colorScheme.primary,
              indicatorWeight: 3.h,
              labelStyle: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                fontFamily:
                    'Kanit', // Ensure consistency if global font is not set
              ),
              tabs: const [
                Tab(text: 'วัคซีน'),
                Tab(text: 'รักษาโรค'),
                Tab(text: 'ป่วย'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildActivityList(ref, ActivityType.VACCINE),
                _buildActivityList(ref, ActivityType.TREATMENT),
                _buildActivityList(ref, ActivityType.SICKNESS),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(WidgetRef ref, ActivityType type) {
    final activitiesAsync = ref.watch(activitiesProvider(cowId));

    return activitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Error: $error')),
      data: (activities) {
        final filteredActivities = activities
            .where((activity) => activity.activityType == type)
            .toList();

        if (filteredActivities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medical_services_outlined,
                    size: 48.r, color: Colors.grey[400]),
                SizedBox(height: 16.h),
                Text(
                  'ไม่มีข้อมูล${type == ActivityType.VACCINE ? 'การฉีดวัคซีน' : type == ActivityType.TREATMENT ? 'การรักษา' : 'การป่วย'}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(activitiesProvider(cowId).future),
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
        );
      },
    );
  }
}
