import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:th_cow_passport/services/cow_management/cow_activity/activity_service.dart';
import 'package:th_cow_passport/services/cow_management/cow_detail/cow_detail_service.dart';
import 'package:th_cow_passport/services/cow_management/models/activity_model.dart';
import 'package:th_cow_passport/ui/widgets/styled_text_field.dart';

class AddActivityScreen extends ConsumerStatefulWidget {
  final int cowId;
  final ActivityType activityType;

  const AddActivityScreen({
    super.key,
    required this.cowId,
    required this.activityType,
  });

  @override
  ConsumerState<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends ConsumerState<AddActivityScreen> {
  final logger = Logger();
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  bool _isSaving = false;

  // Common Controllers
  final _activityDateController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Vaccine Controllers
  final _vaccineNameController = TextEditingController();

  // Birth Controllers
  final _calfNameController = TextEditingController();
  final _calfGenderController = TextEditingController();
  final _calfBreedController = TextEditingController();
  final _calfNidController = TextEditingController();
  final _calfBirthWeightController = TextEditingController();

  // Weight Update Controllers
  final _weightController = TextEditingController();

  // Treatment Controllers
  final _symptomsController = TextEditingController();
  final _treatmentDetailsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _activityDateController.text =
        DateFormat('yyyy-MM-dd HH:mm').format(_selectedDate);
  }

  @override
  void dispose() {
    // Dispose all controllers
    _activityDateController.dispose();
    _descriptionController.dispose();
    _vaccineNameController.dispose();
    _calfNameController.dispose();
    _calfGenderController.dispose();
    _calfBreedController.dispose();
    _calfNidController.dispose();
    _calfBirthWeightController.dispose();
    _weightController.dispose();
    _symptomsController.dispose();
    _treatmentDetailsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _activityDateController.text =
              DateFormat('yyyy-MM-dd HH:mm').format(_selectedDate);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('เพิ่มกิจกรรม: ${_getActivityTypeName(widget.activityType)}'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildForm(widget.activityType),
              SizedBox(height: 32.h),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveActivity,
                icon: _isSaving
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึกกิจกรรม'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ActivityType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StyledTextField(
          controller: _activityDateController,
          label: 'วันที่และเวลาทำกิจกรรม',
          readOnly: true,
          icon: Icons.calendar_today,
          onTap: () => _selectDate(context),
        ),
        SizedBox(height: 16.h),
        // Specific form fields
        ...switch (type) {
          ActivityType.VACCINE => _buildVaccineForm(),
          ActivityType.BIRTH => _buildBirthForm(),
          ActivityType.SICKNESS => _buildGenericForm('อาการที่พบ'),
          ActivityType.TREATMENT => _buildTreatmentForm(),
          ActivityType.EDIT_LOG => _buildGenericForm('รายละเอียดการแก้ไข'),
          ActivityType.PREGNANCY_CHECK => _buildGenericForm('ผลการตรวจครรภ์'),
          ActivityType.BREEDING => _buildGenericForm('รายละเอียดการผสมพันธุ์'),
          ActivityType.DEATH => _buildGenericForm('สาเหตุการตาย'),
          ActivityType.WEIGHT_UPDATE => _buildWeightUpdateForm(),
          ActivityType.SOLD => _buildGenericForm('รายละเอียดการขาย'),
        },
        SizedBox(height: 16.h),
        StyledTextField(
          controller: _descriptionController,
          label: 'หมายเหตุ',
          maxLines: 3,
          icon: Icons.note,
          isRequired: false,
        ),
      ],
    );
  }

  List<Widget> _buildVaccineForm() {
    return [
      StyledTextField(
        controller: _vaccineNameController,
        label: 'ชื่อวัคซีน',
        hintText: 'เช่น วัคซีนป้องกันโรคปากและเท้าเปื่อย',
        isRequired: true,
        icon: Icons.vaccines,
      ),
    ];
  }

  List<Widget> _buildBirthForm() {
    return [
      StyledTextField(
        controller: _calfNameController,
        label: 'ชื่อลูกวัว',
        hintText: 'ชื่อของลูกวัว',
        isRequired: true,
        icon: Icons.pets, // Required param
        assetIcon: 'assets/images/calf.png',
      ),
      SizedBox(height: 16.h),
      StyledTextField(
        controller: _calfGenderController,
        label: 'เพศลูกวัว',
        hintText: 'เพศผู้ / เพศเมีย',
        isRequired: true,
        icon: Icons.wc, // Required param
        assetIcon: 'assets/images/gender.png',
      ),
      SizedBox(height: 16.h),
      StyledTextField(
        controller: _calfBreedController,
        label: 'พันธุ์ลูกวัว',
        hintText: 'พันธุ์ของลูกวัว',
        isRequired: true,
        icon: Icons.category,
      ),
      SizedBox(height: 16.h),
      StyledTextField(
        controller: _calfNidController,
        label: 'เลขประจำตัวลูกวัว (NID)',
        hintText: 'กรอกเลข NID',
        icon: Icons.tag,
      ),
      SizedBox(height: 16.h),
      StyledTextField(
        controller: _calfBirthWeightController,
        label: 'น้ำหนักแรกเกิด (กก.)',
        hintText: 'เช่น 25.5',
        keyboardType: TextInputType.number,
        suffixText: 'กก.',
        icon: Icons.monitor_weight,
      ),
    ];
  }

  List<Widget> _buildTreatmentForm() {
    return [
      StyledTextField(
        controller: _symptomsController,
        label: 'อาการ',
        maxLines: 3,
        hintText: 'อธิบายอาการป่วยของวัว',
        isRequired: true,
        icon: Icons.sick,
      ),
      SizedBox(height: 16.h),
      StyledTextField(
        controller: _treatmentDetailsController,
        label: 'รายละเอียดการรักษา',
        maxLines: 3,
        hintText: 'ระบุยาและวิธีการรักษา',
        isRequired: true,
        icon: Icons.healing,
      ),
    ];
  }

  List<Widget> _buildWeightUpdateForm() {
    return [
      StyledTextField(
        controller: _weightController,
        label: 'น้ำหนักปัจจุบัน (กก.)',
        hintText: 'เช่น 450.5',
        isRequired: true,
        keyboardType: TextInputType.number,
        suffixText: 'กก.',
        icon: Icons.monitor_weight,
      ),
    ];
  }

  List<Widget> _buildGenericForm(String label) {
    return [
      StyledTextField(
        controller:
            _descriptionController, // Re-using description controller for simplicity
        label: label,
        maxLines: 5,
        isRequired: true,
        icon: Icons.description,
      ),
    ];
  }

  String _getActivityTypeName(ActivityType type) {
    switch (type) {
      case ActivityType.VACCINE:
        return 'ฉีดวัคซีน';
      case ActivityType.BIRTH:
        return 'คลอดลูก';
      case ActivityType.SICKNESS:
        return 'บันทึกการป่วย';
      case ActivityType.TREATMENT:
        return 'การรักษา';
      case ActivityType.EDIT_LOG:
        return 'ประวัติการแก้ไข';
      case ActivityType.PREGNANCY_CHECK:
        return 'บันทึกผลการตรวจครรภ์';
      case ActivityType.BREEDING:
        return 'ผสมพันธุ์';
      case ActivityType.DEATH:
        return 'ตายแล้ว';
      case ActivityType.WEIGHT_UPDATE:
        return 'บันทึกน้ำหนัก';
      case ActivityType.SOLD:
        return 'ขาย';
    }
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    logger.i('Saving activity: ${widget.activityType}, Date: $_selectedDate');

    setState(() {
      _isSaving = true;
    });

    // 1. Create Activity object from form data
    final Map<String, dynamic> data = {};
    switch (widget.activityType) {
      case ActivityType.VACCINE:
        data['vaccine_name'] = _vaccineNameController.text;
        break;
      case ActivityType.BIRTH:
        data['calf_name'] = _calfNameController.text;
        data['sex'] = _calfGenderController.text;
        data['breed'] = _calfBreedController.text;
        data['calf_nid'] = _calfNidController.text;
        data['calf_birth_weight'] =
            double.tryParse(_calfBirthWeightController.text);
        break;
      case ActivityType.TREATMENT:
        data['symptoms'] = _symptomsController.text;
        data['treatment_details'] = _treatmentDetailsController.text;
        break;
      case ActivityType.SICKNESS:
      case ActivityType.EDIT_LOG:
      case ActivityType.PREGNANCY_CHECK:
      case ActivityType.BREEDING:
      case ActivityType.DEATH:
      case ActivityType.WEIGHT_UPDATE:
        data['weight'] = double.tryParse(_weightController.text);
        break;
      case ActivityType.SOLD:
    }

    final newActivity = Activity(
      animalId: widget.cowId,
      activityType: widget.activityType,
      activityDate: _selectedDate,
      description: _descriptionController.text,
      data: data,
    );

    try {
      await ref.read(activityServiceProvider).addActivity(newActivity);
      ref.invalidate(activitiesProvider(widget.cowId));
      ref.invalidate(cowDetailServiceProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกกิจกรรมสำเร็จ!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $error'),
            backgroundColor: Colors.red,
          ),
        );
        logger.e('Error saving activity: $error', error: error);
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
