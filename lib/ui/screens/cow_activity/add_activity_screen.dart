import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:th_cow_passport/services/cow_management/cow_activity/activity_service.dart';
import 'package:th_cow_passport/services/cow_management/models/activity_model.dart';
import 'package:th_cow_passport/ui/screens/cow_activity/widgets/form_widgets.dart';

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
    _activityDateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _activityDateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เพิ่มกิจกรรม: ${_getActivityTypeName(widget.activityType)}'),
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
        DatePickerField(
          controller: _activityDateController,
          labelText: 'วันที่ทำกิจกรรม',
          onTap: () => _selectDate(context),
        ),
        SizedBox(height: 16.h),
        // Specific form fields
        ...switch (type) {
          ActivityType.VACCINE => _buildVaccineForm(),
          ActivityType.BIRTH => _buildBirthForm(),
          ActivityType.TREATMENT => _buildTreatmentForm(),
          ActivityType.EDIT_LOG => _buildGenericForm('รายละเอียดการแก้ไข'),
          ActivityType.PREGNANCY_CHECK => _buildGenericForm('ผลการตรวจการตั้งท้อง'),
          ActivityType.BREEDING => _buildGenericForm('รายละเอียดการผสมพันธุ์'),
          ActivityType.DEATH => _buildGenericForm('สาเหตุการตาย'),
          ActivityType.WEIGHT_UPDATE => _buildWeightUpdateForm(),
          ActivityType.SOLD => _buildGenericForm('รายละเอียดการขาย'),
        },
        SizedBox(height: 16.h),
        FormTextField(
          controller: _descriptionController,
          labelText: 'หมายเหตุ',
          maxLines: 3,
          isRequired: false,
        ),
      ],
    );
  }

  List<Widget> _buildVaccineForm() {
    return [
      FormTextField(
        controller: _vaccineNameController,
        labelText: 'ชื่อวัคซีน',
        hintText: 'เช่น วัคซีนป้องกันโรคปากและเท้าเปื่อย',
      ),
    ];
  }

  List<Widget> _buildBirthForm() {
    return [
      FormTextField(
        controller: _calfNameController,
        labelText: 'ชื่อลูกวัว',
        hintText: 'ชื่อของลูกวัว',
      ),
      SizedBox(height: 16.h),
      FormTextField(
        controller: _calfGenderController,
        labelText: 'เพศลูกวัว',
        hintText: 'เพศผู้ / เพศเมีย',
      ),
      SizedBox(height: 16.h),
      FormTextField(
        controller: _calfBreedController,
        labelText: 'พันธุ์ลูกวัว',
        hintText: 'พันธุ์ของลูกวัว',
      ),
      SizedBox(height: 16.h),
      FormTextField(
        controller: _calfNidController,
        labelText: 'เลขประจำตัวลูกวัว (NID)',
        hintText: 'กรอกเลข NID 13 หลัก (ถ้ามี)',
        isRequired: false,
      ),
      SizedBox(height: 16.h),
      FormTextField(
        controller: _calfBirthWeightController,
        labelText: 'น้ำหนักแรกเกิด (กก.)',
        hintText: 'เช่น 25.5',
        isRequired: false,
      ),
    ];
  }

  List<Widget> _buildTreatmentForm() {
    return [
      FormTextField(
        controller: _symptomsController,
        labelText: 'อาการ',
        maxLines: 3,
        hintText: 'อธิบายอาการป่วยของวัว',
      ),
      SizedBox(height: 16.h),
      FormTextField(
        controller: _treatmentDetailsController,
        labelText: 'รายละเอียดการรักษา',
        maxLines: 3,
        hintText: 'ระบุยาและวิธีการรักษา',
      ),
    ];
  }

  List<Widget> _buildWeightUpdateForm() {
    return [
      FormTextField(
        controller: _weightController,
        labelText: 'น้ำหนักปัจจุบัน (กก.)',
        hintText: 'เช่น 450.5',
      ),
    ];
  }

  List<Widget> _buildGenericForm(String label) {
    return [
       FormTextField(
        controller: _descriptionController, // Re-using description controller for simplicity
        labelText: label,
        maxLines: 5,
      ),
    ];
  }

  String _getActivityTypeName(ActivityType type) {
    switch (type) {
      case ActivityType.VACCINE:
        return 'ฉีดวัคซีน';
      case ActivityType.BIRTH:
        return 'การเกิด';
      case ActivityType.TREATMENT:
        return 'การรักษา';
      case ActivityType.EDIT_LOG:
        return 'ประวัติการแก้ไข';
      case ActivityType.PREGNANCY_CHECK:
        return 'ตรวจการตั้งท้อง';
      case ActivityType.BREEDING:
        return 'ผสมพันธุ์';
      case ActivityType.DEATH:
        return 'ตายแล้ว';
      case ActivityType.WEIGHT_UPDATE:
        return 'ปรับปรุงน้ำหนัก';
      case ActivityType.SOLD:
        return 'ขาย';
    }
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

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
        data['calf_birth_weight'] = double.tryParse(_calfBirthWeightController.text);
        break;
      case ActivityType.TREATMENT:
         data['symptoms'] = _symptomsController.text;
         data['treatment_details'] = _treatmentDetailsController.text;
        break;
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
