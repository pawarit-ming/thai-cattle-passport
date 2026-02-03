import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:th_cow_passport/services/cow_management/models/activity_model.dart';
import 'package:th_cow_passport/ui/screens/activity/activity_extensions.dart';
import 'package:th_cow_passport/ui/screens/activity/forms/activity_forms.dart';
import 'package:th_cow_passport/ui/screens/activity/wizard/wizard_constants.dart';

class Step2FormInput extends ConsumerStatefulWidget {
  final ActivityType activityType;
  final Map<String, dynamic> initialData;
  final DateTime initialDate;
  final String? initialNotes;
  final Function(Map<String, dynamic> data, DateTime date, String? notes)
      onNext;
  final VoidCallback onBack;

  const Step2FormInput({
    super.key,
    required this.activityType,
    this.initialData = const {},
    required this.initialDate,
    this.initialNotes,
    required this.onNext,
    required this.onBack,
  });

  @override
  ConsumerState<Step2FormInput> createState() => _Step2FormInputState();
}

class _Step2FormInputState extends ConsumerState<Step2FormInput> {
  final _formKey = GlobalKey<FormState>();

  // Local controllers
  final _notesController = TextEditingController();
  late DateTime _selectedDate;

  // Specific Controllers
  final _vaccineNameController = TextEditingController();
  final _calfNameController = TextEditingController();
  final _calfGenderController = TextEditingController();
  final _calfBreedController = TextEditingController();
  final _calfNidController = TextEditingController();
  final _calfBirthWeightController = TextEditingController();
  final _weightController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _treatmentDetailsController = TextEditingController();
  final _detailsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _notesController.text = widget.initialNotes ?? '';
    _restoreFormData(widget.initialData);
  }

  void _restoreFormData(Map<String, dynamic> data) {
    if (data.containsKey('vaccine_name')) {
      _vaccineNameController.text = data['vaccine_name'];
    }
    if (data.containsKey('calf_name')) {
      _calfNameController.text = data['calf_name'];
    }
    if (data.containsKey('sex')) _calfGenderController.text = data['sex'];
    if (data.containsKey('breed')) _calfBreedController.text = data['breed'];
    if (data.containsKey('calf_nid')) {
      _calfNidController.text = data['calf_nid'];
    }
    if (data.containsKey('calf_birth_weight')) {
      _calfBirthWeightController.text = data['calf_birth_weight'].toString();
    }
    if (data.containsKey('weight')) {
      _weightController.text = data['weight'].toString();
    }
    if (data.containsKey('symptoms')) {
      _symptomsController.text = data['symptoms'];
    }
    if (data.containsKey('treatment_details')) {
      _treatmentDetailsController.text = data['treatment_details'];
    }
    if (data.containsKey('details')) _detailsController.text = data['details'];
  }

  @override
  void dispose() {
    _notesController.dispose();
    _vaccineNameController.dispose();
    _calfNameController.dispose();
    _calfGenderController.dispose();
    _calfBreedController.dispose();
    _calfNidController.dispose();
    _calfBirthWeightController.dispose();
    _weightController.dispose();
    _symptomsController.dispose();
    _treatmentDetailsController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: WizardColors.primarySpring,
              onPrimary: Colors.white,
              onSurface: WizardColors.textDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: WizardColors.primarySpring,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> data = {};

      // Collect Data based on type
      switch (widget.activityType) {
        case ActivityType.VACCINE:
          if (_vaccineNameController.text.isNotEmpty) {
            data['vaccine_name'] = _vaccineNameController.text;
          }
          break;
        case ActivityType.BIRTH:
          if (_calfNameController.text.isNotEmpty) {
            data['calf_name'] = _calfNameController.text;
          }
          if (_calfGenderController.text.isNotEmpty) {
            data['sex'] = _calfGenderController.text;
          }
          if (_calfBreedController.text.isNotEmpty) {
            data['breed'] = _calfBreedController.text;
          }
          if (_calfNidController.text.isNotEmpty) {
            data['calf_nid'] = _calfNidController.text;
          }
          if (_calfBirthWeightController.text.isNotEmpty) {
            data['calf_birth_weight'] =
                double.tryParse(_calfBirthWeightController.text);
          }
          break;
        case ActivityType.TREATMENT:
          if (_symptomsController.text.isNotEmpty) {
            data['symptoms'] = _symptomsController.text;
          }
          if (_treatmentDetailsController.text.isNotEmpty) {
            data['treatment_details'] = _treatmentDetailsController.text;
          }
          break;
        case ActivityType.WEIGHT_UPDATE:
          if (_weightController.text.isNotEmpty) {
            data['weight'] = double.tryParse(_weightController.text);
          }
          break;
        default:
          if (_detailsController.text.isNotEmpty) {
            data['details'] = _detailsController.text;
          }
      }

      widget.onNext(data, _selectedDate, _notesController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.r),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.activityType.label,
                    style: WizardStyles.titleLarge,
                  ),
                  SizedBox(height: 24.h),

                  // Date Section
                  Text(
                    'วันที่',
                    style: WizardStyles.labelLarge.copyWith(color: Colors.grey),
                  ),
                  SizedBox(height: 8.h),
                  InkWell(
                    onTap: () => _selectDate(context),
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: WizardColors.cardBackground,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                            color: WizardColors.stepIndicatorInactive),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'วันที่เลือก',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12.sp),
                              ),
                              Text(
                                DateFormat('d MMM yyyy').format(_selectedDate),
                                style: WizardStyles.titleMedium,
                              ),
                            ],
                          ),
                          Icon(Icons.calendar_today,
                              color: WizardColors.primarySpring),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Dynamic Form Section
                  _buildSpecificForm(widget.activityType),

                  SizedBox(height: 24.h),

                  // Notes Section
                  Text(
                    'บันทึกเพิ่มเติม',
                    style: WizardStyles.labelLarge.copyWith(color: Colors.grey),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    decoration: BoxDecoration(
                      color: WizardColors.cardBackground,
                      borderRadius: BorderRadius.circular(16.r),
                      border:
                          Border.all(color: WizardColors.stepIndicatorInactive),
                    ),
                    child: TextFormField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            'เพิ่มรายละเอียด เช่น อาการ พฤติกรรม หรือปริมาณอาหาร...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16.r),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom Navigation
        Container(
          padding: EdgeInsets.all(24.r),
          color: WizardColors.background,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: widget.onBack,
                style: WizardStyles.secondaryButtonStyle,
                child: const Text('ย้อนกลับ'),
              ),
              ElevatedButton(
                onPressed: _handleNext,
                style: WizardStyles.primaryButtonStyle,
                child: Row(
                  children: [
                    const Text('ถัดไป'),
                    SizedBox(width: 8.w),
                    const Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecificForm(ActivityType type) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: WizardStyles.cardDecoration,
      child: Column(
        children: [
          _getFormByType(type),
        ],
      ),
    );
  }

  Widget _getFormByType(ActivityType type) {
    switch (type) {
      case ActivityType.VACCINE:
        return VaccineForm(nameController: _vaccineNameController);
      case ActivityType.BIRTH:
        return BirthForm(
          nameController: _calfNameController,
          genderController: _calfGenderController,
          breedController: _calfBreedController,
          nidController: _calfNidController,
          birthWeightController: _calfBirthWeightController,
        );
      case ActivityType.TREATMENT:
        return TreatmentForm(
          symptomsController: _symptomsController,
          treatmentDetailsController: _treatmentDetailsController,
        );
      case ActivityType.WEIGHT_UPDATE:
        return Column(
          children: [
            Icon(Icons.monitor_weight,
                size: 48.r, color: WizardColors.secondarySpring),
            SizedBox(height: 16.h),
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: WizardStyles.titleLarge.copyWith(fontSize: 48.sp),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '0',
                suffix: Text('กก.',
                    style: TextStyle(fontSize: 24.sp, color: Colors.grey)),
              ),
            ),
          ],
        );
      case ActivityType.EDIT_LOG:
        return GenericForm(controller: _detailsController, label: 'รายละเอียด');
      case ActivityType.PREGNANCY_CHECK:
        return GenericForm(controller: _detailsController, label: 'ผลการตรวจ');
      case ActivityType.BREEDING:
        return GenericForm(controller: _detailsController, label: 'รายละเอียด');
      case ActivityType.DEATH:
        return GenericForm(
            controller: _detailsController, label: 'สาเหตุการตาย');
      case ActivityType.SOLD:
        return GenericForm(controller: _detailsController, label: 'รายละเอียด');
    }
  }
}
