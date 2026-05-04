import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:th_cow_passport/routes/app_router.dart';
import 'package:th_cow_passport/services/auth/auth_provider.dart';

class UpdatePasswordScreen extends ConsumerStatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  ConsumerState<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends ConsumerState<UpdatePasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  Future<void> _updatePassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.length < 6) {
      setState(() => _errorMessage = 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _errorMessage = 'รหัสผ่านไม่ตรงกัน');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // เรียกใช้ Provider สำหรับอัปเดตรหัสผ่านใหม่
      await ref.read(updatePasswordProvider(password).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เปลี่ยนรหัสผ่านสำเร็จ!')),
        );

        // คืนค่าเป็น false เพื่อให้ Router เลิกบังคับไปหน้าตั้งรหัสผ่าน
        isRecoveringPassword = false;
        
        // เปลี่ยนรหัสผ่านเสร็จแล้ว พากลับไปหน้า Home
        context.go('/'); 
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการเปลี่ยนรหัสผ่าน กรุณาลองใหม่อีกครั้ง';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งรหัสผ่านใหม่'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.lock_reset, size: 80.r, color: Theme.of(context).colorScheme.primary),
                SizedBox(height: 24.h),
                Text(
                  'กรุณาตั้งรหัสผ่านใหม่ของคุณ',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 32.h),
                
                if (_errorMessage != null) ...[
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],

                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'รหัสผ่านใหม่',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'ยืนยันรหัสผ่านใหม่',
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  obscureText: _obscurePassword,
                ),
                SizedBox(height: 32.h),
                ElevatedButton(
                  onPressed: _isLoading ? null : _updatePassword,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20.h,
                          width: 20.h,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('บันทึกรหัสผ่านใหม่', style: TextStyle(fontSize: 16.sp)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}