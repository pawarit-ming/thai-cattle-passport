import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:th_cow_passport/services/cow_management/models/activity_model.dart';
import 'package:th_cow_passport/services/cow_management/cow_list/cow_list_service.dart';
import 'package:th_cow_passport/services/cow_management/vaccine/vaccine_service.dart';
import 'package:th_cow_passport/ui/screens/activity/activity_extensions.dart';
import 'package:th_cow_passport/ui/screens/activity/forms/activity_forms.dart';
import 'package:th_cow_passport/ui/screens/activity/wizard/wizard_constants.dart';
import 'package:th_cow_passport/ui/widgets/common/app_text_field.dart';

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

  // Vaccine State
  String? _selectedVaccineId;
  int? _selectedDoseNumber;
  final _vaccineNoteController = TextEditingController();

  // Specific Controllers
  final _calfNameController = TextEditingController();
  final _calfGenderController = TextEditingController();
  final _calfNidController = TextEditingController();
  final _calfBirthWeightController = TextEditingController();
  final _weightController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _treatmentDetailsController = TextEditingController();
  final _detailsController = TextEditingController();

  // Illness Controllers
  final _illnessSymptomsController = TextEditingController();

  // Treatment Controllers
  String? _treatmentSelectionMode; // 'FROM_RECORD' or 'NEW'
  String? _diseaseType;
  final _otherDiseaseController = TextEditingController();
  String? _treatmentMethod;
  final _otherTreatmentController = TextEditingController();
  String? _recoveryStatus;
  DateTime? _followUpDate;

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
    if (data.containsKey('vaccine_id')) {
      _selectedVaccineId = data['vaccine_id'];
    }
    if (data.containsKey('dose_number')) {
      _selectedDoseNumber = data['dose_number'];
    }
    if (data.containsKey('vaccine_note')) {
      _vaccineNoteController.text = data['vaccine_note'];
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

    // Restore Illness Data
    if (data.containsKey('illness_symptoms')) {
      _illnessSymptomsController.text = data['illness_symptoms'];
    }

    // Restore Treatment Data
    if (data.containsKey('treatment_selection_mode')) {
      _treatmentSelectionMode = data['treatment_selection_mode'];
    } else if (data.containsKey('sickness_ref')) {
      _treatmentSelectionMode = 'FROM_RECORD';
    }
    if (data.containsKey('disease_type')) _diseaseType = data['disease_type'];
    if (data.containsKey('other_disease_name')) {
      _otherDiseaseController.text = data['other_disease_name'];
    }
    if (data.containsKey('treatment_method')) {
      _treatmentMethod = data['treatment_method'];
    }
    if (data.containsKey('other_treatment_detail')) {
      _otherTreatmentController.text = data['other_treatment_detail'];
    }
    if (data.containsKey('recovery_status')) {
      _recoveryStatus = data['recovery_status'];
    }
    if (data.containsKey('follow_up_date')) {
      _followUpDate = DateTime.tryParse(data['follow_up_date']);
    }

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
    _vaccineNoteController.dispose();
    _calfNameController.dispose();
    _calfGenderController.dispose();
    _calfNidController.dispose();
    _calfBirthWeightController.dispose();
    _weightController.dispose();
    _symptomsController.dispose();
    _treatmentDetailsController.dispose();
    _detailsController.dispose();
    _illnessSymptomsController.dispose();
    _otherDiseaseController.dispose();
    _otherTreatmentController.dispose();
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
    if (picked != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
        helpText: 'เลือกเวลา',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: WizardColors.primarySpring,
                onPrimary: Colors.white,
                onSurface: WizardColors.textDark,
              ),
            ),
            child: child!,
          );
        },
      );
      setState(() {
        final t = time ?? TimeOfDay.fromDateTime(_selectedDate);
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          t.hour,
          t.minute,
        );
      });
    }
  }

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> data = {};

      // Collect Data based on type
      switch (widget.activityType) {
        case ActivityType.VACCINE:
          if (_selectedVaccineId != null) {
            data['vaccine_id'] = _selectedVaccineId;
            // Read vaccine name synchronously from already-loaded provider
            final vaccines = ref.read(vaccinesProvider).value ?? [];
            try {
              final v = vaccines.firstWhere((v) => v.id == _selectedVaccineId);
              data['vaccine_name'] = v.nameTh;
            } catch (_) {}
          }
          if (_selectedDoseNumber != null) {
            data['dose_number'] = _selectedDoseNumber;
          }
          if (_vaccineNoteController.text.isNotEmpty) {
            data['vaccine_note'] = _vaccineNoteController.text;
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
        case ActivityType.SICKNESS:
          if (_illnessSymptomsController.text.isNotEmpty) {
            data['illness_symptoms'] = _illnessSymptomsController.text;
          }
          break;
        case ActivityType.TREATMENT:
          if (_symptomsController.text.isNotEmpty) {
            data['symptoms'] = _symptomsController.text;
          }
          if (_diseaseType != null) {
            data['disease_type'] = _diseaseType;
            if (_diseaseType == 'OTHER' &&
                _otherDiseaseController.text.isNotEmpty) {
              data['other_disease_name'] = _otherDiseaseController.text;
            }
          }
          if (_treatmentMethod != null) {
            data['treatment_method'] = _treatmentMethod;
            if (_treatmentMethod == 'OTHER' &&
                _otherTreatmentController.text.isNotEmpty) {
              data['other_treatment_detail'] = _otherTreatmentController.text;
            }
          }
          if (_recoveryStatus != null) {
            data['recovery_status'] = _recoveryStatus;
          }
          data['is_recovered'] = _recoveryStatus == 'RECOVERED';
          if (_followUpDate != null) {
            data['follow_up_date'] = _followUpDate!.toIso8601String();
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
                                '${DateFormat('d MMM yyyy').format(_selectedDate)}  ${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')} น.',
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
                  AppTextField(
                    controller: _notesController,
                    label: 'บันทึกเพิ่มเติม',
                    hintText:
                        'เพิ่มรายละเอียด เช่น อาการ พฤติกรรม หรือปริมาณอาหาร...',
                    maxLines: 4,
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
        final vaccinesAsync = ref.watch(vaccinesProvider);
        final historyAsync = ref.watch(cowVaccineHistoryProvider(widget.cowId));
        // Wait for both providers
        if (vaccinesAsync.isLoading || historyAsync.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (vaccinesAsync.hasError) {
          return Text('ไม่สามารถโหลดรายการวัคซีนได้: ${vaccinesAsync.error}');
        }
        final vaccines = vaccinesAsync.value ?? [];
        final history = historyAsync.value ?? {};
        // Get cow sex for filtering
        final allCows = ref.watch(cowServiceProvider).cows;
        String? cowSex;
        try {
          cowSex = allCows.firstWhere((c) => c.animalId == widget.cowId).sex;
        } catch (_) {}
        return VaccineForm(
          vaccines: vaccines,
          selectedVaccineId: _selectedVaccineId,
          selectedDoseNumber: _selectedDoseNumber,
          noteController: _vaccineNoteController,
          onVaccineChanged: (id) => setState(() => _selectedVaccineId = id),
          onDoseChanged: (dose) => setState(() => _selectedDoseNumber = dose),
          vaccineHistory: history,
          cowSex: cowSex,
        );
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
      case ActivityType.SICKNESS:
        return IllnessForm(
          symptomsController: _illnessSymptomsController,
        );
      case ActivityType.TREATMENT:
        final sicknessRef =
            widget.initialData['sickness_ref'] as Map<String, dynamic>?;
        return TreatmentForm(
          symptomsController: _symptomsController,
          sicknessRef: sicknessRef,
          selectionMode: _treatmentSelectionMode,
          onSelectionModeChanged: (val) =>
              setState(() => _treatmentSelectionMode = val),
          diseaseType: _diseaseType,
          onDiseaseTypeChanged: (val) => setState(() => _diseaseType = val),
          otherDiseaseController: _otherDiseaseController,
          treatmentMethod: _treatmentMethod,
          onTreatmentMethodChanged: (val) =>
              setState(() => _treatmentMethod = val),
          otherTreatmentController: _otherTreatmentController,
          recoveryStatus: _recoveryStatus,
          onRecoveryStatusChanged: (val) =>
              setState(() => _recoveryStatus = val),
          followUpDate: _followUpDate,
          onFollowUpDateChanged: (val) => setState(() => _followUpDate = val),
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
