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
    final date = activity.activityDate.toLocal();
    final monthName = _getMonthNameShort(date.month);

    return Container(
      width: 50.w,
      // --- แก้ไขจุดที่ 1: เปลี่ยนจาก height ตายตัว เป็น constraints ขั้นต่ำ ---
      // height: 68.h, // ของเดิมที่ทำให้เกิด Overflow
      constraints: BoxConstraints(minHeight: 68.h), // ของใหม่: ยืดหยุ่นได้
      // -------------------------------------------------------------
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // จัดกึ่งกลางแนวตั้ง
        children: [
          Text(
            monthName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              height: 1.0, // คุม Line Height ให้กระชับขึ้น
            ),
          ),
          SizedBox(height: 2.h), // เพิ่มระยะห่างเล็กน้อย
          Text(
            '${date.day}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              height: 1.0, // คุม Line Height
            ),
          ),
          Text(
            '${date.year + 543}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
              fontSize: 10.sp,
              height: 1.0,
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
                  color: color.withValues(alpha: 0.3),
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
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border:
            Border.all(color: Colors.grey.withValues(alpha: 0.25), width: 1.w),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Section
            _buildDateSection(theme),
            SizedBox(width: 8.w),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Icon + Title
                  Row(
                    children: [
                      activity.activityType.assetIcon != null
                          ? Image.asset(activity.activityType.assetIcon!,
                              width: 24.r, height: 24.r)
                          : Icon(activity.activityType.icon,
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
                  SizedBox(height: 2.h),
                  Text(
                    '${activity.activityDate.toLocal().hour.toString().padLeft(2, '0')}:${activity.activityDate.toLocal().minute.toString().padLeft(2, '0')} น.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                      fontSize: 11.sp,
                    ),
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
        .where((e) => e.key != 'sickness_ref')
        .toList();

    if (validEntries.isEmpty) return const SizedBox.shrink();

    // Special handling for EDIT_LOG
    if (activity.activityType == ActivityType.EDIT_LOG) {
      return _buildEditLogGrid(theme, data);
    }

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

  Widget _buildEditLogGrid(ThemeData theme, Map<String, dynamic> data) {
    final changes = <Widget>[];

    data.forEach((key, value) {
      if (value == null || value.toString().isEmpty) return;

      // Special handling for image fields: show friendly label instead of bucket path
      if (key == 'face_pic' || key == 'body_pic') {
        changes.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Row(
              children: [
                Image.asset(
                  key == 'face_pic'
                      ? 'assets/images/cow_face.png'
                      : 'assets/images/cow.png',
                  width: 16.r,
                  height: 16.r,
                  color: Colors.grey.shade700,
                ),
                SizedBox(width: 8.w),
                Text(
                  'เพิ่ม${_getTranslatedDataKey(key)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
        return;
      }
      if (value is Map<String, dynamic>) {
        final oldValue = value['old'];
        final newValue = value['new'];

        if (oldValue != null || newValue != null) {
          changes.add(
            Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTranslatedDataKey(key),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      // Old value
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            _formatValue(key, oldValue) ?? '-',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Icon(Icons.arrow_forward,
                            size: 16.r, color: Colors.grey),
                      ),
                      // New value
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.8)),
                          ),
                          child: Text(
                            _formatValue(key, newValue) ?? '-',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      }
    });

    return Column(children: changes);
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
      case 'disease_type':
        return 'ชื่อโรค/สาเหตุ';
      case 'disease_name':
        return 'ชื่อโรค/สาเหตุ';
      case 'other_disease_name':
        return 'ชื่อโรค (ระบุ)';
      case 'treatment_method':
        return 'วิธีการรักษา';
      case 'other_treatment_detail':
        return 'วิธีรักษา (ระบุ)';
      case 'recovery_status':
        return 'สถานะหลังรักษา';
      case 'is_recovered':
        return 'หายดีแล้ว';
      case 'follow_up_date':
        return 'วันนัดตรวจ';

      // Sickness
      case 'illness_symptoms':
        return 'อาการที่พบ';

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

      // Edit Fields (for EDIT_LOG)
      case 'status':
        return 'สถานะ';
      case 'height':
        return 'ส่วนสูง (ซม.)';
      case 'color':
        return 'สีตัว';
      case 'birth_date':
        return 'วันเกิด';
      case 'origin':
        return 'แหล่งที่มา';
      case 'import_date':
        return 'วันนำเข้า';
      case 'dam_id':
        return 'แม่พันธุ์';
      case 'face_pic':
        return 'รูปหน้าวัว';
      case 'body_pic':
        return 'รูปตัววัว';

      // Generic
      case 'details':
        return 'รายละเอียด';
      case 'death_cause':
        return 'สาเหตุการตาย';

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
    if (key == 'status') {
      if (strVal == 'ACTIVE') return 'สุขภาพดี';
      if (strVal == 'SICK') return 'ป่วย';
      if (strVal == 'SOLD') return 'ขายแล้ว';
      if (strVal == 'DEATH') return 'ตายแล้ว';
    }
    if (key == 'death_cause') {
      if (strVal == 'EPIDEMIC') return 'โรคระบาด';
      if (strVal == 'ACCIDENT') return 'อุบัติเหตุ';
      if (strVal == 'DIGESTIVE') return 'ระบบย่อยอาหาร';
      if (strVal == 'ENVIRONMENT') return 'สภาพแวดล้อม';
      if (strVal == 'OTHER') return 'อื่นๆ';
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

    // Disease type
    if (key == 'disease_type') {
      const map = {
        'LUMPY_SKIN': 'ลัมปีสกิน',
        'PARASITE': 'พยาธิ',
        'BLOAT': 'ท้องอืด',
        'PNEUMONIA': 'ปอดบวม',
        'MASTITIS': 'เต้านมอักเสบ',
        'FOOT_ROT': 'โรคกีบเน่า',
        'DIARRHEA': 'ท้องเสีย',
        'OTHER': 'อื่นๆ',
      };
      return map[strVal] ?? strVal;
    }

    // Treatment method
    if (key == 'treatment_method') {
      const map = {
        'ORAL_MED': 'กินยา',
        'TOPICAL': 'ทายา',
        'INJECTION': 'ฉีดยา',
        'VACCINE': 'ฉีดวัคซีน',
        'SURGERY': 'ผ่าตัด',
        'OTHER': 'อื่นๆ',
      };
      return map[strVal] ?? strVal;
    }

    // Recovery status
    if (key == 'recovery_status') {
      const map = {
        'RECOVERED': 'หายดีแล้ว',
        'MONITORING': 'เฝ้าดูอาการ',
        'REFERRED': 'ส่งต่อรักษา',
      };
      return map[strVal] ?? strVal;
    }

    // is_recovered
    if (key == 'is_recovered') {
      if (value == true || strVal == 'true') return 'ใช่';
      return 'ไม่';
    }

    // Follow-up date
    if (key == 'follow_up_date') {
      final dt = DateTime.tryParse(strVal);
      if (dt != null) return '${dt.day}/${dt.month}/${dt.year + 543}';
    }

    return strVal;
  }
}
