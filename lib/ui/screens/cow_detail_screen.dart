import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:th_cow_passport/services/cow_management/cow_detail/cow_detail_service.dart';
import 'package:th_cow_passport/services/cow_management/cow_activity/activity_service.dart';
import 'package:th_cow_passport/ui/screens/camera_screen.dart';

import 'package:th_cow_passport/ui/screens/cow_detail/tabs/activity/activity_tab.dart';
import 'package:th_cow_passport/ui/screens/cow_detail/tabs/general/general_tab.dart';

import 'package:th_cow_passport/ui/widgets/cow_detail_widget.dart';

class CowDetailScreen extends ConsumerStatefulWidget {
  final int cowId;
  final bool isReadOnly;

  const CowDetailScreen({
    super.key,
    required this.cowId,
    // 2. กำหนดค่าเริ่มต้นเป็น false (เพื่อให้หน้าอื่นๆ ยังแก้ไขได้ปกติ)
    this.isReadOnly = false,
  });

  @override
  ConsumerState<CowDetailScreen> createState() => _CowDetailScreenState();
}

class _CowDetailScreenState extends ConsumerState<CowDetailScreen>
    with SingleTickerProviderStateMixin {
  final logger = Logger();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        logger.d('Tab changed to index: ${_tabController.index}');
      }
      setState(() {}); // รีเฟรช UI เมื่อ Tab เปลี่ยน
    });
    // ดึงข้อมูลเมื่อเข้าหน้าจอ
    logger.i('Fetching details for cow ID: ${widget.cowId}');
    Future.microtask(
        () => ref.read(cowDetailServiceProvider).fetchCowById(widget.cowId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final detailState = ref.watch(cowDetailServiceProvider);
    final cow = detailState.currentCow;

    if (detailState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (cow == null) {
      // Auto-refetch if data is missing (e.g., after invalidation)
      if (!detailState.isLoading) {
        Future.microtask(() =>
            ref.read(cowDetailServiceProvider).fetchCowById(widget.cowId));
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return const Scaffold(body: Center(child: Text("ไม่พบข้อมูลวัว")));
    }

    return CowDetailWidget(
      title: 'ข้อมูลประจำตัววัว',
      images: [
        if (cow.facePic != null) ...cow.facePic!,
        if (cow.bodyPic != null) ...cow.bodyPic!,
      ],
      tabController: _tabController,

      // ถ้าเป็น isReadOnly (ดูผ่านเว็บ) ให้ส่งค่า null เพื่อซ่อนปุ่ม
      // ถ้าไม่ใช่ (ดูผ่านแอป) ให้ส่งฟังก์ชันถอยหลังตามปกติ
      onBack: widget.isReadOnly
          ? null
          : () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
      actions: [
        // เพิ่มเงื่อนไขเช็คตรงนี้
        if (!widget.isReadOnly)
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            tooltip: 'แสดง QR Code',
            onPressed: () => _showQrDialog(context, cow.animalId.toString()),
          ),
      ],
      tabs: const [
        Tab(text: 'ข้อมูลทั่วไป'),
        Tab(text: 'กิจกรรม'),
      ],
      tabViews: [
        // แก้ไข: ส่งค่า isReadOnly เข้าไป
        GeneralTab(isReadOnly: widget.isReadOnly),
        ActivityTab(cowId: cow.animalId!),
      ],
      bottomBar: widget.isReadOnly
          ? null
          : _buildBottomBar(
              context, colorScheme, theme, cow.animalId!, cow.animalId!),

      // --- แก้ไขจุดนี้: ถ้าเป็น ReadOnly ให้ส่ง null ---
      floatingActionButton: widget.isReadOnly
          ? null
          : FloatingActionButton(
              onPressed: () => _showScanInstructionDialog(context),
              backgroundColor: colorScheme.secondary,
              foregroundColor: colorScheme.onSecondary,
              child: const Icon(Icons.camera_alt),
            ),
    );
  }

  void _showScanInstructionDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon header
                Container(
                  width: 56.r,
                  height: 56.r,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt_rounded,
                      color: theme.primaryColor, size: 28.r),
                ),
                SizedBox(height: 16.h),
                Text(
                  'ถ่ายภาพระบุตัวตน',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'ถ่ายภาพตามลำดับเพื่อระบุตัวตนวัว',
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey[500]),
                ),
                SizedBox(height: 24.h),

                // Steps
                _buildInstructionStep(
                  context,
                  1,
                  'หน้าวัว',
                  'ถ่ายหน้าตรงให้เห็นชัดเจน',
                  'assets/images/cow_face.png',
                ),
                SizedBox(height: 12.h),
                _buildInstructionStep(
                  context,
                  2,
                  'ตัววัว',
                  'ถ่ายด้านข้างให้เห็นลาย/สี',
                  'assets/images/cow.png',
                ),

                SizedBox(height: 28.h),

                // Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CameraScreen(
                            baseTitle: 'ระบุตัวตนวัว',
                            steps: ['หน้าวัว', 'ตัววัว'],
                            stepIcons: [
                              'assets/images/cow_face.png',
                              'assets/images/cow.png',
                            ],
                          ),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r)),
                    ),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: Text('เริ่มถ่ายภาพ',
                        style: TextStyle(
                            fontSize: 15.sp, fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(height: 8.h),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('ยกเลิก',
                      style:
                          TextStyle(color: Colors.grey[400], fontSize: 13.sp)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstructionStep(BuildContext context, int number, String title,
      String subtitle, String assetPath) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Step number badge
          Container(
            width: 24.r,
            height: 24.r,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // Icon
          Image.asset(assetPath,
              width: 36.r,
              height: 36.r,
              color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 12.w),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ColorScheme colorScheme,
      ThemeData theme, int animalId, int cowId) {
    final isActivityTab = _tabController.index == 1;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 10.r,
            offset: Offset(0, -4.h),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: ElevatedButton.icon(
            onPressed: () async {
// ... (context handled by tool)
              if (isActivityTab) {
                context.push('/add-activity/$cowId');
              } else {
                // Navigate to edit screen and wait for result
                final didEdit =
                    await context.push<bool>('/edit-form/$animalId');
                // If edit was successful, refresh activities
                if (didEdit == true) {
                  ref.invalidate(activitiesProvider(cowId));
                }
              }
            },
            icon: Icon(isActivityTab ? Icons.add : Icons.edit),
            label: Text(
              isActivityTab ? 'เพิ่มกิจกรรม' : 'แก้ไขข้อมูล',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r)),
            ),
          ),
        ),
      ),
    );
  }

  void _showQrDialog(BuildContext context, String cowId) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    const String baseUrl = 'https://th-cow-passport-web.web.app/#/cow-detail';

    final String qrData = '$baseUrl/$cowId';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          title: Center(
              child: Text('Cow ID: $cowId',
                  style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                      color: theme.scaffoldBackgroundColor, width: 2.w),
                ),
                child: SizedBox(
                  width: 200.w,
                  height: 200.h,
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 200.r,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text('สแกนเพื่อดูข้อมูลวัว',
                  style: TextStyle(color: theme.hintColor)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              child: const Text('ปิด'),
            ),
            SizedBox(width: 8.w),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r)),
              ),
              icon: const Icon(Icons.save_alt),
              label: const Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }
}
