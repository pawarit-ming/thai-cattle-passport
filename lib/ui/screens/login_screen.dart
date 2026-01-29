import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:th_cow_passport/supabase_config.dart'; // import ให้ตรงกับโปรเจกต์

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // เมื่อ Login สำเร็จ Router จะ Redirect เองอัตโนมัติ (ตั้งค่าในข้อ 2)
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('เกิดข้อผิดพลาดที่ไม่คาดคิด'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.pets,
                  size: 80.w, color: Theme.of(context).primaryColor),
              SizedBox(height: 20.h),
              Text(
                'เข้าสู่ระบบ CowD',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 40.h),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'อีเมล',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'รหัสผ่าน',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text('เข้าสู่ระบบ', style: TextStyle(fontSize: 16.sp)),
              ),
              SizedBox(height: 16.h),
              TextButton(
                onPressed: () {
                  // TODO: เพิ่มหน้าสมัครสมาชิก (Register) หรือลืมรหัสผ่าน
                },
                child: const Text('ยังไม่มีบัญชี? สมัครสมาชิก'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
