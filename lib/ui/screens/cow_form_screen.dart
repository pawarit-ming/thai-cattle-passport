import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:th_cow_passport/services/cow_management/cow_detail/cow_detail_service.dart';
import 'package:th_cow_passport/services/farm/farm_service.dart';
import 'package:th_cow_passport/services/farm/model/farm_model.dart';
import 'package:th_cow_passport/ui/screens/camera_screen.dart';
import 'package:th_cow_passport/services/cow_management/models/cow_model.dart';
import 'package:th_cow_passport/ui/widgets/cow_detail_widget.dart';
import 'package:th_cow_passport/supabase_config.dart';

final logger = Logger();

class CowFormScreen extends ConsumerStatefulWidget {
  const CowFormScreen({super.key});

  @override
  ConsumerState<CowFormScreen> createState() => _CowFormScreenState();
}

class _CowFormScreenState extends ConsumerState<CowFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final List<String> _breedOptions = [
    'บราห์มัน',
    'ชาร์โรเลส์',
    'วากิว',
    'แองกัส',
    'ฮินดูบราซิล',
    'พื้นเมือง',
    'อื่นๆ'
  ];

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
  late TextEditingController _damIdController;
  late TextEditingController _sireIdController;
  late TextEditingController _sireNameController;
  late TextEditingController _damNameController;

  // Farm selection
  Farm? _selectedFarm;

  // Image files
  File? _faceImage;
  File? _bodyImage;
  File? _markImage;

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
    _damIdController = TextEditingController();
    _sireIdController = TextEditingController();
    _sireNameController = TextEditingController();
    _damNameController = TextEditingController();

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
    _damIdController.dispose();
    _sireIdController.dispose();
    _sireNameController.dispose();
    _damNameController.dispose();
    super.dispose();
  }

  // --- Image Picking Logic ---

  Future<void> _pickImage(
      ImageSource source, Function(File) onImageSelected) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          onImageSelected(File(pickedFile.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _navigateAndGetImage(
      String title, Function(File) onImageSelected) async {
    final imagePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(baseTitle: title),
      ),
    );

    if (imagePath != null) {
      setState(() {
        onImageSelected(File(imagePath));
      });
    }
  }

  void _showImageSourceDialog(String title, Function(File) onImageSelected) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('เลือกจากคลังภาพ'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery, onImageSelected);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('ถ่ายภาพ'),
              onTap: () {
                Navigator.of(context).pop();
                _navigateAndGetImage(title, onImageSelected);
              },
            ),
          ],
        ),
      ),
    );
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
      damId: int.tryParse(_damIdController.text),
      sireId: int.tryParse(_sireIdController.text),
      sireName:
          _sireNameController.text.isNotEmpty ? _sireNameController.text : null,
      damName:
          _damNameController.text.isNotEmpty ? _damNameController.text : null,
      status: 'ACTIVE',
      facePic: [],
      bodyPic: [],
      markPic: [],
    );

    try {
      logger.i('[CowForm] Saving cow: ${_animalNameController.text}');

      final success = await cowService.addCow(
        newCow,
        facePic: _faceImage,
        bodyPic: _bodyImage,
        markPic: _markImage,
      );

      if (success && mounted) {
        logger.i('[CowForm] Cow saved successfully');
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

  // --- เพิ่มฟังก์ชันนี้สำหรับสร้างฟาร์มแบบด่วน ---
  Future<void> _showCreateFarmDialog() async {
    final nameController = TextEditingController();
    final provinceController = TextEditingController();
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return;

    // กำหนดสไตล์ของขอบเตรียมไว้ใช้ร่วมกัน
    final defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide:
          BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: const Text('สร้างฟาร์มใหม่'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('กรุณากรอกข้อมูลเบื้องต้นเพื่อสร้างฟาร์ม'),
            SizedBox(height: 16.h),
            // ช่องกรอกชื่อฟาร์ม
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'ชื่อฟาร์ม *',
                hintText: 'เช่น ฟาร์มโชคชัย',
                filled: true,
                fillColor: Colors.grey.shade50, // พื้นหลังสีเทาอ่อน
                border: defaultBorder,
                enabledBorder: defaultBorder, // ขอบตอนปกติ
                focusedBorder: focusedBorder, // ขอบตอนกดพิมพ์
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              ),
            ),
            SizedBox(height: 12.h),
            // ช่องกรอกจังหวัด
            TextField(
              controller: provinceController,
              decoration: InputDecoration(
                labelText: 'จังหวัด *',
                hintText: 'เช่น นครราชสีมา',
                filled: true,
                fillColor: Colors.grey.shade50, // พื้นหลังสีเทาอ่อน
                border: defaultBorder,
                enabledBorder: defaultBorder, // ขอบตอนปกติ
                focusedBorder: focusedBorder, // ขอบตอนกดพิมพ์
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              // ตรวจสอบว่ากรอกครบทั้งคู่
              if (nameController.text.trim().isEmpty ||
                  provinceController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กรุณากรอกชื่อฟาร์มและจังหวัด'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }

              try {
                // เพิ่ม field 'province' เข้าไปในคำสั่ง insert
                await supabase.from('farms').insert({
                  'user_id': userId,
                  'farm_name': nameController.text.trim(),
                  'province': provinceController.text.trim(),
                });

                if (mounted) {
                  ref.invalidate(userFarmsProvider(userId));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('สร้างฟาร์มเรียบร้อยแล้ว')),
                  );
                }
              } catch (e) {
                logger.e(e);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'เกิดข้อผิดพลาด: ${e.toString().split('\n').first}'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r)),
            ),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  // --- UI Building ---
  @override
  Widget build(BuildContext context) {
    // 1. เพิ่ม PopScope เพื่อจัดการปุ่ม Back ของ Android (Hardware Back Button)
    return PopScope(
      // ถ้าอยู่ขั้นตอนที่ 1 (Image Picker) อนุญาตให้ปิดหน้านี้ได้เลย (canPop = true)
      // ถ้าอยู่ขั้นตอนที่ 2 (Form) ห้ามปิดหน้า (canPop = false) เพื่อเราจะเขียน logic ถอยไปขั้นตอน 1 เอง
      canPop: _isImagePickerStep,
      onPopInvoked: (didPop) {
        if (didPop) return;
        // Logic สำหรับขั้นตอนที่ 2: เมื่อกด Back ให้กลับไปขั้นตอนที่ 1
        setState(() => _isImagePickerStep = true);
      },
      child: _isImagePickerStep ? _buildImagePickerStep() : _buildFormStep(),
    );
  }

  Widget _buildImagePickerStep() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canContinue =
        _faceImage != null && _bodyImage != null && _markImage != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มวัวใหม่ (ขั้นตอนที่ 1/2)'),
        centerTitle: true,
        // 2. ปรับปุ่ม Back บน AppBar ให้ทำงานได้แน่นอนขึ้น
        leading: BackButton(
          onPressed: () {
            // เช็คว่าถอยหลังได้ไหม
            if (context.canPop()) {
              context.pop();
            } else {
              // ถ้าถอยไม่ได้ (เช่น refresh หน้ามา) ให้บังคับกลับไปหน้าแรก
              context.go('/');
            }
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('รูปถ่ายระบุตัวตน',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp)),
            SizedBox(height: 8.h),
            const Text(
                'กรุณาเพิ่มรูปภาพให้ครบทั้ง 3 รูปเพื่อใช้ในการระบุตัวตน'),
            SizedBox(height: 24.h),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildPhotoPicker(
                      label: 'รูปหน้าตรง',
                      imageFile: _faceImage,
                      onTap: () => _showImageSourceDialog('รูปหน้าตรง',
                          (file) => setState(() => _faceImage = file)),
                    ),
                    _buildPhotoPicker(
                      label: 'รูปด้านข้างลำตัว',
                      imageFile: _bodyImage,
                      onTap: () => _showImageSourceDialog('รูปด้านข้างลำตัว',
                          (file) => setState(() => _bodyImage = file)),
                    ),
                    _buildPhotoPicker(
                      label: 'รูปขา/ตำหนิ',
                      imageFile: _markImage,
                      onTap: () => _showImageSourceDialog('รูปขา/ตำหนิ',
                          (file) => setState(() => _markImage = file)),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('ถัดไป'),
                onPressed: canContinue
                    ? () => setState(() => _isImagePickerStep = false)
                    : null,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  backgroundColor: colorScheme.primary,
                  disabledBackgroundColor: Colors.grey.shade400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormStep() {
    final cowService = ref.watch(cowDetailServiceProvider);
    return Form(
      key: _formKey,
      child: CowDetailWidget(
        title: 'เพิ่มวัวใหม่ (ขั้นตอนที่ 2/2)',
        // Use the first image as the header image
        images: [
          if (_faceImage != null) _faceImage!.path,
          if (_bodyImage != null) _bodyImage!.path,
          if (_markImage != null) _markImage!.path,
        ],
        tabController: _tabController,
        tabs: const [
          Tab(text: 'ข้อมูลทั่วไป'),
          Tab(text: 'ข้อมูลกายภาพ'),
        ],
        tabViews: [
          _buildGeneralTab(),
          _buildPhysicalTab(),
        ],
        bottomBar: _buildBottomSaveBar(cowService.isLoading),
        onBack: () => setState(() => _isImagePickerStep = true),
      ),
    );
  }

  Widget _buildGeneralTab() {
    final userId = supabase.auth.currentUser?.id;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          // Farm Selection Dropdown
          if (userId != null)
            Consumer(
              builder: (context, ref, child) {
                final farmsAsync = ref.watch(userFarmsProvider(userId));

                return farmsAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) {
                    logger.e('[CowForm] Error loading farms',
                        error: error, stackTrace: stack);
                    return Text('Error loading farms: $error');
                  },
                  data: (farms) {
                    if (farms.isEmpty) {
                      // --- แก้ไขตรงนี้: เปลี่ยนจากกล่องข้อความธรรมดา เป็นปุ่มให้กดสร้าง ---
                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.r),
                        margin: EdgeInsets.only(bottom: 16.h),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.orange, size: 40),
                            SizedBox(height: 8.h),
                            const Text(
                              'คุณยังไม่มีข้อมูลฟาร์ม',
                              style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold),
                            ),
                            const Text('ต้องสร้างฟาร์มก่อนจึงจะเพิ่มวัวได้'),
                            SizedBox(height: 12.h),
                            ElevatedButton.icon(
                              onPressed:
                                  _showCreateFarmDialog, // เรียกฟังก์ชันที่สร้างไว้
                              icon: const Icon(Icons.add_home_work),
                              label: const Text('สร้างฟาร์มใหม่'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('ฟาร์ม',
                                style: Theme.of(context).textTheme.labelLarge),
                            const Text(' *',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        DropdownButtonFormField<Farm>(
                          initialValue: _selectedFarm ??
                              (farms.isNotEmpty ? farms.first : null),
                          decoration: InputDecoration(
                            //labelText: 'เลือกฟาร์ม',
                            prefixIcon: const Icon(Icons.home),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          items: farms
                              .map((farm) => DropdownMenuItem(
                                    value: farm,
                                    child: Text(farm.farmName),
                                  ))
                              .toList(),
                          onChanged: (farm) {
                            setState(() {
                              _selectedFarm = farm;
                              logger.i(
                                  '[CowForm] Farm selected: ${farm?.farmName}');
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'กรุณาเลือกฟาร์ม';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                      ],
                    );
                  },
                );
              },
            ),
          _buildStyledTextField(
            controller: _nidNumberController,
            label: 'Tag ID (เลขหู)',
            hintText: 'เช่น 1234567890123',
            icon: Icons.confirmation_number,
            isRequired: true,
          ),
          SizedBox(height: 16.h),
          _buildStyledTextField(
            controller: _animalNameController,
            label: 'ชื่อวัว',
            hintText: 'เช่น สมศรี, บุญรอด',
            icon: Icons.pets,
            isRequired: true,
          ),
          SizedBox(height: 16.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('สายพันธุ์',
                      style: Theme.of(context).textTheme.labelLarge),
                  const Text(' *', style: TextStyle(color: Colors.red)),
                ],
              ),
              SizedBox(height: 8.h),
              DropdownButtonFormField<String>(
                // ตรวจสอบว่าค่าที่มีอยู่ใน controller ตรงกับใน list หรือไม่ เพื่อกัน error
                initialValue: _breedOptions.contains(_breedController.text)
                    ? _breedController.text
                    : null,
                decoration: InputDecoration(
                  hintText: 'เลือกสายพันธุ์',
                  prefixIcon: const Icon(Icons.category),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                ),
                items: _breedOptions.map((breed) {
                  return DropdownMenuItem(
                    value: breed,
                    child: Text(breed),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    // อัปเดตค่าลง Controller เพื่อให้ Logic การ Save เดิมทำงานได้
                    _breedController.text = value ?? '';
                    _updateSaveButtonState();
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณาเลือกสายพันธุ์';
                  }
                  return null;
                },
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('วันเกิด',
                      style: Theme.of(context).textTheme.labelLarge),
                  const Text(' *', style: TextStyle(color: Colors.red)),
                ],
              ),
              SizedBox(height: 8.h),
              TextFormField(
                readOnly:
                    true, // ตั้งเป็นอ่านอย่างเดียว เพื่อไม่ให้คีย์บอร์ดเด้ง
                // ใช้ key เพื่อให้ Widget รีเฟรชค่าใหม่ทันทีที่ตัวแปร _birthDate เปลี่ยน
                key: ValueKey(_birthDate),
                initialValue: MaterialLocalizations.of(context)
                    .formatShortDate(_birthDate),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: const Icon(
                      Icons.arrow_drop_down), // เพิ่มลูกศรให้รู้ว่ากดเลือกได้
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _birthDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null && picked != _birthDate) {
                    setState(() => _birthDate = picked);
                  }
                },
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('เพศ', style: Theme.of(context).textTheme.labelLarge),
                  const Text(' *', style: TextStyle(color: Colors.red)),
                ],
              ),
              SizedBox(height: 8.h),
              DropdownButtonFormField<String>(
                initialValue: _sex, // ใช้ value เพื่อให้แสดงค่าปัจจุบันเสมอ
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.wc),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                ),
                items: const [
                  DropdownMenuItem(value: 'MALE', child: Text('ผู้')),
                  DropdownMenuItem(value: 'FEMALE', child: Text('เมีย')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sex = value);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicalTab() {
    // This tab does not need its own Form key as it's part of the parent Form
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStyledTextField(
                    label: 'น้ำหนัก (กก.)',
                    hintText: 'เช่น 450.5',
                    controller: _weightController,
                    icon: Icons.monitor_weight,
                    keyboardType: TextInputType.number),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildStyledTextField(
                    label: 'ส่วนสูง (ซม.)',
                    hintText: 'เช่น 150',
                    controller: _heightController,
                    icon: Icons.height,
                    keyboardType: TextInputType.number),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildStyledTextField(
            controller: _colorController,
            label: 'สี',
            hintText: 'เช่น ขาว, ดำ, แดง',
            icon: Icons.color_lens,
          ),
          SizedBox(height: 16.h),
          _buildStyledTextField(
              label: 'ชื่อพ่อพันธุ์',
              hintText: 'เช่น บราห์มัน',
              controller: _sireNameController,
              icon: Icons.male),
          SizedBox(height: 16.h),
          _buildStyledTextField(
              label: 'ID พ่อพันธุ์',
              hintText: 'Tag ID ของพ่อพันธุ์',
              controller: _sireIdController,
              icon: Icons.male,
              keyboardType: TextInputType.number),
          SizedBox(height: 16.h),
          _buildStyledTextField(
              label: 'ชื่อแม่พันธุ์',
              hintText: 'เช่น โลลิตา',
              controller: _damNameController,
              icon: Icons.female),
          SizedBox(height: 16.h),
          _buildStyledTextField(
              label: 'ID แม่พันธุ์',
              hintText: 'Tag ID ของแม่พันธุ์',
              controller: _damIdController,
              icon: Icons.female,
              keyboardType: TextInputType.number),
        ],
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
                borderRadius: BorderRadius.circular(12.r)),
          ),
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    bool isRequired = false,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: theme.textTheme.labelLarge),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Colors.red)),
            if (!isRequired)
              Text(
                ' (ไม่บังคับ)',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.sp),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return 'กรุณากรอก $label';
            }
            if (keyboardType == TextInputType.number &&
                value != null &&
                value.isNotEmpty) {
              if (double.tryParse(value) == null) {
                return 'กรุณากรอกตัวเลขที่ถูกต้อง';
              }
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: Colors.grey.shade50,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPicker({
    required String label,
    required File? imageFile,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAdded = imageFile != null;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(
                color: isAdded ? colorScheme.primary : Colors.grey.shade300,
                width: isAdded ? 2.w : 1.w,
              ),
              borderRadius: BorderRadius.circular(12.r),
              image: isAdded
                  ? DecorationImage(
                      image: FileImage(imageFile), fit: BoxFit.cover)
                  : null,
            ),
            child: isAdded
                ? Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      margin: EdgeInsets.all(8.r),
                      padding: EdgeInsets.all(4.r),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, color: Colors.white, size: 20.r),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            color: Colors.grey.shade600, size: 36.r),
                        SizedBox(height: 8.h),
                        Text(label,
                            style: TextStyle(color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
