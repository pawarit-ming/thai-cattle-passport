import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logger/logger.dart';
import 'package:th_cow_passport/services/auth/auth_provider.dart';
import 'package:th_cow_passport/services/auth/auth_service.dart';
import 'package:th_cow_passport/supabase_config.dart';

final logger = Logger();

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // ดึงข้อมูลผู้ใช้จาก database
    final userAsync = ref.watch(currentUserProvider);

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
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Text('ไม่พบข้อมูลผู้ใช้',
                  style: theme.textTheme.bodyLarge),
            );
          }

          final fullName = '${user.firstName} ${user.lastName}'.trim();
          final email = supabase.auth.currentUser?.email ?? 'ไม่ระบุอีเมล';

          logger.i('[ProfileScreen] Loaded user: $fullName, Role: ${user.role}');

          return SingleChildScrollView(
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
                              border: Border.all(
                                  color: colorScheme.primary, width: 3.w),
                            ),
                            child: CircleAvatar(
                              radius: 50.r,
                              backgroundColor: Colors.grey.shade200,
                              child: Text(
                                fullName.isNotEmpty
                                    ? fullName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 32.sp,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
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
                                border: Border.all(
                                    color: Colors.white, width: 2.w),
                              ),
                              child: Icon(Icons.edit,
                                  color: Colors.white, size: 16.r),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        fullName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color:
                              colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          user.role.name,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),

                // แสดงข้อมูลเพิ่มเติม
                if (user.title != null)
                  _buildInfoTile(context, 'ตำแหน่ง', user.title!),
                if (user.mobilePhone != null)
                  _buildInfoTile(context, 'เบอร์โทรศัพท์', user.mobilePhone!),
                if (user.address != null)
                  _buildInfoTile(context, 'ที่อยู่', user.address!),
                if (user.province != null)
                  _buildInfoTile(context, 'จังหวัด', user.province!),
                if (user.birthDate != null)
                  _buildInfoTile(context, 'วันเกิด',
                      user.birthDate.toString().split(' ')[0]),

                SizedBox(height: 32.h),

                // เมนูตัวเลือก
                _buildProfileMenu(context,
                    icon: Icons.person_outline,
                    text: 'แก้ไขข้อมูลส่วนตัว'),
                _buildProfileMenu(context,
                    icon: Icons.location_on_outlined,
                    text: 'ที่อยู่ฟาร์ม'),
                _buildProfileMenu(context,
                    icon: Icons.history, text: 'ประวัติการซื้อขาย'),
                _buildProfileMenu(context,
                    icon: Icons.notifications_outlined,
                    text: 'การแจ้งเตือน'),

                _buildProfileMenu(context,
                    icon: Icons.logout,
                    text: 'ออกจากระบบ',
                    textColor: colorScheme.error,
                    iconColor: colorScheme.error,
                    onTap: () async {
                  logger.i('[ProfileScreen] User initiating sign out');
                  try {
                    final authService = AuthService();
                    await authService.signOut();
                    logger.i('[ProfileScreen] [SUCCESS] Sign out completed');
                  } catch (e) {
                    logger.e('[ProfileScreen] [ERROR] Sign out failed', error: e);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('ไม่สามารถออกจากระบบได้: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }),
                SizedBox(height: 32.h),
              ],
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
        error: (error, stackTrace) {
          logger.e('[ProfileScreen] Error loading user data',
              error: error, stackTrace: stackTrace);
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 48.r, color: colorScheme.error),
                  SizedBox(height: 16.h),
                  Text('เกิดข้อผิดพลาดในการโหลดข้อมูล',
                      style: theme.textTheme.bodyLarge),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () => ref.refresh(currentUserProvider),
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
          color: (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.1),
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
      trailing: Icon(Icons.arrow_forward_ios,
          size: 16.r, color: Colors.grey.shade400),
      onTap: onTap ?? () {},
    );
  }
}
