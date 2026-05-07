import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/services/cow_management/cow_activity/activity_service.dart';
import 'package:th_cow_passport/services/cow_management/cow_detail/cow_detail_service.dart';
import 'package:th_cow_passport/services/cow_management/cow_list/cow_list_service.dart';
import 'package:th_cow_passport/services/cow_management/vaccine/vaccine_service.dart';
import 'package:th_cow_passport/services/notification/farm_alert_service.dart';
import 'package:th_cow_passport/services/cow_management/models/activity_model.dart';
import 'package:th_cow_passport/ui/screens/activity/activity_extensions.dart';
import 'package:th_cow_passport/ui/screens/activity/wizard/wizard_constants.dart';
import 'package:logger/logger.dart';

class Step3Summary extends ConsumerStatefulWidget {
  final int cowId;
  final ActivityType type;
  final DateTime date;
  final Map<String, dynamic> data;
  final String? notes;

  final VoidCallback onEdit;
  final VoidCallback onSaveSuccess;

  const Step3Summary({
    super.key,
    required this.cowId,
    required this.type,
    required this.date,
    this.data = const {},
    this.notes,
    required this.onEdit,
    required this.onSaveSuccess,
  });

  @override
  ConsumerState<Step3Summary> createState() => _Step3SummaryState();
}

class _Step3SummaryState extends ConsumerState<Step3Summary> {
  bool _isSaving = false;

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    final newActivity = Activity(
      animalId: widget.cowId,
      activityType: widget.type,
      activityDate: widget.date,
      description: widget.notes,
      data: widget.data,
    );

    try {
      await ref.read(activityServiceProvider).addActivity(newActivity);
      ref.invalidate(activitiesProvider(widget.cowId));
      ref.invalidate(cowVaccineHistoryProvider(widget.cowId));
      ref.invalidate(cowDetailServiceProvider);
      ref.invalidate(farmAlertsProvider);
      // Force refresh the global cow list as well (important for Birth activities)
      ref.read(cowServiceProvider).fetchCows(forceRefresh: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกเรียบร้อยแล้ว!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaveSuccess();
      }
    } catch (e) {
      Logger().e('Error saving activity: $e'); // Log info
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.r),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(32.r),
                  decoration: WizardStyles.cardDecoration,
                  child: Column(
                    children: [
                      Container(
                        width: 100.r,
                        height: 100.r,
                        decoration: BoxDecoration(
                          color:
                              WizardColors.primarySpring.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.type.icon,
                            size: 48.r, color: WizardColors.primarySpring),
                      ),
                      SizedBox(height: 24.h),
                      _buildSummaryRow('วันที่',
                          '${widget.date.day}/${widget.date.month}/${widget.date.year + 543}'),
                      SizedBox(height: 16.h),
                      _buildSummaryRow('ประเภท', widget.type.label),
                      if (widget.data.isNotEmpty) ...[
                        SizedBox(height: 24.h),
                        // Display key data
                        ...widget.data.entries
                            .where((e) => !_isInternalKey(e.key))
                            .map((e) => Padding(
                                  padding: EdgeInsets.only(bottom: 8.h),
                                  child: _buildSummaryRow(_formatKey(e.key),
                                      _formatValue(e.key, e.value)),
                                )),
                      ],
                      if (widget.notes != null && widget.notes!.isNotEmpty) ...[
                        SizedBox(height: 24.h),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('บันทึกเพิ่มเติม',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 14.sp)),
                        ),
                        SizedBox(height: 8.h),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(widget.notes!,
                              style: WizardStyles.labelLarge),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'กรุณาตรวจสอบรายละเอียดด้านบน เมื่อบันทึกแล้ว ข้อมูลจะถูกเพิ่มในประวัติสัตว์',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(24.r),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: WizardStyles.primaryButtonStyle,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('บันทึกข้อมูล'),
                ),
              ),
              SizedBox(height: 16.h),
              TextButton(
                onPressed: widget.onEdit,
                style: WizardStyles.secondaryButtonStyle,
                child: const Text('แก้ไขข้อมูล'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey, fontSize: 16.sp)),
        Text(value, style: WizardStyles.titleMedium),
      ],
    );
  }

  String _formatKey(String key) {
    switch (key) {
      case 'vaccine_name':
        return 'ชื่อวัคซีน';
      case 'animal_name':
        return 'ชื่อลูกโค';
      case 'sex':
        return 'เพศ';
      case 'breed':
        return 'สายพันธุ์';
      case 'nid_number':
        return 'NID ลูกโค';
      case 'birth_weight':
        return 'น้ำหนักแรกเกิด';
      case 'weight':
        return 'น้ำหนัก';
      case 'symptoms':
        return 'อาการ';
      case 'treatment_details':
        return 'รายละเอียดการรักษา';
      case 'details':
        return 'รายละเอียด';
      case 'breeding_method':
        return 'วิธีการ';
      case 'sire_type':
        return 'ประเภทพ่อพันธุ์';
      case 'sire_id':
        return 'ID พ่อพันธุ์';
      case 'other_sire_name':
        return 'ชื่อพ่อพันธุ์';
      case 'other_sire_origin':
        return 'ที่มาพ่อพันธุ์';
      case 'check_method':
        return 'วิธีการตรวจ';
      case 'check_result':
        return 'ผลการตรวจ';
      case 'estimated_age':
        return 'อายุครรภ์';
      case 'death_cause':
        return 'สาเหตุการตาย';
      case 'dose_number':
        return 'เข็มที่';
      case 'vaccine_note':
        return 'หมายเหตุ';
      case 'illness_symptoms':
        return 'อาการที่พบ';
      case 'disease_type':
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
      case 'disease_name':
        return 'ชื่อโรค/สาเหตุ';
      default:
        return key.replaceAll('_', ' ').capitalize();
    }
  }

  bool _isInternalKey(String key) {
    return const {'sickness_ref', 'vaccine_id'}.contains(key);
  }

  String _formatValue(String key, dynamic value) {
    if (value == null) return '-';
    final strVal = value.toString();

    // Dose number formatting
    if (key == 'dose_number') {
      final num = int.tryParse(strVal);
      if (num != null) return 'เข็มที่ $num';
      return strVal;
    }

    if (key == 'breeding_method') {
      if (strVal == 'NATURAL') return 'ตามธรรมชาติ';
      if (strVal == 'AI') return 'ผสมเทียม';
    }
    if (key == 'sire_type') {
      if (strVal == 'FARM') return 'วัวในฟาร์ม';
      if (strVal == 'UNKNOWN') return 'ไม่ทราบ';
      if (strVal == 'OTHER') return 'อื่นๆ';
    }
    if (key == 'sex') {
      if (strVal == 'MALE') return 'เพศผู้';
      if (strVal == 'FEMALE') return 'เพศเมีย';
    }

    // Pregnancy Check Translations
    if (key == 'check_method') {
      if (strVal == 'PALPATION') return 'การคลำ';
      if (strVal == 'ULTRASOUND') return 'อัลตร้าซาวด์';
      if (strVal == 'OBSERVATION') return 'การสังเกต';
      if (strVal == 'BLOOD') return 'เจาะเลือด';
      if (strVal == 'URINE') return 'ตรวจปัสสาวะ';
    }
    if (key == 'check_result') {
      if (strVal == 'PREGNANT') return 'ตั้งครรภ์';
      if (strVal == 'NOT_PREGNANT') return 'ไม่ตั้งครรภ์';
      if (strVal == 'RECHECK') return 'ตรวจใหม่/ไม่แน่ใจ';
    }

    if (key == 'death_cause') {
      if (strVal == 'EPIDEMIC') return 'โรคระบาด';
      if (strVal == 'ACCIDENT') return 'อุบัติเหตุ';
      if (strVal == 'DIGESTIVE') return 'ระบบย่อยอาหาร';
      if (strVal == 'ENVIRONMENT') return 'สภาพแวดล้อม';
      if (strVal == 'UNKNOWN') return 'ไม่ทราบสาเหตุ';
      if (strVal == 'OTHER') return 'อื่นๆ';
    }

    if (key == 'is_recovered') {
      if (value == true) return 'ใช่';
      return 'ไม่';
    }

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

    if (key == 'recovery_status') {
      const map = {
        'RECOVERED': 'หายดีแล้ว',
        'MONITORING': 'เฝ้าดูอาการ',
        'REFERRED': 'ส่งต่อรักษา',
      };
      return map[strVal] ?? strVal;
    }

    if (key == 'follow_up_date') {
      final dt = DateTime.tryParse(strVal);
      if (dt != null) return '${dt.day}/${dt.month}/${dt.year + 543}';
    }

    return strVal;
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
