import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:th_cow_passport/services/cow_management/models/activity_model.dart';

class AddActivityModal extends StatelessWidget {
  final int cowId;
  const AddActivityModal({super.key, required this.cowId});

  void _navigateToForm(BuildContext context, ActivityType type) {
    Navigator.of(context).pop(); // ปิด Modal ก่อน
    context.push('/add-activity/$cowId', extra: type);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'เลือกประเภทกิจกรรม',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16.r,
                mainAxisSpacing: 16.r,
                childAspectRatio: 1.2,
                children: [
                  _ActivityCard(
                    label: 'ฉีดวัคซีน',
                    icon: Icons.vaccines,
                    color: Colors.blue.shade300,
                    onTap: () => _navigateToForm(context, ActivityType.VACCINE),
                  ),
                  _ActivityCard(
                    label: 'การเกิด',
                    icon: Icons.child_friendly,
                    color: Colors.pink.shade300,
                    onTap: () => _navigateToForm(context, ActivityType.BIRTH),
                  ),
                  _ActivityCard(
                    label: 'การรักษา',
                    icon: Icons.healing,
                    color: Colors.green.shade300,
                    onTap: () =>
                        _navigateToForm(context, ActivityType.TREATMENT),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48.r, color: color),
            SizedBox(height: 8.h),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
