import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:th_cow_passport/services/cow_management/cow_detail/cow_detail_service.dart';
import 'package:th_cow_passport/services/farm/model/farm_model.dart';
import 'package:th_cow_passport/services/cow_management/models/cow_model.dart';
import 'package:th_cow_passport/ui/widgets/cow_detail_widget.dart';
import 'package:th_cow_passport/supabase_config.dart';
import 'package:th_cow_passport/ui/screens/cow_form/steps/image_picker_step.dart';
import 'package:th_cow_passport/ui/screens/cow_form/tabs/general_info_tab.dart';
import 'package:th_cow_passport/ui/screens/cow_form/tabs/physical_info_tab.dart';
import 'package:th_cow_passport/services/cow_management/cow_list/cow_list_service.dart';

final logger = Logger();

class CowFormScreen extends ConsumerStatefulWidget {
  const CowFormScreen({super.key});

  @override
  ConsumerState<CowFormScreen> createState() => _CowFormScreenState();
}

class _CowFormScreenState extends ConsumerState<CowFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // State
  bool _isImagePickerStep = true;
  bool _isSaveButtonEnabled = false;

  // Tab Controller
  late TabController _tabController;

  // Form field controllers
  late TextEditingController _nidNumberController;
  late TextEditingController _animalNameController;
  late TextEditingController _breedController;
  late TextEditingController _colorController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  // Parent Selection State
  int? _selectedSireId;
  int? _selectedDamId;

  // Farm selection
  Farm? _selectedFarm;

  // Image files
  File? _faceImage;
  File? _bodyImage;

  DateTime _birthDate = DateTime.now();
  String _sex = 'MALE'; // Default to MALE

  void _updateSaveButtonState() {
    final isEnabled = _nidNumberController.text.isNotEmpty &&
        _animalNameController.text.isNotEmpty &&
        _breedController.text.isNotEmpty;
    if (_isSaveButtonEnabled != isEnabled) {
      setState(() {
        _isSaveButtonEnabled = isEnabled;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nidNumberController = TextEditingController();
    _animalNameController = TextEditingController();
    _breedController = TextEditingController();
    _colorController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();

    _nidNumberController.addListener(_updateSaveButtonState);
    _animalNameController.addListener(_updateSaveButtonState);
    _breedController.addListener(_updateSaveButtonState);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nidNumberController.removeListener(_updateSaveButtonState);
    _animalNameController.removeListener(_updateSaveButtonState);
    _breedController.removeListener(_updateSaveButtonState);
    _nidNumberController.dispose();
    _animalNameController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // --- Form Saving Logic ---

  void _saveForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      logger.w('[CowForm] Form validation failed');
      return;
    }

    if (_selectedFarm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกฟาร์ม')),
      );
      logger.w('[CowForm] No farm selected');
      return;
    }

    final cowService = ref.read(cowDetailServiceProvider);

    // Get current user ID from Supabase auth
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ข้อผิดพลาด: ไม่พบข้อมูลผู้ใช้')),
      );
      logger.e('[CowForm] User ID not found');
      return;
    }

    final newCow = Cow(
      farmId: _selectedFarm!.id,
      userId: userId,
      nidNumber: _nidNumberController.text,
      animalName: _animalNameController.text,
      breed: _breedController.text,
      birthDate: _birthDate,
      sex: _sex,
      color: _colorController.text,
      height: double.tryParse(_heightController.text),
      weight: double.tryParse(_weightController.text),
      damId: _selectedDamId,
      sireId: _selectedSireId,
      status: 'ACTIVE',
      facePic: [],
      bodyPic: [],
    );

    try {
      logger.i('[CowForm] Saving cow: ${_animalNameController.text}');
      final success = await cowService.addCow(
        newCow,
        facePic: _faceImage,
        bodyPic: _bodyImage,
      );

// ... inside _saveForm ...

      if (success && mounted) {
        logger.i('[CowForm] Cow saved successfully');

        // Refresh the list
        await ref.read(cowServiceProvider).fetchCows(forceRefresh: true);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลวัวเรียบร้อยแล้ว')),
        );
        context.go('/'); // Go to home/list page after success
      } else if (mounted) {
        logger.e('[CowForm] Failed to save cow');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล')),
        );
      }
    } catch (e) {
      logger.e('[CowForm] Error saving cow', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ละทิ้งข้อมูล?'),
        content: const Text(
            'ข้อมูลที่คุณกรอกจะยังไม่ถูกบันทึก คุณต้องการออกจากหน้านี้ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ออกจากหน้า'),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  // --- UI Building ---
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!_isImagePickerStep) {
          setState(() => _isImagePickerStep = true);
        } else {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          }
        }
      },
      child: _isImagePickerStep ? _buildImagePickerStep() : _buildFormStep(),
    );
  }

  Widget _buildImagePickerStep() {
    return ImagePickerStep(
      faceImage: _faceImage,
      bodyImage: _bodyImage,
      onFaceImageChanged: (file) => setState(() => _faceImage = file),
      onBodyImageChanged: (file) => setState(() => _bodyImage = file),
      onNext: () => setState(() => _isImagePickerStep = false),
      onBack: () async {
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        }
      },
    );
  }

  Widget _buildFormStep() {
    final cowService = ref.watch(cowDetailServiceProvider);
    return Form(
      key: _formKey,
      child: CowDetailWidget(
        title: 'เพิ่มวัวใหม่ (ขั้นตอนที่ 2/2)',
        images: [
          if (_faceImage != null) _faceImage!.path,
          if (_bodyImage != null) _bodyImage!.path,
        ],
        tabController: _tabController,
        tabs: const [
          Tab(text: 'ข้อมูลทั่วไป'),
          Tab(text: 'ข้อมูลกายภาพ'),
        ],
        tabViews: [
          GeneralInfoTab(
            nidNumberController: _nidNumberController,
            animalNameController: _animalNameController,
            breedController: _breedController,
            birthDate: _birthDate,
            onBirthDateChanged: (date) => setState(() => _birthDate = date),
            sex: _sex,
            onSexChanged: (val) {
              if (val != null) setState(() => _sex = val);
            },
            selectedFarm: _selectedFarm,
            onFarmChanged: (farm) => setState(() => _selectedFarm = farm),
          ),
          PhysicalInfoTab(
            weightController: _weightController,
            heightController: _heightController,
            colorController: _colorController,
            selectedSireId: _selectedSireId,
            selectedDamId: _selectedDamId,
            onSireSelected: (cow) {
              setState(() {
                _selectedSireId = cow?.animalId;
              });
            },
            onDamSelected: (cow) {
              setState(() {
                _selectedDamId = cow?.animalId;
              });
            },
          ),
        ],
        bottomBar: _buildBottomSaveBar(cowService.isLoading),
        onBack: () => setState(() => _isImagePickerStep = true),
      ),
    );
  }

  Widget _buildBottomSaveBar(bool isLoading) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 4.r, offset: Offset(0, -2.h))
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: isLoading || !_isSaveButtonEnabled ? null : _saveForm,
          icon: isLoading
              ? Container(
                  width: 24.r,
                  height: 24.r,
                  padding: EdgeInsets.all(2.r),
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : const Icon(Icons.save),
          label: Text('บันทึกข้อมูลวัว',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            disabledBackgroundColor: Colors.grey.shade400,
            minimumSize: Size(double.infinity, 56.h),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r)),
          ),
        ),
      ),
    );
  }
}
