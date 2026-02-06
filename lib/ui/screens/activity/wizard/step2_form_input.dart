import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:th_cow_passport/services/cow_management/models/activity_model.dart';
import 'package:th_cow_passport/services/cow_management/cow_list/cow_list_service.dart';
import 'package:th_cow_passport/ui/screens/activity/activity_extensions.dart';
import 'package:th_cow_passport/ui/screens/activity/forms/activity_forms.dart';
import 'package:th_cow_passport/ui/screens/activity/wizard/wizard_constants.dart';

class Step2FormInput extends ConsumerStatefulWidget {
  final int cowId; // Added cowId
  final ActivityType activityType;
  final Map<String, dynamic> initialData;
  final DateTime initialDate;
  final String? initialNotes;
  final Function(Map<String, dynamic> data, DateTime date, String? notes)
      onNext;
  final VoidCallback onBack;

  const Step2FormInput({
    super.key,
    required this.cowId, // Required field
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
  final _calfNidController = TextEditingController();
  final _calfBirthWeightController = TextEditingController();
  final _weightController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _treatmentDetailsController = TextEditingController();
  final _detailsController = TextEditingController();

  // Breeding Controllers
  String? _breedingMethod;
  String? _sireType;
  int? _selectedSireId;
  final _otherSireNameController = TextEditingController();
  final _otherSireOriginController = TextEditingController();

  // Pregnancy Check Controllers
  String? _pregCheckMethod;
  String? _pregCheckResult;
  final _pregAgeWeeksController = TextEditingController();
  final _pregAgeDaysController = TextEditingController();

  // Death Controllers
  String? _deathCause;

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
    if (data.containsKey('animal_name')) {
      _calfNameController.text = data['animal_name'];
    }
    if (data.containsKey('sex')) _calfGenderController.text = data['sex'];
    if (data.containsKey('nid_number')) {
      _calfNidController.text = data['nid_number'];
    }
    if (data.containsKey('birth_weight')) {
      _calfBirthWeightController.text = data['birth_weight'].toString();
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

    // Restore Breeding Data
    if (data.containsKey('breeding_method')) {
      _breedingMethod = data['breeding_method'];
    }
    if (data.containsKey('sire_type')) _sireType = data['sire_type'];
    if (data.containsKey('sire_id')) _selectedSireId = data['sire_id'];
    if (data.containsKey('other_sire_name')) {
      _otherSireNameController.text = data['other_sire_name'];
    }
    if (data.containsKey('other_sire_origin')) {
      _otherSireOriginController.text = data['other_sire_origin'];
    }

    // Restore Pregnancy Check Data
    if (data.containsKey('check_method')) {
      _pregCheckMethod = data['check_method'];
    }
    if (data.containsKey('check_result')) {
      _pregCheckResult = data['check_result'];
    }
    if (data.containsKey('check_result')) {
      _pregCheckResult = data['check_result'];
    }

    // Restore Death Data
    if (data.containsKey('death_cause')) _deathCause = data['death_cause'];

    // Note: estimated_age format changed. Not restoring legacy partial data for simplicity in this iteration.
    // If strict migration needed, would parse "X สัปดาห์ Y วัน" here.
    if (data.containsKey('estimated_age')) {
      final val = data['estimated_age'].toString();
      // Simple check if it matches new format "X สัปดาห์ Y วัน"
      // Not critical for now as this is new feature dev
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _vaccineNameController.dispose();
    _calfNameController.dispose();
    _calfGenderController.dispose();
    _calfNidController.dispose();
    _calfBirthWeightController.dispose();
    _weightController.dispose();
    _symptomsController.dispose();
    _treatmentDetailsController.dispose();
    _detailsController.dispose();
    _otherSireNameController.dispose();
    _otherSireOriginController.dispose();
    _pregAgeWeeksController.dispose();
    _pregAgeDaysController.dispose();
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
          if (_calfNidController.text.isNotEmpty) {
            data['nid_number'] = _calfNidController.text;
          }
          if (_calfNameController.text.isNotEmpty) {
            data['animal_name'] = _calfNameController.text;
          }
          if (_calfGenderController.text.isNotEmpty) {
            data['sex'] = _calfGenderController.text;
          }

          // Auto-assign Breed logic (Father -> Mother)
          String? assignedBreed;
          final allCows = ref.read(cowServiceProvider).cows;

          // 1. Try Father/Sire (if selected and is Farm)
          if (_sireType == 'FARM' && _selectedSireId != null) {
            try {
              final sire =
                  allCows.firstWhere((c) => c.animalId == _selectedSireId);
              assignedBreed = sire.breed;
            } catch (_) {}
          }

          // 2. Fallback to Mother (Current Cow) if Father breed not found
          if (assignedBreed == null) {
            try {
              final mother =
                  allCows.firstWhere((c) => c.animalId == widget.cowId);
              assignedBreed = mother.breed;
            } catch (_) {}
          }

          data['breed'] = assignedBreed ?? 'ไม่ระบุ';

          if (_calfBirthWeightController.text.isNotEmpty) {
            data['birth_weight'] =
                double.tryParse(_calfBirthWeightController.text);
          }
          // Save Sire Data
          if (_sireType != null) {
            data['sire_type'] = _sireType;
            if (_sireType == 'FARM' && _selectedSireId != null) {
              data['sire_id'] = _selectedSireId;
            } else if (_sireType == 'OTHER') {
              if (_otherSireNameController.text.isNotEmpty) {
                data['other_sire_name'] = _otherSireNameController.text;
              }
              if (_otherSireOriginController.text.isNotEmpty) {
                data['other_sire_origin'] = _otherSireOriginController.text;
              }
            }
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
        case ActivityType.BREEDING:
          if (_breedingMethod != null) {
            data['breeding_method'] = _breedingMethod;
          }
          if (_sireType != null) {
            data['sire_type'] = _sireType;
            if (_sireType == 'FARM' && _selectedSireId != null) {
              data['sire_id'] = _selectedSireId;
            } else if (_sireType == 'OTHER') {
              if (_otherSireNameController.text.isNotEmpty) {
                data['other_sire_name'] = _otherSireNameController.text;
              }
              if (_otherSireOriginController.text.isNotEmpty) {
                data['other_sire_origin'] = _otherSireOriginController.text;
              }
            }
          }
          if (_detailsController.text.isNotEmpty) {
            data['details'] = _detailsController.text;
          }
          break;
        case ActivityType.PREGNANCY_CHECK:
          if (_pregCheckMethod != null) {
            data['check_method'] = _pregCheckMethod;
          }
          if (_pregCheckResult != null) {
            data['check_result'] = _pregCheckResult;
          }
          if (_pregCheckResult == 'PREGNANT') {
            final weeks = _pregAgeWeeksController.text.isEmpty
                ? '0'
                : _pregAgeWeeksController.text;
            final days = _pregAgeDaysController.text.isEmpty
                ? '0'
                : _pregAgeDaysController.text;
            data['estimated_age'] = ((int.parse(weeks) * 7) + int.parse(days));
          }
          break;
        case ActivityType.DEATH:
          if (_deathCause != null) {
            data['death_cause'] = _deathCause;
            if (_deathCause == 'OTHER' && _detailsController.text.isNotEmpty) {
              data['details'] = _detailsController.text;
            }
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
        final allCows = ref.watch(cowServiceProvider).cows;
        // Birth always needs a Father (Sire) -> Filter for MALES
        final farmSires = allCows.where((c) => c.sex == 'MALE').toList();

        return BirthForm(
          nameController: _calfNameController,
          genderController: _calfGenderController,
          nidController: _calfNidController,
          birthWeightController: _calfBirthWeightController,
          // Sire Selection
          sireType: _sireType,
          onSireTypeChanged: (val) => setState(() => _sireType = val),
          farmSires: farmSires,
          selectedSireId: _selectedSireId,
          onSireIdChanged: (val) => setState(() => _selectedSireId = val),
          otherSireNameController: _otherSireNameController,
          otherSireOriginController: _otherSireOriginController,
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
        return PregnancyCheckForm(
          checkMethod: _pregCheckMethod,
          onMethodChanged: (val) => setState(() => _pregCheckMethod = val),
          checkResult: _pregCheckResult,
          onResultChanged: (val) => setState(() => _pregCheckResult = val),
          weeksController: _pregAgeWeeksController,
          daysController: _pregAgeDaysController,
        );
      case ActivityType.BREEDING:
        final allCows = ref.watch(cowServiceProvider).cows;
        // Find current cow to determine gender logic
        final currentCow = allCows.firstWhere((c) => c.animalId == widget.cowId,
            orElse: () => allCows.first); // Fallback safely if not found
        final isMale = currentCow.sex == 'MALE';
        final targetSex = isMale ? 'FEMALE' : 'MALE';
        final partnerLabel = isMale ? 'แม่พันธุ์' : 'พ่อพันธุ์';

        final farmPartners = allCows.where((c) => c.sex == targetSex).toList();

        return BreedingForm(
          breedingMethod: _breedingMethod,
          onMethodChanged: (val) => setState(() => _breedingMethod = val),
          partnerLabel: partnerLabel,
          sireType: _sireType,
          onSireTypeChanged: (val) => setState(() => _sireType = val),
          farmSires: farmPartners,
          selectedSireId: _selectedSireId,
          onSireIdChanged: (val) => setState(() => _selectedSireId = val),
          otherSireNameController: _otherSireNameController,
          otherSireOriginController: _otherSireOriginController,
        );
      case ActivityType.DEATH:
        return DeathForm(
          cause: _deathCause,
          onCauseChanged: (val) => setState(() => _deathCause = val),
          otherDetailsController: _detailsController,
        );
      case ActivityType.SOLD:
        return GenericForm(controller: _detailsController, label: 'รายละเอียด');
    }
  }
}
