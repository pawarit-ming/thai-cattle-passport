import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/services/cow_management/cow_detail/cow_detail_service.dart';

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
      child: Card(
        elevation: 4,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(theme, 'Tag ID:', cow.nidNumber),
              _buildDetailRow(theme, 'ชื่อ:', cow.animalName),
              _buildDetailRow(theme, 'สายพันธุ์:', cow.breed),
              _buildDetailRow(
                  theme, 'เพศ:', cow.sex == 'M' ? 'พ่อพันธุ์' : 'แม่พันธุ์'),
              _buildDetailRow(theme, 'วันเกิด:',
                  cow.birthDate.toIso8601String().substring(0, 10)),
              _buildDetailRow(theme, 'น้ำหนัก:', '${cow.weight} กก.'),
              _buildDetailRow(theme, 'ส่วนสูง:', '${cow.height} ซม.'),
              _buildDetailRow(theme, 'สีตัว:', cow.animalColor),
              Divider(height: 32.h),
              _buildDetailRow(
                  theme, 'แม่พันธุ์ (Dam ID):', cow.damId?.toString() ?? '-'),
              _buildDetailRow(
                  theme, 'พ่อพันธุ์ (Sire ID):', cow.sireId?.toString() ?? '-'),
              _buildDetailRow(
                  theme, 'สถานะ:', _getStatusLabel(cow.animalStatus)),
            ],
          ),
        ),
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
              style:
                  theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case '0':
        return 'ขายแล้ว';
      case '1':
        return 'ตาย';
      case '2':
        return 'คัดทิ้ง';
      case '4':
        return 'ปกติ';
      default:
        return 'ไม่ระบุ';
    }
  }
}