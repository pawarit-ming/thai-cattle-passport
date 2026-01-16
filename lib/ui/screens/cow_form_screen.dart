import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CowFormScreen extends StatefulWidget {
  final String? cowId;

  const CowFormScreen({super.key, this.cowId});

  @override
  State<CowFormScreen> createState() => _CowFormScreenState();
}

class _CowFormScreenState extends State<CowFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isEditing = false;

  // Form field controllers
  late TextEditingController _tagIdController;
  late TextEditingController _nameController;
  late TextEditingController _breedController;

  // Placeholder state for image "selection"
  bool _faceImageAdded = false;
  bool _bodyImageAdded = false;
  bool _legsImageAdded = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.cowId != null;

    _tagIdController = TextEditingController();
    _nameController = TextEditingController();
    _breedController = TextEditingController();

    if (_isEditing) {
      // Mock data
      _tagIdController.text = '101';
      _nameController.text = 'Bessie';
      _breedController.text = 'Brahman';
      _faceImageAdded = true;
      _bodyImageAdded = true;
      _legsImageAdded = true;
    }
  }

  @override
  void dispose() {
    _tagIdController.dispose();
    _nameController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primary, // ใช้สีหลัก (สีน้ำตาล)
        foregroundColor: colorScheme.onPrimary, // สีตัวหนังสือ/ไอคอนเป็นสีขาว
        centerTitle: true,
        // ปุ่มย้อนกลับ
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
        title: Text(
          _isEditing ? 'แก้ไขข้อมูลวัว' : 'เพิ่มวัวใหม่',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        physics: const ClampingScrollPhysics(), // ป้องกันการเด้งไปมา
        onStepTapped: (step) => setState(() => _currentStep = step),
        onStepContinue: () {
          final isLastStep = _currentStep == _getSteps().length - 1;
          if (isLastStep) {
            _saveForm();
          } else {
            setState(() => _currentStep += 1);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        // ปรับแต่งสีของปุ่มใน Stepper
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Row(
              children: [
                FilledButton(
                  onPressed: details.onStepContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                  ),
                  child: Text(
                      _currentStep == _getSteps().length - 1 ? 'บันทึก' : 'ถัดไป'),
                ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  OutlinedButton(
                    onPressed: details.onStepCancel,
                    child: const Text('ย้อนกลับ'),
                  ),
              ],
            ),
          );
        },
        steps: _getSteps(),
      ),
    );
  }

  void _saveForm() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กำลังบันทึกข้อมูล...')),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }
  }

  List<Step> _getSteps() {
    return [
      Step(
        title: const Text('รูปถ่ายระบุตัวตน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('กรุณาถ่ายรูปให้ชัดเจนเพื่อใช้ในการระบุตัวตน'),
            const SizedBox(height: 16),
            _buildPhotoPicker(
              label: 'รูปหน้าตรง',
              isAdded: _faceImageAdded,
              onTap: () => setState(() => _faceImageAdded = true),
            ),
            _buildPhotoPicker(
              label: 'รูปด้านข้างลำตัว',
              isAdded: _bodyImageAdded,
              onTap: () => setState(() => _bodyImageAdded = true),
            ),
            _buildPhotoPicker(
              label: 'รูปขา/ตำหนิ',
              isAdded: _legsImageAdded,
              onTap: () => setState(() => _legsImageAdded = true),
            ),
          ],
        ),
      ),
      Step(
        title: const Text('ข้อมูลรายละเอียด', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        content: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 8),
              // --- 1. ช่อง Tag ID ---
              _buildStyledTextField(
                controller: _tagIdController,
                label: 'Tag ID (เลขหู)',
                icon: Icons.confirmation_number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกเลขหู';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20), // เพิ่มระยะห่าง
              
              // --- 2. ช่อง Name ---
              _buildStyledTextField(
                controller: _nameController,
                label: 'ชื่อวัว',
                icon: Icons.pets,
              ),
              const SizedBox(height: 20),

              // --- 3. ช่อง Breed ---
              _buildStyledTextField(
                controller: _breedController,
                label: 'สายพันธุ์',
                icon: Icons.category,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกสายพันธุ์';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // Helper Widget สำหรับสร้าง TextField สวยๆ
  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon), // ไอคอนนำหน้า
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // ขอบมน
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400), // สีขอบปกติ
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2), // สีขอบตอนพิมพ์
        ),
        filled: true,
        fillColor: Colors.grey.shade50, // พื้นหลังสีเทาอ่อน
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildPhotoPicker({
    required String label,
    required bool isAdded,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: isAdded ? colorScheme.primaryContainer.withOpacity(0.3) : Colors.white,
            border: Border.all(
              color: isAdded ? colorScheme.primary : Colors.grey.shade400, 
              width: isAdded ? 2 : 1
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Center(
            child: isAdded
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: colorScheme.primary, size: 32),
                      const SizedBox(width: 8),
                      Text(
                        '$label เรียบร้อย',
                        style: TextStyle(
                            color: colorScheme.primary, 
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, color: Colors.grey.shade600, size: 30),
                      const SizedBox(height: 8),
                      Text(label, style: TextStyle(color: Colors.grey.shade700)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}