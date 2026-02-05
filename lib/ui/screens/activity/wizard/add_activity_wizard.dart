import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:th_cow_passport/services/cow_management/models/activity_model.dart';
import 'package:th_cow_passport/services/cow_management/cow_detail/cow_detail_service.dart';
import 'package:th_cow_passport/services/cow_management/cow_activity/activity_service.dart';
import 'package:th_cow_passport/ui/screens/activity/wizard/wizard_constants.dart';
import 'package:th_cow_passport/ui/screens/activity/wizard/step1_type_selection.dart';
import 'package:th_cow_passport/ui/screens/activity/wizard/step2_form_input.dart';
import 'package:th_cow_passport/ui/screens/activity/wizard/step3_summary.dart';

class AddActivityWizard extends ConsumerStatefulWidget {
  final int cowId;

  const AddActivityWizard({super.key, required this.cowId});

  @override
  ConsumerState<AddActivityWizard> createState() => _AddActivityWizardState();
}

class _AddActivityWizardState extends ConsumerState<AddActivityWizard> {
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Wizard State
  ActivityType? _selectedType;
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic> _formData = {};
  String? _notes;

  @override
  void initState() {
    super.initState();
    // Ensure we have the correct cow data loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = ref.read(cowDetailServiceProvider);
      if (service.currentCow?.animalId != widget.cowId) {
        service.fetchCowById(widget.cowId);
      }
    });
  }

  Future<void> _handleTypeSelection(ActivityType type) async {
    setState(() => _selectedType = type);

    if (type == ActivityType.PREGNANCY_CHECK || type == ActivityType.BIRTH) {
      // Check for breeding history
      final activities =
          await ref.read(activitiesProvider(widget.cowId).future);
      final hasBreeding = activities
          .any((activity) => activity.activityType == ActivityType.BREEDING);

      if (!hasBreeding && mounted) {
        final shouldProceed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('ไม่พบประวัติการผสมพันธุ์'),
            content: const Text(
              'วัวตัวนี้ยังไม่มีบันทึกการผสมพันธุ์ในระบบ\nคุณต้องการบันทึกข้อมูลต่อหรือไม่?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false), // Cancel
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
                child: const Text('ยกเลิก'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true), // Confirm
                child: const Text('ยืนยัน (บันทึกต่อ)'),
              ),
            ],
          ),
        );

        if (shouldProceed != true) {
          // User cancelled, clear selection and stay on Step 1
          setState(() => _selectedType = null);
          return;
        }
      }
    }

    _nextStep();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop(); // Cancel if back on step 1
    }
  }

  void _goToStep(int step) {
    if (step >= 0 && step < _totalSteps) {
      setState(() => _currentStep = step);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Get Cow Data
    final detailState = ref.watch(cowDetailServiceProvider);
    final cow = detailState.currentCow;

    // 2. Loading State
    if (detailState.isLoading || cow == null || cow.animalId != widget.cowId) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final cowSex = cow.sex; // 'MALE' or 'FEMALE'

    String title = 'กิจกรรมใหม่';
    if (_currentStep == 2) title = 'สรุปข้อมูล';

    return Scaffold(
      backgroundColor: WizardColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: WizardColors.textDark),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          style: WizardStyles.titleMedium,
        ),
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                Step1TypeSelection(
                  cowSex: cowSex,
                  onTypeSelected: _handleTypeSelection,
                ),
                // Only build Step 2 if type is selected
                if (_selectedType != null)
                  Step2FormInput(
                    cowId: widget.cowId,
                    activityType: _selectedType!,
                    initialData: _formData,
                    initialDate: _selectedDate,
                    initialNotes: _notes,
                    onNext: (data, date, notes) {
                      setState(() {
                        _formData = data;
                        _selectedDate = date;
                        _notes = notes;
                      });
                      _nextStep();
                    },
                    onBack: _prevStep,
                  )
                else
                  const SizedBox
                      .shrink(), // Placeholder if Step 1 not done (IndexedStack loads all)

                // Only build Step 3 if type is selected
                if (_selectedType != null)
                  Step3Summary(
                    cowId: widget.cowId,
                    type: _selectedType!,
                    date: _selectedDate,
                    data: _formData,
                    notes: _notes,
                    onEdit: () => _goToStep(1),
                    onSaveSuccess: () => context.pop(),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ขั้นตอนที่ ${_currentStep + 1} จาก $_totalSteps',
                style: TextStyle(
                  color: WizardColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                  letterSpacing: 1.2,
                ),
              ),
              if (_currentStep == 0)
                Text(
                  'เลือกประเภท',
                  style: TextStyle(
                    color: WizardColors.textLight,
                    fontSize: 12.sp,
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Stack(
            children: [
              Container(
                height: 6.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: WizardColors.stepIndicatorInactive,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 6.h,
                width:
                    ((MediaQuery.of(context).size.width - 48.w) / _totalSteps) *
                        (_currentStep + 1),
                decoration: BoxDecoration(
                  color: WizardColors.stepIndicatorActive,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
