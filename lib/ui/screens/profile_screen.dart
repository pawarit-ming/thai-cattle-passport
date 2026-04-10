import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:th_cow_passport/services/auth/auth_provider.dart';
import 'package:th_cow_passport/services/auth/auth_service.dart';
import 'package:th_cow_passport/services/profile/models/user_model.dart';
import 'package:th_cow_passport/services/profile/services/dld_verification_service.dart';
import 'package:th_cow_passport/supabase_config.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

final logger = Logger();

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _showVerificationDialog(
      BuildContext context, WidgetRef ref, User user) async {
    final theme = Theme.of(context);
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isLoading = false;
        bool isSuccess = false;
        return StatefulBuilder(
          builder: (stContext, setState) {
            if (isSuccess) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.r)),
                contentPadding: EdgeInsets.all(24.r),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle_outline,
                          color: Colors.green.shade600, size: 64.r),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'ยินดีด้วย!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'คุณได้รับการยืนยันการเป็นเกษตรกร\nกับกรมปศุสัตว์เรียบร้อยแล้ว',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          // ignore: discarded_futures
                          ref.refresh(currentUserProvider.future);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                        ),
                        child: Text(
                          'ตกลง',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.r)),
              title: Text(
                'ยืนยันตัวตนเกษตรกร',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'กรุณากรอกเลขบัตรประชาชน 13 หลัก เพื่อตรวจสอบสถานะเกษตรกรกับกรมปศุสัตว์ (DLD)',
                      style: theme.textTheme.bodyMedium,
                    ),
                    SizedBox(height: 20.h),
                    TextFormField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 13,
                      enabled: !isLoading,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'เลขบัตรประชาชน',
                        labelStyle: theme.textTheme.bodyMedium,
                        hintText: 'X-XXXX-XXXXX-XX-X',
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกเลขบัตรประชาชน';
                        }
                        if (value.length != 13) {
                          return 'กรุณากรอกให้ครบ 13 หลัก';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isLoading ? null : () => Navigator.pop(dialogContext),
                  child: Text(
                    'ยกเลิก',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isLoading ? Colors.grey.shade400 : Colors.grey,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            final citizenId = controller.text.trim();
                            setState(() {
                              isLoading = true;
                            });

                            try {
                              final service = DldVerificationService();
                              final success = await service.verifyFarmer(
                                  citizenId, user.id);

                              if (dialogContext.mounted) {
                                if (success) {
                                  setState(() {
                                    isLoading = false;
                                    isSuccess = true;
                                  });
                                } else {
                                  Navigator.pop(dialogContext); // ปิด dialog
                                  if (context.mounted) {
                                    _showFailedRegistrationDialog(
                                        context, theme);
                                  }
                                }
                              }
                            } catch (e) {
                              if (dialogContext.mounted) {
                                setState(() {
                                  isLoading = false;
                                });
                                final errorMessage = e is String ? e : 'เกิดข้อผิดพลาด: $e';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(errorMessage),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 20.h,
                          height: 20.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'ตรวจสอบข้อมูล',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFailedRegistrationDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.primary),
            SizedBox(width: 8.w),
            Text(
              'ไม่พบข้อมูลเกษตรกร',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'ไม่พบเลขบัตรประชาชนนี้ในระบบ DLD ต้องการลงทะเบียนเกษตรกรผู้เลี้ยงสัตว์ใหม่หรือไม่?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ภายหลัง',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final Uri url =
                  Uri.parse('https://eregist.dld.go.th/eregist-portal/');
              await launchUrl(url, mode: LaunchMode.externalApplication);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r),
              ),
            ),
            child: Text(
              'ไปหน้าลงทะเบียน',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
              child:
                  Text('ไม่พบข้อมูลผู้ใช้', style: theme.textTheme.bodyLarge),
            );
          }

          final fullName = '${user.firstName} ${user.lastName}'.trim();
          final email = supabase.auth.currentUser?.email ?? 'ไม่ระบุอีเมล';

          logger
              .i('[ProfileScreen] Loaded user: $fullName, Role: ${user.role}');

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
                                style: GoogleFonts.prompt(
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
                                border:
                                    Border.all(color: Colors.white, width: 2.w),
                              ),
                              child: Icon(Icons.edit,
                                  color: Colors.white, size: 16.r),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            fullName,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          if (user.isDldVerified)
                            Padding(
                              padding: EdgeInsets.only(left: 8.w),
                              child: Tooltip(
                                message: 'เกษตรกรยืนยันตัวตนกับ DLD แล้ว',
                                child: Icon(
                                  Icons.verified,
                                  color: Colors.blue,
                                  size: 24.r,
                                ),
                              ),
                            ),
                        ],
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
                          color: colorScheme.primaryContainer
                              .withValues(alpha: 0.3),
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

                SizedBox(height: 24.h),

                // Card สำหรับยืนยันตัวตน DLD
                if (!user.isDldVerified && user.role == UserRole.FARMER)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Card(
                      elevation: 0,
                      color: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        side: BorderSide(color: Colors.blue.shade100),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.r),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.blue.shade700),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ยังไม่ได้ยืนยันตัวตนเกษตรกร',
                                        style: GoogleFonts.prompt(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade900,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                      Text(
                                        'ยืนยันข้อมูลกับกรมปศุสัตว์เพื่อรับสัญลักษณ์ยืนยัน',
                                        style: GoogleFonts.prompt(
                                          color: Colors.blue.shade800,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () =>
                                    _showVerificationDialog(context, ref, user),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                ),
                                child: Text(
                                  'ตรวจสอบข้อมูล DLD',
                                  style: GoogleFonts.prompt(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                SizedBox(height: 16.h),

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
                    icon: Icons.person_outline, text: 'แก้ไขข้อมูลส่วนตัว'),
                _buildProfileMenu(context,
                    icon: Icons.location_on_outlined, text: 'ที่อยู่ฟาร์ม'),
                _buildProfileMenu(context,
                    icon: Icons.history, text: 'ประวัติการซื้อขาย'),
                _buildProfileMenu(context,
                    icon: Icons.notifications_outlined,
                    text: 'การแจ้งเตือน',
                    onTap: () => context.push('/notifications')),

                _buildProfileMenu(context,
                    icon: Icons.logout,
                    text: 'ออกจากระบบ',
                    textColor: colorScheme.error,
                    iconColor: colorScheme.error, onTap: () async {
                  final bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('ยืนยันออกจากระบบ?'),
                        content:
                            const Text('คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('ยกเลิก'),
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                          TextButton(
                            child: const Text('ออกจากระบบ',
                                style: TextStyle(color: Colors.red)),
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm != true) return;

                  logger.i('[ProfileScreen] User initiating sign out');
                  try {
                    final authService = AuthService();
                    await authService.signOut();
                    logger.i('[ProfileScreen] [SUCCESS] Sign out completed');
                  } catch (e) {
                    logger.e('[ProfileScreen] [ERROR] Sign out failed',
                        error: e);
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
          color:
              (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.1),
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
