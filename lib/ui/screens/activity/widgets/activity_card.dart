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
    final color = activity.activityType.color;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Timeline Line (Left)
          _buildTimelineLine(color, theme),
          SizedBox(width: 12.w),

          // 2. Content Card (Right)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24.h),
              child: _buildContentCard(context, theme, color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection(ThemeData theme) {
    final date = activity.activityDate;
    final monthName = _getMonthNameShort(date.month);

    return Container(
      width: 50.w,
      height: 68.h,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        children: [
          Text(
            monthName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${date.day}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              height: 1.0,
            ),
          ),
          Text(
            '${date.year + 543}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineLine(Color color, ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 12.r,
          height: 12.r,
          margin: EdgeInsets.only(top: 24.h),
          decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.w),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]),
        ),
        if (!isLast)
          Expanded(
            child: Container(
              width: 2.w,
              color: Colors.grey.shade200,
            ),
          ),
      ],
    );
  }

  Widget _buildContentCard(BuildContext context, ThemeData theme, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Section
            _buildDateSection(theme),
            SizedBox(width: 8.w),

            // // Vertical Divider
            // Container(
            //   width: 1.5.w,
            //   height: 64.h, // Approximate height to match date box visual
            //   color: Colors.brown.shade300,
            // ),
            SizedBox(width: 8.w),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Icon + Title
                  Row(
                    children: [
                      Icon(activity.activityType.icon,
                          color: color, size: 20.r),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          activity.activityType.label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Description
                  if (activity.description != null &&
                      activity.description!.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Text(
                      activity.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],

                  // Data Grid
                  if (activity.data.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    _buildDataGrid(theme, activity.data),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataGrid(ThemeData theme, Map<String, dynamic> data) {
    final validEntries = data.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .toList();

    if (validEntries.isEmpty) return const SizedBox.shrink();

    return Column(
      children: validEntries.map((entry) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Key
              Expanded(
                flex: 4,
                child: Text(
                  _getTranslatedDataKey(entry.key),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Value
              Expanded(
                flex: 6,
                child: Text(
                  _formatValue(entry.key, entry.value),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- Helpers ---

  String _getMonthNameShort(int month) {
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

  String _getTranslatedDataKey(String key) {
    switch (key) {
      // Vaccine
      case 'vaccine_name':
        return 'ชื่อวัคซีน';

      // Birth (Calf info)
      case 'animal_name':
        return 'ชื่อลูกโค';
      case 'sex':
        return 'เพศ';
      case 'breed':
        return 'สายพันธุ์';
      case 'nid_number':
        return 'เลข NID';
      case 'birth_weight':
        return 'น้ำหนักแรกเกิด (กก.)';

      // Weight
      case 'weight':
        return 'น้ำหนัก (กก.)';

      // Treatment
      case 'symptoms':
        return 'อาการ';
      case 'treatment_details':
        return 'การรักษา';

      // Breeding
      case 'breeding_method':
        return 'วิธีผสม';
      case 'sire_type':
        return 'แหล่งพ่อพันธุ์';
      case 'sire_id':
        return 'พ่อพันธุ์ (ฟาร์ม)';
      case 'other_sire_name':
        return 'ชื่อพ่อพันธุ์';
      case 'other_sire_origin':
        return 'ที่มา';

      // Pregnancy Check
      case 'check_method':
        return 'วิธีการตรวจ';
      case 'check_result':
        return 'ผลการตรวจ';
      case 'estimated_age':
        return 'อายุครรภ์';

      // Generic
      case 'details':
        return 'รายละเอียด';

      default:
        return key;
    }
  }

  String _formatValue(String key, dynamic value) {
    if (value == null) return '-';
    final strVal = value.toString();

    // Enum Translations
    if (key == 'breeding_method') {
      if (strVal == 'NATURAL') return 'ธรรมชาติ';
      if (strVal == 'AI') return 'ผสมเทียม';
    }
    if (key == 'sire_type') {
      if (strVal == 'FARM') return 'ในฟาร์ม';
      if (strVal == 'UNKNOWN') return 'ไม่ทราบ';
      if (strVal == 'OTHER') return 'ภายนอก';
    }
    if (key == 'sex') {
      if (strVal == 'MALE') return 'เพศผู้';
      if (strVal == 'FEMALE') return 'เพศเมีย';
    }

    // Pregnancy Check Translations
    if (key == 'check_method') {
      if (strVal == 'PALPATION') return 'การคลำ';
      if (strVal == 'ULTRASOUND') return 'อัลตร้าซาวด์';
      if (strVal == 'OBSERVATION') return 'สังเกต';
      if (strVal == 'BLOOD') return 'ตรวจเลือด';
      if (strVal == 'URINE') return 'ตรวจปัสสาวะ';
    }
    if (key == 'check_result') {
      if (strVal == 'PREGNANT') return 'ตั้งครรภ์';
      if (strVal == 'NOT_PREGNANT') return 'ไม่ตั้งครรภ์';
      if (strVal == 'RECHECK') return 'ตรวจใหม่';
    }

    if (key == 'estimated_age') {
      if (strVal.contains('สัปดาห์') || strVal.contains('วัน')) {
        return strVal;
      }
      final parts = strVal.split(' ');
      if (parts.length == 2) {
        final val = parts[0];
        final unit = parts[1];
        final unitTh =
            unit == 'MONTHS' ? 'เดือน' : (unit == 'DAYS' ? 'วัน' : unit);
        return '$val $unitTh';
      }
      return '$strVal เดือน'; // Fallback for old data or default
    }

    // Format specific values if needed

    return strVal;
  }
}
