import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('บัญชีผู้ใช้'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 32.h),
            // ส่วนหัว: รูปโปรไฟล์และชื่อ
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: colorScheme.primary, width: 3.w),
                        ),
                        child: CircleAvatar(
                          radius: 50.r,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: const NetworkImage(
                              'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200'),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.w),
                          ),
                          child: Icon(Icons.edit,
                              color: Colors.white, size: 16.r),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'สมชาย ใจดี',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'ฟาร์มโชคชัย • 081-234-5678',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),

            // เมนูตัวเลือก
            _buildProfileMenu(context,
                icon: Icons.person_outline, text: 'แก้ไขข้อมูลส่วนตัว'),
            _buildProfileMenu(context,
                icon: Icons.location_on_outlined, text: 'ที่อยู่ฟาร์ม'),
            _buildProfileMenu(context,
                icon: Icons.history, text: 'ประวัติการซื้อขาย'),
            _buildProfileMenu(context,
                icon: Icons.notifications_outlined, text: 'การแจ้งเตือน'),
            _buildProfileMenu(context,
                icon: Icons.logout,
                text: 'ออกจากระบบ',
                textColor: colorScheme.error,
                iconColor: colorScheme.error, onTap: () {
              // Handle logout
            }),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenu(
    BuildContext context, {
    required IconData icon,
    required String text,
    VoidCallback? onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 4.h),
      leading: Container(
        width: 40.r,
        height: 40.r,
        decoration: BoxDecoration(
          color: (iconColor ?? theme.colorScheme.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, color: iconColor ?? theme.colorScheme.primary),
      ),
      title: Text(
        text,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: textColor ?? theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing:
          Icon(Icons.arrow_forward_ios, size: 16.r, color: Colors.grey.shade400),
      onTap: onTap ?? () {},
    );
  }
}
