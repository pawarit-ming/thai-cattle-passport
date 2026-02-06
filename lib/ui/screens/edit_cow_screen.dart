import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:th_cow_passport/services/cow_management/cow_detail/cow_detail_service.dart';
import 'package:th_cow_passport/services/cow_management/cow_list/cow_list_service.dart';
import 'package:th_cow_passport/services/cow_management/models/cow_model.dart'; // Import Cow Model
import 'package:th_cow_passport/ui/screens/camera_screen.dart'; // Import CameraScreen
import 'package:th_cow_passport/core/constants/animal_constants.dart';
import 'package:th_cow_passport/ui/widgets/cow_detail_widget.dart';
import 'package:th_cow_passport/ui/widgets/cow_selection_field.dart';
import 'package:th_cow_passport/ui/widgets/styled_text_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:th_cow_passport/ui/widgets/styled_dropdown_field.dart';

class EditCowScreen extends ConsumerStatefulWidget {
  final int cowId;
  const EditCowScreen({super.key, required this.cowId});

  @override
  ConsumerState<EditCowScreen> createState() => _EditCowScreenState();
}

class _EditCowScreenState extends ConsumerState<EditCowScreen>
    with SingleTickerProviderStateMixin {
  final logger = Logger();
  final _formKey = GlobalKey<FormState>();

// Tab Controller
  late TabController _tabController;

// Controllers สำหรับทุกฟิลด์
  late TextEditingController _nameController;
  late TextEditingController _nidController;
  late TextEditingController _breedController;
  late TextEditingController _colorController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;

  // Controllers for custom breed/color
  final TextEditingController _customBreedController = TextEditingController();
  final TextEditingController _customColorController = TextEditingController();

  // Lists for new images to be appended
  final List<File> _newFaceFiles = [];
  final List<File> _newBodyFiles = [];
  final List<File> _newMarkFiles = [];

  // Selected dropdown values
  String? _selectedBreed;
  String? _selectedColor;

  // Parent IDs
  int? _selectedSireId;
  int? _selectedDamId;

  DateTime? _selectedBirthDate;
  String? _selectedSex;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 1. ดึงข้อมูลวัวตัวปัจจุบันจาก Service มาตั้งค่าเริ่มต้น
    logger.i('Initializing EditCowScreen for cowId: ${widget.cowId}');
    final cow = ref.read(cowDetailServiceProvider).currentCow;

    //กำหนดค่าเริ่มต้นจากข้อมูลจริง
    _nameController = TextEditingController(text: cow?.animalName);
    _nidController = TextEditingController(text: cow?.nidNumber);
    _breedController = TextEditingController(text: cow?.breed);
    _colorController = TextEditingController(text: cow?.color);
    _weightController = TextEditingController(text: cow?.weight?.toString());
    _heightController = TextEditingController(text: cow?.height?.toString());

    // Initialize dropdown selections
    _selectedBreed =
        AnimalConstants.breedOptions.contains(cow?.breed) ? cow?.breed : null;
    _selectedColor =
        AnimalConstants.colorOptions.contains(cow?.color) ? cow?.color : null;

    // If breed/color is custom (not in list), set to 'อื่นๆ (ระบุ)' and populate custom field
    if (cow?.breed != null &&
        !AnimalConstants.breedOptions.contains(cow!.breed)) {
      _selectedBreed = AnimalConstants.customOption;
      _customBreedController.text = cow.breed!;
    }
    if (cow?.color != null &&
        !AnimalConstants.colorOptions.contains(cow!.color)) {
      _selectedColor = AnimalConstants.customOption;
      _customColorController.text = cow.color!;
    }

    _selectedSireId = cow?.sireId;
    _selectedDamId = cow?.damId;

    _selectedBirthDate = cow?.birthDate;
    _selectedSex = cow?.sex;
    _selectedStatus = cow?.status;
  }

  @override
  void dispose() {
    _tabController.dispose();
    // ล้าง Controller เมื่อหน้าจอถูกทำลาย
    _nameController.dispose();
    _nidController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _customBreedController.dispose();
    _customColorController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      logger.i('Saving updates for cowId: ${widget.cowId}...');
      final currentCow = ref.read(cowDetailServiceProvider).currentCow;
      if (currentCow == null) {
        logger.w('Current cow is null, cannot update');
        return;
      }

      // Determine final breed and color values
      final finalBreed = _selectedBreed == AnimalConstants.customOption
          ? _customBreedController.text
          : _selectedBreed ?? _breedController.text;
      final finalColor = _selectedColor == AnimalConstants.customOption
          ? _customColorController.text
          : _selectedColor ?? _colorController.text;

      final updatedCow = currentCow.copyWith(
        animalName: _nameController.text,
        nidNumber: _nidController.text,
        breed: finalBreed,
        color: finalColor,
        weight: double.tryParse(_weightController.text),
        height: double.tryParse(_heightController.text),
        damId: _selectedDamId,
        sireId: _selectedSireId,
        birthDate: _selectedBirthDate,
        sex: _selectedSex,
        status: _selectedStatus,
        updatedAt: DateTime.now(),
      );

      // 3. ส่งข้อมูลไปบันทึกที่ Supabase ผ่าน Service
      final errorMessage = await ref.read(cowDetailServiceProvider).updateCow(
            updatedCow,
            newFaceFiles: _newFaceFiles,
            newBodyFiles: _newBodyFiles,
            newMarkFiles: _newMarkFiles,
          );

      if (errorMessage != null) {
        logger.e('Error updating cow: $errorMessage');
      } else {
        logger.i('Cow updated successfully');
      }

      if (errorMessage == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกการแก้ไขเรียบร้อยแล้ว')),
        );
        // Force refresh the list so the updated details appear there too.
        ref.read(cowServiceProvider).fetchCows(forceRefresh: true);
        context.pop(true); // กลับไปหน้า Detail พร้อมสัญญาณว่ามีการแก้ไข
      } else if (errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $errorMessage')),
        );
      }
    }
  }

  // Combine existing images (URLs) and new local files (Paths)
  List<String> _getDisplayImages(Cow? cow) {
    if (cow == null) return [];
    List<String> images = [];
    if (cow.facePic != null) images.addAll(cow.facePic!);
    if (cow.bodyPic != null) images.addAll(cow.bodyPic!);
    if (cow.markPic != null) images.addAll(cow.markPic!);

    // Append new local files
    images.addAll(_newFaceFiles.map((f) => f.path));
    images.addAll(_newBodyFiles.map((f) => f.path));
    images.addAll(_newMarkFiles.map((f) => f.path));

    return images;
  }

  Future<void> _handleImageTap() async {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Text(
                  'เพิ่มรูปภาพ',
                  style:
                      TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.face),
                title: const Text('รูปหน้าวัว'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage('face');
                },
              ),
              ListTile(
                leading: const Icon(Icons.pets),
                title: const Text('รูปตัววัว'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage('body');
                },
              ),
              ListTile(
                leading: const Icon(Icons.warning),
                title: const Text('รูปตำหนิ'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage('mark');
                },
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(String type) async {
    showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        builder: (context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('ถ่ายรูป'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromCamera(type);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('เลือกจากอัลบั้ม'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromGallery(type);
                  },
                ),
              ],
            ),
          );
        });
  }

  Future<void> _pickFromCamera(String type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraScreen(
          baseTitle: 'ถ่ายรูป',
          steps: ['ถ่ายรูป'], // Single step
        ),
      ),
    );

    if (result != null) {
      File? file;
      if (result is String) {
        file = File(result);
      } else if (result is List &&
          result.isNotEmpty &&
          result.first is String) {
        file = File(result.first);
      }

      if (file != null) {
        _addImageFile(type, file);
      }
    }
  }

  Future<void> _pickFromGallery(String type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      _addImageFile(type, File(image.path));
    }
  }

  void _addImageFile(String type, File file) {
    setState(() {
      if (type == 'face') {
        _newFaceFiles.add(file);
      } else if (type == 'body') {
        _newBodyFiles.add(file);
      } else if (type == 'mark') {
        _newMarkFiles.add(file);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cow = ref.watch(cowDetailServiceProvider).currentCow;

    if (cow == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Form(
      key: _formKey,
      child: CowDetailWidget(
        title: 'แก้ไขข้อมูล: ${cow.animalName}',
        images: _getDisplayImages(cow),
        isEditable: true,
        onImageTap: _handleImageTap,
        tabController: _tabController,
        tabs: const [
          Tab(text: 'ข้อมูลทั่วไป'),
          Tab(text: 'ข้อมูลกายภาพ'),
        ],
        tabViews: [
          _buildGeneralTab(), // Tab 1
          _buildPhysicalTab(), // Tab 2
        ],
        bottomBar: _buildBottomSaveBar(colorScheme),
        onBack: () => context.pop(),
      ),
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          StyledTextField(
              label: 'ชื่อวัว',
              controller: _nameController,
              icon: Icons.pets,
              isRequired: true),
          SizedBox(height: 16.h),
          StyledTextField(
              label: 'Tag ID',
              controller: _nidController,
              icon: Icons.tag,
              isRequired: true),
          SizedBox(height: 16.h),
          StyledDropdownField<String>(
            label: 'สายพันธุ์',
            isRequired: true,
            hintText: 'เลือกสายพันธุ์',
            value: _selectedBreed,
            icon: Icons.category,
            items: AnimalConstants.breedOptions.map((breed) {
              return DropdownMenuItem(
                value: breed,
                child: Text(breed),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedBreed = value;
              });
            },
          ),
          if (_selectedBreed == AnimalConstants.customOption) ...[
            SizedBox(height: 16.h),
            StyledTextField(
              label: 'ระบุสายพันธุ์',
              controller: _customBreedController,
              icon: Icons.edit,
              hintText: 'เช่น วากิวลูกผสม, บราห์มันแท้',
              isRequired: true,
            ),
          ],
          SizedBox(height: 16.h),

          // เพิ่มส่วนเลือกวันที่และเพศเพื่อให้แก้ไขได้ทุกอย่าง
          StyledTextField(
            label: "วันเกิด",
            controller: TextEditingController(
                text: _selectedBirthDate?.toIso8601String().substring(0, 10) ??
                    "ระบุวันที่"),
            icon: Icons.calendar_today,
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedBirthDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (date != null) setState(() => _selectedBirthDate = date);
            },
          ),
          SizedBox(height: 16.h),
          StyledDropdownField<String>(
            label: 'เพศ',
            value: _selectedSex,
            icon: Icons.wc,
            items: const [
              DropdownMenuItem(value: 'MALE', child: Text('ผู้')),
              DropdownMenuItem(value: 'FEMALE', child: Text('เมีย')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _selectedSex = value);
            },
          ),
          SizedBox(height: 16.h),
          StyledDropdownField<String>(
            label: 'สถานะ',
            value: _selectedStatus,
            icon: Icons.info,
            items: const [
              DropdownMenuItem(value: 'ACTIVE', child: Text('สุขภาพดี')),
              DropdownMenuItem(value: 'SICK', child: Text('ป่วย')),
              DropdownMenuItem(value: 'SOLD', child: Text('ขายแล้ว')),
              DropdownMenuItem(value: 'DEATH', child: Text('ตายแล้ว')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _selectedStatus = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicalTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: StyledTextField(
                      label: 'น้ำหนัก (กก.)',
                      controller: _weightController,
                      icon: Icons.monitor_weight,
                      suffixText: 'กก.',
                      keyboardType: TextInputType.number)),
              SizedBox(width: 16.w),
              Expanded(
                  child: StyledTextField(
                      label: 'ส่วนสูง (ซม.)',
                      controller: _heightController,
                      icon: Icons.height,
                      suffixText: 'ซม.',
                      keyboardType: TextInputType.number)),
            ],
          ),
          SizedBox(height: 16.h),
          StyledDropdownField<String>(
            label: 'สีตัว',
            hintText: 'เลือกสี',
            value: _selectedColor,
            icon: Icons.palette,
            items: AnimalConstants.colorOptions.map((color) {
              return DropdownMenuItem(
                value: color,
                child: Text(color),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedColor = value;
              });
            },
          ),
          if (_selectedColor == AnimalConstants.customOption) ...[
            SizedBox(height: 16.h),
            StyledTextField(
              label: 'ระบุสีตัว',
              controller: _customColorController,
              icon: Icons.edit,
              hintText: 'เช่น เหลืองอ่อน, ส้มแดง',
              isRequired: true,
            ),
          ],
          SizedBox(height: 16.h),

          // Parent Selection
          CowSelectionField(
            label: 'พ่อพันธุ์',
            icon: Icons.male,
            initialCowId: _selectedSireId,
            excludeCowId: widget.cowId,
            onCowSelected: (cow) {
              setState(() {
                _selectedSireId = cow?.animalId;
              });
            },
          ),
          SizedBox(height: 16.h),
          CowSelectionField(
            label: 'แม่พันธุ์',
            icon: Icons.female,
            initialCowId: _selectedDamId,
            excludeCowId: widget.cowId,
            onCowSelected: (cow) {
              setState(() {
                _selectedDamId = cow?.animalId;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSaveBar(ColorScheme colorScheme) {
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
          onPressed: _handleSave,
          icon: const Icon(Icons.save),
          label: Text('บันทึกการเปลี่ยนแปลง',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            minimumSize: Size(double.infinity, 56.h),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r)),
          ),
        ),
      ),
    );
  }
}
