import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/services/cow_management/cow_detail/cow_detail_service.dart';
import 'package:th_cow_passport/ui/screens/cow_detail/tabs/general/widgets/health_preview_section.dart';
import 'package:th_cow_passport/ui/screens/cow_detail/tabs/general/widgets/offspring_preview_section.dart';

class GeneralTab extends ConsumerWidget {
  // เปลี่ยนเป็น ConsumerWidget
  const GeneralTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // ดึงข้อมูลวัวปัจจุบันจาก Service
    final cow = ref.watch(cowDetailServiceProvider).currentCow;

    if (cow == null) {
      return const Center(child: Text("ไม่พบข้อมูลทั่วไป"));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          // 1. ข้อมูลทั่วไป (General Info Card)
          Card(
            elevation: 2, // ลด shadow ลงนิดหน่อยให้ดู modern ขึ้น
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r)),
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ข้อมูลทั่วไป',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Divider(height: 24.h),
                  _buildDetailRow(theme, 'Tag ID:', cow.nidNumber),
                  _buildDetailRow(theme, 'ชื่อ:', cow.animalName),
                  _buildDetailRow(theme, 'สายพันธุ์:', cow.breed ?? '-'),
                  _buildDetailRow(theme, 'เพศ:',
                      cow.sex == 'MALE' ? 'พ่อพันธุ์' : 'แม่พันธุ์'),
                  _buildDetailRow(theme, 'วันเกิด:',
                      cow.birthDate?.toIso8601String().substring(0, 10) ?? '-'),
                  _buildDetailRow(
                      theme, 'น้ำหนัก:', '${cow.weight ?? '-'} กก.'),
                  _buildDetailRow(
                      theme, 'ส่วนสูง:', '${cow.height ?? '-'} ซม.'),
                  _buildDetailRow(theme, 'สีตัว:', cow.color ?? '-'),
                  Divider(height: 24.h),
                  _buildDetailRow(
                      theme, 'แม่พันธุ์ (Dam):', cow.damId?.toString() ?? '-'),
                  _buildDetailRow(theme, 'พ่อพันธุ์ (Sire):',
                      cow.sireId?.toString() ?? '-'),
                  _buildDetailRow(theme, 'สถานะ:', _getStatusLabel(cow.status)),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // 2. สุขภาพ (Health Card)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r)),
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: HealthPreviewSection(cowId: cow.animalId!),
            ),
          ),
          SizedBox(height: 16.h),

          // 3. ลูกโค (Offspring Card)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r)),
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: OffspringPreviewSection(cowId: cow.animalId!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold, color: Colors.grey[700])),
          Text(value,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'ใช้งาน';
      case 'SOLD':
        return 'ขายแล้ว';
      case 'DECEASED':
        return 'ตายแล้ว';
      case 'SICK':
        return 'ป่วย';
      default:
        return 'ไม่ระบุ';
    }
  }
}
