import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:th_cow_passport/services/auth/auth_service.dart';
import 'package:th_cow_passport/services/farm/farm_service.dart';
import 'package:th_cow_passport/ui/screens/auth/steps/role_selection_step.dart';
import 'package:th_cow_passport/features/address/presentation/widgets/thai_address_picker.dart';
import 'package:th_cow_passport/ui/widgets/styled_text_field.dart';

final logger = Logger();

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Step 0: Role Selection
  String _selectedRole = 'FARMER'; // Default

  // Step 1: Auth
  final _authFormKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;
  String? _emailError;

  // Step 2: Farm (Only for Farmer)
  final _farmFormKey = GlobalKey<FormState>();
  late TextEditingController _farmNameController;
  late TextEditingController _addressDetailsController; // House No, Soi, Street
  late TextEditingController _provinceController;
  late TextEditingController _districtController;
  late TextEditingController _subDistrictController;
  late TextEditingController _postalCodeController;

  // Data storage for multi-step
  late String _authEmail;
  late String _authPassword;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _emailError = null;
    _passwordController = TextEditingController();

    // Farm Controllers
    _farmNameController = TextEditingController();
    _addressDetailsController = TextEditingController();
    _provinceController = TextEditingController();
    _districtController = TextEditingController();
    _subDistrictController = TextEditingController();
    _postalCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _farmNameController.dispose();
    _addressDetailsController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _subDistrictController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  // --- Logic Helpers ---

  int get _maxSteps => _selectedRole == 'FARMER' ? 4 : 3;

  Future<void> _handleStepContinue() async {
    logger.i('[RegisterScreen] Current step: $_currentStep');

    // 1. Role Selection
    if (_currentStep == 0) {
      setState(() => _currentStep = 1);
      return;
    }

    // 2. Auth & Profile
    if (_currentStep == 1) {
      if (!_authFormKey.currentState!.validate()) return;

      // If Farmer, just move to next step (collect Farm info first)
      if (_selectedRole == 'FARMER') {
        setState(() => _currentStep = 2);
        return;
      }

      // If Buyer, this is the last step -> Register Now
      await _performRegistration();
      return;
    }

    // 3. Farm Info (Only if Farmer)
    if (_currentStep == 2 && _selectedRole == 'FARMER') {
      if (!_farmFormKey.currentState!.validate()) return;
      // Register (Auth + Farm)
      await _performRegistration();
    }
  }

  Future<void> _performRegistration() async {
    setState(() => _isLoading = true);
    _emailError = null; // Clear previous errors

    try {
      // 1. Sign Up (Create Auth User)
      _authEmail = _emailController.text.trim();
      _authPassword = _passwordController.text;

      final authService = AuthService();
      final authResponse = await authService.signUp(
        email: _authEmail,
        password: _authPassword,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      final userId = authResponse.user?.id;
      if (userId == null) throw Exception('ไม่สามารถสร้างบัญชีผู้ใช้ได้');

      // 2. Create Farm (Only for Farmer)
      if (_selectedRole == 'FARMER') {
        final farmService = FarmService();
        await farmService.createFarm(
          userId: userId, // Pass the newly created ID explicitely
          farmName: _farmNameController.text.trim(),
          province: _provinceController.text.trim(),
          address: _addressDetailsController.text.trim(),
          district: _districtController.text.trim(),
          subDistrict: _subDistrictController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
        );
      }

      if (mounted) {
        _isLoading = false;
        _onSuccess();
      }
    } catch (e) {
      _handleAuthError(e);
      // If error occurs, we might want to stay on the current step or handle cleanup
      // For now, _handleAuthError stops loading and shows error.
    }
  }

  void _onSuccess() {
    setState(() => _currentStep = _maxSteps - 1); // Go to last step

    // Auto redirect after delay if needed, or let user click specific button
    // But currently UI shows Success Step
  }

  void _handleAuthError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('user_already_exists') ||
        msg.contains('Email already registered')) {
      setState(() {
        _emailError = 'อีเมลนี้ถูกใช้งานแล้ว';
        _isLoading = false;
      });
    } else {
      _showError(_parseErrorMessage(msg));
      setState(() => _isLoading = false);
    }
  }

  String _parseErrorMessage(String error) {
    if (error.contains('weak_password')) {
      return 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
    }
    if (error.contains('invalid_email')) {
      return 'รูปแบบอีเมลไม่ถูกต้อง';
    }
    return 'เกิดข้อผิดพลาด: $error';
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
  }

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate progress (0.0 to 1.0)
    final progress = (_currentStep + 1) / _maxSteps;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ลงทะเบียน'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.r),
              child: Column(
                children: [
                  // Progress Bar
                  _buildProgressIndicator(progress, colorScheme),
                  SizedBox(height: 32.h),

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      padding: EdgeInsets.all(12.r),
                      margin: EdgeInsets.only(bottom: 16.h),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(
                            16.r), // Standard 16.r for alerts
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          SizedBox(width: 12.w),
                          Expanded(
                              child: Text(_errorMessage!,
                                  style:
                                      TextStyle(color: Colors.red.shade700))),
                        ],
                      ),
                    ),

                  // Content
                  if (_currentStep == 0)
                    RoleSelectionStep(
                        selectedRole: _selectedRole,
                        onRoleSelected: (role) =>
                            setState(() => _selectedRole = role)),
                  if (_currentStep == 1) _buildAuthProfileStep(theme),
                  if (_currentStep == 2 && _selectedRole == 'FARMER')
                    _buildFarmStep(theme),
                  // Success Step: If Farmer (Step 3), If Buyer (Step 2)
                  if ((_selectedRole == 'FARMER' && _currentStep == 3) ||
                      (_selectedRole == 'BUYER' && _currentStep == 2))
                    _buildSuccessStep(theme, colorScheme),
                ],
              ),
            ),
          ),
          // Fixed Bottom Buttons
          if (!((_selectedRole == 'FARMER' && _currentStep == 3) ||
              (_selectedRole == 'BUYER' && _currentStep == 2)))
            Container(
              padding: EdgeInsets.fromLTRB(
                  16.r, 16.r, 16.r, 32.h), // Added extra bottom padding
              color: theme.scaffoldBackgroundColor,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_currentStep == 0) {
                                // Step 0: Go back to Login
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/login');
                                }
                              } else {
                                // Other steps: Go back one step
                                setState(() => _currentStep--);
                              }
                            },
                      child: const Text('ย้อนกลับ'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleStepContinue,
                      child: _isLoading
                          ? SizedBox(
                              width: 20.r,
                              height: 20.r,
                              child: const CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(_getNextButtonLabel()),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getNextButtonLabel() {
    if (_currentStep == 0) return 'ถัดไป';
    if (_selectedRole == 'BUYER' && _currentStep == 1) return 'สร้างบัญชี';
    if (_selectedRole == 'FARMER' && _currentStep == 2) return 'เสร็จสิ้น';
    return 'ถัดไป';
  }

  Widget _buildProgressIndicator(double progress, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ขั้นตอน ${_currentStep + 1} จาก $_maxSteps',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12.sp),
        ),
        SizedBox(height: 8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8.h,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthProfileStep(ThemeData theme) {
    return Form(
      key: _authFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ข้อมูลส่วนตัว',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          Text('กรอกข้อมูลเพื่อสร้างบัญชีใหม่',
              style: TextStyle(color: Colors.grey.shade600)),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: StyledTextField(
                  controller: _firstNameController,
                  label: 'ชื่อ',
                  hintText: 'กรอกชื่อจริง',
                  icon: Icons.person,
                  isRequired: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z\u0E00-\u0E7F ]'))
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: StyledTextField(
                  controller: _lastNameController,
                  label: 'นามสกุล',
                  hintText: 'กรอกนามสกุล',
                  icon: Icons.person_outline,
                  isRequired: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z\u0E00-\u0E7F ]'))
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          StyledTextField(
            controller: _phoneController,
            label: 'เบอร์โทรศัพท์',
            hintText: '0812345678',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            isRequired: true,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          SizedBox(height: 16.h),
          StyledTextField(
            controller: _emailController,
            label: 'อีเมล',
            hintText: 'example@email.com',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            isRequired: true,
            errorText: _emailError,
            customValidator: (v) =>
                !v!.contains('@') ? 'กรุณากรอกอีเมลให้ถูกต้อง' : null,
          ),
          SizedBox(height: 16.h),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'รหัสผ่าน',
              hintText: 'อย่างน้อย 6 ตัวอักษร',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                v!.length < 6 ? 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFarmStep(ThemeData theme) {
    return Form(
      key: _farmFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ข้อมูลฟาร์ม',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 8.h),
          Text('กรุณากรอกข้อมูลฟาร์มของคุณ',
              style: TextStyle(color: Colors.grey.shade600)),
          SizedBox(height: 24.h),

          StyledTextField(
            controller: _farmNameController,
            label: 'ชื่อฟาร์ม',
            icon: Icons.agriculture,
            isRequired: true,
          ),
          SizedBox(height: 16.h),

          // Simplified Address Field
          StyledTextField(
            controller: _addressDetailsController,
            label: 'รายละเอียดที่อยู่',
            hintText: 'บ้านเลขที่, หมู่, ถนน, ซอย',
            icon: Icons.home,
            maxLines: 2,
            isRequired: true,
          ),
          SizedBox(height: 16.h),

          // Thai Address Picker
          ThaiAddressPicker(
            onAddressChanged: (province, district, tambon) {
              setState(() {
                _provinceController.text = province?.nameTh ?? '';
                _districtController.text = district?.nameTh ?? '';
                _subDistrictController.text = tambon?.nameTh ?? '';
                _postalCodeController.text = tambon?.zipCode.toString() ?? '';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
                color: Colors.green.shade50, shape: BoxShape.circle),
            child: Icon(Icons.check_circle, size: 64.r, color: Colors.green),
          ),
          SizedBox(height: 24.h),
          Text('ลงทะเบียนสำเร็จ!',
              style: theme.textTheme.headlineMedium
                  ?.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
          SizedBox(height: 16.h),
          Text(
            'ยินดีต้อนรับสู่ระบบ Cow Passport\nเริ่มต้นใช้งานได้ทันที',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade700),
          ),
          SizedBox(height: 32.h),
          ElevatedButton(
            onPressed: () => context.go('/'),
            style: ElevatedButton.styleFrom(minimumSize: Size(200.w, 48.h)),
            child: const Text('เข้าสู่หน้าหลัก'),
          ),
        ],
      ),
    );
  }
}
