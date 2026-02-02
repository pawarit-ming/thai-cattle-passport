import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:th_cow_passport/services/auth/auth_service.dart';
import 'package:th_cow_passport/services/farm/farm_service.dart';

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
  // Step 1: Auth
  final _authFormKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _citizenIdController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _emailError;

  // Step 3: Farm
  final _farmFormKey = GlobalKey<FormState>();
  late TextEditingController _farmNameController;
  late TextEditingController _provinceController;
  late TextEditingController _addressController;
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
    _citizenIdController = TextEditingController();
    _emailController = TextEditingController();
    _emailError = null;
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _farmNameController = TextEditingController();
    _provinceController = TextEditingController();
    _addressController = TextEditingController();
    _districtController = TextEditingController();
    _subDistrictController = TextEditingController();
    _postalCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _citizenIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _farmNameController.dispose();
    _provinceController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _subDistrictController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleStepContinue() async {
    logger.i('[RegisterScreen] Current step: $_currentStep');

    if (_currentStep == 0) {
      // Step 1: Collect and validate auth + profile data, then sign up
      // Clear previous field-level errors when retrying
      if (mounted) {
        setState(() {
          _emailError = null;
          _errorMessage = null;
        });
      } else {
        _emailError = null;
        _errorMessage = null;
      }

      // Validate auth form
      if (!_authFormKey.currentState!.validate()) {
        logger.w('[RegisterScreen] Auth form validation failed');
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        _showError('รหัสผ่านไม่ตรงกัน');
        return;
      }

      setState(() => _isLoading = true);
      try {
        _authEmail = _emailController.text.trim();
        _authPassword = _passwordController.text;
        final firstName = _firstNameController.text.trim();
        final lastName = _lastNameController.text.trim();
        final citizenId = _citizenIdController.text.trim();

        logger.i('[RegisterScreen] Signing up: $_authEmail, name: $firstName $lastName, citizenId: $citizenId');
        final authService = AuthService();
        final response = await authService.signUp(
          email: _authEmail,
          password: _authPassword,
          firstName: firstName,
          lastName: lastName,
          citizenId: citizenId,
        );

        logger.i('[RegisterScreen] [SUCCESS] Auth user created: ${response.user!.id}');

        if (mounted) {
          setState(() {
            _currentStep = 1;  // Move to farm step (profile is now done)
            _errorMessage = null;
            _isLoading = false;
          });
        }
      } catch (e) {
        final parsed = _parseErrorMessage(e.toString());
        // If duplicate email, show inline error under email field instead of big banner
        if (parsed.contains('ลงทะเบียนแล้ว')) {
          if (mounted) {
            setState(() {
              _emailError = parsed;
              _errorMessage = null;
              _isLoading = false;
            });
          } else {
            _emailError = parsed;
            _errorMessage = null;
          }
        } else {
          _showError(parsed);
          if (mounted) setState(() => _isLoading = false);
        }
      }
    } else if (_currentStep == 1) {
      // Step 2: Create farm
      // Step 3: Validate farm form
      if (!_farmFormKey.currentState!.validate()) {
        logger.w('[RegisterScreen] Farm form validation failed');
        return;
      }

      setState(() => _isLoading = true);
      try {
        final farmService = FarmService();
        final farmName = _farmNameController.text.trim();

        logger.i('[RegisterScreen] Creating farm: $farmName');
        // Farm service will use the current authenticated user's id
        await farmService.createFarm(
          farmName: farmName,
          province: _provinceController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
          subDistrict: _subDistrictController.text.trim().isEmpty ? null : _subDistrictController.text.trim(),
          postalCode: _postalCodeController.text.trim().isEmpty ? null : _postalCodeController.text.trim(),
        );

        logger.i('[RegisterScreen] [SUCCESS] Farm created');

        if (mounted) {
          setState(() {
            _currentStep = 2;
            _errorMessage = null;
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลงทะเบียนสำเร็จ! ยินดีต้อนรับ'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to home after successful registration
          context.go('/');
        }
      } catch (e) {
        _showError(_parseErrorMessage(e.toString()));
        if (mounted) setState(() => _isLoading = false);
      }
    } else if (_currentStep == 2) {
      // Success - navigate to home
      logger.i('[RegisterScreen] [SUCCESS] Registration completed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ลงทะเบียนสำเร็จ! ยินดีต้อนรับ'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/');
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() => _errorMessage = message);
    }
    logger.e('[RegisterScreen] Error: $message');
  }

  String _parseErrorMessage(String error) {
    if (error.contains('weak_password')) {
      return 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
    }
    if (error.contains('user_already_exists')) {
      logger.w('[RegisterScreen] Duplicate email detected during registration');
      return 'อีเมลนี้ได้ลงทะเบียนแล้ว กรุณาเข้าสู่ระบบหรือใช้อีเมลอื่น';
    }
    if (error.contains('invalid_email')) {
      return 'รูปแบบอีเมลไม่ถูกต้อง';
    }
    if (error.contains('row-level security') || error.contains('42501')) {
      return 'ข้อผิดพลาด: ไม่สามารถบันทึกข้อมูลได้ (ติดต่อผู้ดูแลระบบ)';
    }
    return 'เกิดข้อผิดพลาด: $error';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ลงทะเบียน'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(colorScheme),
            SizedBox(height: 32.h),

            // Error message
            if (_errorMessage != null)
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600, size: 20.r),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_errorMessage != null) SizedBox(height: 16.h),

            // Step content
            if (_currentStep == 0) _buildAuthProfileStep(theme),
            if (_currentStep == 1) _buildFarmStep(theme),
            if (_currentStep == 2) _buildSuccessStep(theme, colorScheme),

            SizedBox(height: 32.h),

            // Navigation buttons
            if (_currentStep < 2)
              Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => setState(() => _currentStep--),
                        child: const Text('ย้อนกลับ'),
                      ),
                    ),
                  if (_currentStep > 0) SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleStepContinue,
                      child: _isLoading
                          ? SizedBox(
                              height: 20.r,
                              width: 20.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(_currentStep == 1 ? 'สร้างบัญชี' : 'ถัดไป'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ขั้นตอน ${_currentStep + 1} จาก 3',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        SizedBox(height: 8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            minHeight: 8.h,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation(colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthProfileStep(ThemeData theme) {
    // Combined auth + profile step (since trigger handles DB insert)
    return Form(
      key: _authFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Title =====
          Text(
            'สร้างบัญชี',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            'กรุณากรอกข้อมูลส่วนตัวและสร้างบัญชี',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          SizedBox(height: 24.h),
          
          // 1. First Name & Last Name (Side by Side)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อจริง',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'กรุณากรอก';
                    return null;
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'นามสกุล',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'กรุณากรอก';
                    return null;
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          // 2. Citizen ID
          TextFormField(
            controller: _citizenIdController,
            decoration: const InputDecoration(
              labelText: 'เลขที่บัตรประชาชน',
              hintText: 'เลขที่บัตรประชาชน',
              prefixIcon: Icon(Icons.credit_card),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'กรุณากรอกเลขที่บัตรประชาชน';
              return null;
            },
          ),
          SizedBox(height: 16.h),
          
          // 3. Email
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'อีเมล',
              hintText: 'example@email.com',
              prefixIcon: const Icon(Icons.email_outlined),
              errorText: _emailError,
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (v) {
              if (_emailError != null || _errorMessage != null) {
                setState(() {
                  _emailError = null;
                  _errorMessage = null;
                });
              }
            },
            validator: (value) {
              if (value?.isEmpty ?? true) return 'กรุณากรอกอีเมล';
              if (!value!.contains('@')) return 'อีเมลไม่ถูกต้อง';
              return null;
            },
          ),
          SizedBox(height: 16.h),
          
          // 4. Password
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'รหัสผ่าน',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            obscureText: _obscurePassword,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'กรุณากรอกรหัสผ่าน';
              if ((value?.length ?? 0) < 6) return 'รหัสผ่านต้องมี 6 ตัวอักษรขึ้นไป';
              return null;
            },
          ),
          SizedBox(height: 16.h),
          
          // 5. Confirm Password
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'รหัสยืนยัน',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            obscureText: _obscureConfirmPassword,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'กรุณายืนยันรหัสผ่าน';
              return null;
            },
          ),
          SizedBox(height: 16.h),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('มีบัญชีแล้ว?'),
              SizedBox(width: 4.w),
              GestureDetector(
                onTap: () => context.go('/login'),
                child: Text(
                  'เข้าสู่ระบบ',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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
          Text(
            'ข้อมูลฟาร์ม',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            'กรุณากรอกข้อมูลฟาร์มของคุณ',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          SizedBox(height: 24.h),
          TextFormField(
            controller: _farmNameController,
            decoration: const InputDecoration(
              labelText: 'ชื่อฟาร์ม',
              prefixIcon: Icon(Icons.agriculture),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'กรุณากรอกชื่อฟาร์ม';
              return null;
            },
          ),
          SizedBox(height: 16.h),
          TextFormField(
            controller: _provinceController,
            decoration: const InputDecoration(
              labelText: 'จังหวัด',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'กรุณากรอกจังหวัด';
              return null;
            },
          ),
          SizedBox(height: 16.h),
          TextFormField(
            controller: _districtController,
            decoration: const InputDecoration(
              labelText: 'อำเภอ (ไม่บังคับ)',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          SizedBox(height: 16.h),
          TextFormField(
            controller: _subDistrictController,
            decoration: const InputDecoration(
              labelText: 'ตำบล (ไม่บังคับ)',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          SizedBox(height: 16.h),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'ที่อยู่ (ไม่บังคับ)',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            maxLines: 2,
          ),
          SizedBox(height: 16.h),
          TextFormField(
            controller: _postalCodeController,
            decoration: const InputDecoration(
              labelText: 'รหัสไปรษณีย์ (ไม่บังคับ)',
              prefixIcon: Icon(Icons.mail_outlined),
            ),
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
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 64.r,
              color: Colors.green.shade600,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'ลงทะเบียนสำเร็จ!',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade600,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'ยินดีต้อนรับสู่ Cow Passport',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'กำลังไปยังหน้าแรก...',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}