import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:th_cow_passport/services/cow_management/cow_detail/cow_detail_service.dart';
import 'package:th_cow_passport/ui/widgets/cow_detail_widget.dart';

class EditCowScreen extends ConsumerStatefulWidget {
  final int cowId;
  const EditCowScreen({super.key, required this.cowId});

  @override
  ConsumerState<EditCowScreen> createState() => _EditCowScreenState();
}

class _EditCowScreenState extends ConsumerState<EditCowScreen> with SingleTickerProviderStateMixin {
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
  late TextEditingController _eyeColorController;
  late TextEditingController _noseColorController;
  late TextEditingController _damIdController;
  late TextEditingController _sireIdController;
  late TextEditingController _markNumberController;

  DateTime? _selectedBirthDate;
  String? _selectedSex;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 1. ดึงข้อมูลวัวตัวปัจจุบันจาก Service มาตั้งค่าเริ่มต้น
    final cow = ref.read(cowDetailServiceProvider).currentCow;

    //กำหนดค่าเริ่มต้นจากข้อมูลจริง
    _nameController = TextEditingController(text: cow?.animalName);
    _nidController = TextEditingController(text: cow?.nidNumber);
    _breedController = TextEditingController(text: cow?.breed);
    _colorController = TextEditingController(text: cow?.animalColor);
    _weightController = TextEditingController(text: cow?.weight.toString());
    _heightController = TextEditingController(text: cow?.height.toString());
    _eyeColorController = TextEditingController(text: cow?.eyeColor);
    _noseColorController = TextEditingController(text: cow?.noseColor);
    _damIdController = TextEditingController(text: cow?.damId?.toString());
    _sireIdController = TextEditingController(text: cow?.sireId?.toString());
    _markNumberController = TextEditingController(text: cow?.markNumber);

    _selectedBirthDate = cow?.birthDate;
    _selectedSex = cow?.sex;
    _selectedStatus = cow?.animalStatus;
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
    _eyeColorController.dispose();
    _noseColorController.dispose();
    _damIdController.dispose();
    _sireIdController.dispose();
    _markNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      final currentCow = ref.read(cowDetailServiceProvider).currentCow;
      if (currentCow == null) return;

      final updatedCow = currentCow.copyWith(
        animalName: _nameController.text,
        nidNumber: _nidController.text,
        breed: _breedController.text,
        animalColor: _colorController.text,
        weight: double.tryParse(_weightController.text),
        height: double.tryParse(_heightController.text),
        damId: int.tryParse(_damIdController.text),
        sireId: int.tryParse(_sireIdController.text),
        birthDate: _selectedBirthDate,
        sex: _selectedSex,
        animalStatus: _selectedStatus,
        updatedAt: DateTime.now(),
      );

      // 3. ส่งข้อมูลไปบันทึกที่ Supabase ผ่าน Service
      final errorMessage =
          await ref.read(cowDetailServiceProvider).updateCow(updatedCow);

      if (errorMessage == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกการแก้ไขเรียบร้อยแล้ว')),
        );
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
        imageUrl: cow.facePic,
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
                      keyboardType: TextInputType.number)),
              SizedBox(width: 16.w),
              Expanded(
                  child: _buildStyledTextField(
                      label: 'ส่วนสูง (ซม.)',
                      controller: _heightController,
                      icon: Icons.height,
                      keyboardType: TextInputType.number)),
            ],
          ),
          SizedBox(height: 16.h),
          _buildStyledTextField(
              label: 'สีตัว',
              controller: _colorController,
              icon: Icons.palette),
          SizedBox(height: 16.h),
          _buildStyledTextField(
              label: 'ID พ่อพันธุ์',
              controller: _sireIdController,
              icon: Icons.male,
              keyboardType: TextInputType.number),
          SizedBox(height: 16.h),
          _buildStyledTextField(
              label: 'ID แม่พันธุ์',
              controller: _damIdController,
              icon: Icons.female,
              keyboardType: TextInputType.number),
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
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 12.sp),
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
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r)),
          ),
        ),
      ],
    );
  }
}