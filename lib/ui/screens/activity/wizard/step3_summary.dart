import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/services/cow_management/cow_activity/activity_service.dart';
import 'package:th_cow_passport/services/cow_management/cow_detail/cow_detail_service.dart';
import 'package:th_cow_passport/services/cow_management/models/activity_model.dart';
import 'package:th_cow_passport/ui/screens/activity/activity_extensions.dart';
import 'package:th_cow_passport/ui/screens/activity/wizard/wizard_constants.dart';

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
      ref.invalidate(cowDetailServiceProvider);

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
                      SizedBox(height: 32.h),
                      _buildSummaryRow('วันที่',
                          '${widget.date.day}/${widget.date.month}/${widget.date.year + 543}'),
                      Divider(height: 32.h),
                      _buildSummaryRow('ประเภท', widget.type.label),
                      if (widget.data.isNotEmpty) ...[
                        Divider(height: 32.h),
                        // Display key data
                        ...widget.data.entries.map((e) => Padding(
                              padding: EdgeInsets.only(bottom: 8.h),
                              child: _buildSummaryRow(
                                  _formatKey(e.key), '${e.value}'),
                            )),
                      ],
                      if (widget.notes != null && widget.notes!.isNotEmpty) ...[
                        Divider(height: 32.h),
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
      case 'calf_name':
        return 'ชื่อลูกโค';
      case 'sex':
        return 'เพศ';
      case 'breed':
        return 'สายพันธุ์';
      case 'calf_nid':
        return 'NID ลูกโค';
      case 'calf_birth_weight':
        return 'น้ำหนักแรกเกิด';
      case 'weight':
        return 'น้ำหนัก';
      case 'symptoms':
        return 'อาการ';
      case 'treatment_details':
        return 'รายละเอียดการรักษา';
      case 'details':
        return 'รายละเอียด';
      default:
        return key.replaceAll('_', ' ').capitalize();
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
