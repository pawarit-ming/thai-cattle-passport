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
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              'เลือกประเภทกิจกรรม',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      content: SizedBox(
        height: MediaQuery.of(context).size.height * 0.55,
        width: double.maxFinite,
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12.r,
          mainAxisSpacing: 8.r,
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
              onTap: () => _navigateToForm(context, ActivityType.TREATMENT),
            ),
            _ActivityCard(
              label: 'น้ำหนักใหม่',
              icon: Icons.monitor_weight,
              color: Colors.teal.shade300,
              onTap: () => _navigateToForm(context, ActivityType.WEIGHT_UPDATE),
            ),
            _ActivityCard(
              label: 'ผสมพันธุ์',
              icon: Icons.favorite,
              color: Colors.red.shade300,
              onTap: () => _navigateToForm(context, ActivityType.BREEDING),
            ),
            _ActivityCard(
              label: 'ตรวจตั้งครรภ์',
              icon: Icons.pregnant_woman,
              color: Colors.purple.shade300,
              onTap: () => _navigateToForm(context, ActivityType.PREGNANCY_CHECK),
            ),
            _ActivityCard(
              label: 'ตาย',
              icon: Icons.close,
              color: Colors.grey.shade400,
              onTap: () => _navigateToForm(context, ActivityType.DEATH),
            ),
            _ActivityCard(
              label: 'ขาย',
              icon: Icons.sell,
              color: Colors.orange.shade300,
              onTap: () => _navigateToForm(context, ActivityType.SOLD),
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
            Icon(icon, size: 32.r, color: color),
            SizedBox(height: 2.h),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
