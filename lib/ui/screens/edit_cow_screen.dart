import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EditCowScreen extends StatefulWidget {
  final String cowId;
  const EditCowScreen({super.key, required this.cowId});

  @override
  State<EditCowScreen> createState() => _EditCowScreenState();
}

class _EditCowScreenState extends State<EditCowScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _tagIdController;
  late TextEditingController _nameController;
  late TextEditingController _breedController;
  late TextEditingController _dobController;
  late TextEditingController _damController;
  late TextEditingController _sireController;

  @override
  void initState() {
    super.initState();
    // จำลองข้อมูล (Mock Data)
    _tagIdController = TextEditingController(text: '101');
    _nameController = TextEditingController(text: 'Bessie');
    _breedController = TextEditingController(text: 'Brahman');
    _dobController = TextEditingController(text: '2023-01-15');
    _damController = TextEditingController(text: '502');
    _sireController = TextEditingController(text: '007');
  }

  @override
  void dispose() {
    _tagIdController.dispose();
    _nameController.dispose();
    _breedController.dispose();
    _dobController.dispose();
    _damController.dispose();
    _sireController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อัปเดตข้อมูลเรียบร้อยแล้ว')),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/detail'); // หรือ route ที่เหมาะสม
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primary, // สีน้ำตาล
        foregroundColor: colorScheme.onPrimary, // สีขาว
        centerTitle: true,
        title: const Text(
          'แก้ไขข้อมูลวัว',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        // --- ส่วนที่ 1: เพิ่มปุ่มย้อนกลับ ---
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.save),
        //     tooltip: 'บันทึก',
        //     onPressed: _save,
        //   )
        // ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // --- ส่วนที่ 2: ปรับแต่งช่องกรอกข้อมูลให้ชัดเจน ---
              _buildStyledTextField(
                label: 'Tag ID (เลขหู)',
                controller: _tagIdController,
                icon: Icons.confirmation_number,
                isRequired: true,
              ),
              const SizedBox(height: 16),
              
              _buildStyledTextField(
                label: 'ชื่อวัว',
                controller: _nameController,
                icon: Icons.pets,
              ),
              const SizedBox(height: 16),
              
              _buildStyledTextField(
                label: 'สายพันธุ์',
                controller: _breedController,
                icon: Icons.category,
                isRequired: true,
              ),
              const SizedBox(height: 16),
              
              _buildStyledTextField(
                label: 'วันเกิด (YYYY-MM-DD)',
                controller: _dobController,
                icon: Icons.calendar_today,
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStyledTextField(
                      label: 'แม่พันธุ์ (Dam)',
                      controller: _damController,
                      icon: Icons.female,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStyledTextField(
                      label: 'พ่อพันธุ์ (Sire)',
                      controller: _sireController,
                      icon: Icons.male,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // ปุ่มบันทึกขนาดใหญ่ด้านล่าง (เผื่อผู้ใช้ถนัดกดข้างล่าง)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text('บันทึกการแก้ไข', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Helper สำหรับสร้าง TextField สวยๆ (ใช้ Logic เดียวกับ CowFormScreen)
  Widget _buildStyledTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isRequired = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'กรุณากรอกข้อมูล $label';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey.shade50, // พื้นหลังสีเทาอ่อน
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}