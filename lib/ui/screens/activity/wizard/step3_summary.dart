import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
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
            content: Text('Saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaveSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
                          color: WizardColors.primarySpring.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.type.icon,
                            size: 48.r, color: WizardColors.primarySpring),
                      ),
                      SizedBox(height: 32.h),
                      _buildSummaryRow(
                          'Date', DateFormat('dd/MM/yyyy').format(widget.date)),
                      Divider(height: 32.h),
                      _buildSummaryRow('Type', widget.type.label),
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
                          child: Text('Notes',
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
                  'Please review the details above. Once saved, this record will be added to the animal history.',
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
                      : const Text('Save Record'),
                ),
              ),
              SizedBox(height: 16.h),
              TextButton(
                onPressed: widget.onEdit,
                style: WizardStyles.secondaryButtonStyle,
                child: const Text('Edit Details'),
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
    // Simple formatter, can be expanded
    return key.replaceAll('_', ' ').capitalize();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
