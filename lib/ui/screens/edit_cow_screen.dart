import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:th_cow_passport/services/cow_management/cow_detail/cow_detail_service.dart';
import 'package:th_cow_passport/services/cow_management/cow_list/cow_list_service.dart';
import 'package:th_cow_passport/ui/widgets/cow_detail_widget.dart';
import 'package:th_cow_passport/ui/widgets/cow_selection_field.dart';

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

  final List<String> _breedOptions = [
    'บราห์มัน',
    'ชาร์โรเลส์',
    'วากิว',
    'แองกัส',
    'ฮินดูบราซิล',
    'พื้นเมือง',
    'อื่น'
  ];

  final List<String> _colorOptions = [
    'ขาว',
    'ดำ',
    'แดง',
    'น้ำตาล',
    'ด่าง',
    'อื่น'
  ];

// Tab Controller
  late TabController _tabController;

// Controllers สำหรับทุกฟิลด์
  late TextEditingController _nameController;
  late TextEditingController _nidController;
  late TextEditingController _breedController;
  late TextEditingController _colorController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;

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

      final updatedCow = currentCow.copyWith(
        animalName: _nameController.text,
        nidNumber: _nidController.text,
        breed: _breedController.text,
        color: _colorController.text,
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
      final errorMessage =
          await ref.read(cowDetailServiceProvider).updateCow(updatedCow);

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
        context.pop(); // กลับไปหน้า Detail
      } else if (errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $errorMessage')),
        );
      }
    }
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
        images: [
          if (cow.facePic != null) ...cow.facePic!,
        ],
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
          _buildStyledTextField(
              label: 'ชื่อวัว',
              controller: _nameController,
              icon: Icons.pets,
              isRequired: true),
          SizedBox(height: 16.h),
          _buildStyledTextField(
              label: 'Tag ID',
              controller: _nidController,
              icon: Icons.tag,
              isRequired: true),
          SizedBox(height: 16.h),
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
                    _breedController.text = value ?? '';
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
          SizedBox(height: 16.h),

          // เพิ่มส่วนเลือกวันที่และเพศเพื่อให้แก้ไขได้ทุกอย่าง
          ListTile(
            title: const Text("วันเกิด"),
            subtitle: Text(
                _selectedBirthDate?.toIso8601String().substring(0, 10) ??
                    "ระบุวันที่"),
            leading: const Icon(Icons.calendar_today),
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
          DropdownButtonFormField<String>(
            initialValue: _selectedSex,
            decoration: InputDecoration(
              labelText: 'เพศ',
              prefixIcon: const Icon(Icons.wc),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            items: const [
              DropdownMenuItem(value: 'MALE', child: Text('ผู้')),
              DropdownMenuItem(value: 'FEMALE', child: Text('เมีย')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _selectedSex = value);
            },
          ),
          SizedBox(height: 16.h),
          DropdownButtonFormField<String>(
            initialValue: _selectedStatus,
            decoration: InputDecoration(
              labelText: 'สถานะ',
              prefixIcon: const Icon(Icons.info),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            items: const [
              DropdownMenuItem(value: 'ACTIVE', child: Text('ใช้งาน')),
              DropdownMenuItem(value: 'SOLD', child: Text('ขายแล้ว')),
              DropdownMenuItem(value: 'DECEASED', child: Text('ตายแล้ว')),
              DropdownMenuItem(value: 'SICK', child: Text('ป่วย')),
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
                  child: _buildStyledTextField(
                      label: 'น้ำหนัก (กก.)',
                      controller: _weightController,
                      icon: Icons.monitor_weight,
                      suffixText: 'กก.',
                      keyboardType: TextInputType.number)),
              SizedBox(width: 16.w),
              Expanded(
                  child: _buildStyledTextField(
                      label: 'ส่วนสูง (ซม.)',
                      controller: _heightController,
                      icon: Icons.height,
                      suffixText: 'ซม.',
                      keyboardType: TextInputType.number)),
            ],
          ),
          SizedBox(height: 16.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('สีตัว', style: Theme.of(context).textTheme.labelLarge),
              SizedBox(height: 8.h),
              DropdownButtonFormField<String>(
                initialValue: _colorOptions.contains(_colorController.text)
                    ? _colorController.text
                    : null,
                decoration: InputDecoration(
                  hintText: 'เลือกสี',
                  prefixIcon: const Icon(Icons.palette),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                ),
                items: _colorOptions.map((color) {
                  return DropdownMenuItem(
                    value: color,
                    child: Text(color),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _colorController.text = value ?? '';
                  });
                },
                validator: (value) {
                  // Optional field check if necessary, or keep standard
                  return null;
                },
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildStyledTextField(
              label: 'สีตัว',
              controller: _colorController,
              icon: Icons.palette),
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

  Widget _buildStyledTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hintText,
    String? suffixText,
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
              final n = double.tryParse(value);
              if (n == null) {
                return 'กรุณากรอกตัวเลขที่ถูกต้อง';
              }
              // Based on "precision 5, scale 2", the max value is 999.99
              if ((label.contains('น้ำหนัก') || label.contains('ส่วนสูง')) &&
                  n >= 1000) {
                return 'ค่าต้องน้อยกว่า 1,000';
              }
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hintText ?? label,
            suffixText: suffixText,
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
}
