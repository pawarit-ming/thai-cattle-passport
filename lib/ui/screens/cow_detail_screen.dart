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
import 'dart:typed_data';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

class CowDetailScreen extends ConsumerStatefulWidget {
  final int cowId;
  final bool isReadOnly;
  final bool hideBackButton; // ✅ 1. เพิ่มตัวแปรนี้เพื่อคุมการแสดงปุ่มถอยกลับ

  const CowDetailScreen({
    super.key,
    required this.cowId,
    this.isReadOnly = false,
    this.hideBackButton = false, // ✅ 2. ค่า Default เป็น false (แสดงปุ่มตามปกติ)
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
      setState(() {});
    });
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

      // ✅ 3. ปรับ Logic ตรงนี้: ถ้า hideBackButton เป็น true ให้ส่ง null (เพื่อซ่อนปุ่ม)
      // (หมายเหตุ: CowDetailWidget ต้องรองรับค่า null ใน onBack เพื่อซ่อนปุ่ม Leading)
      onBack: widget.hideBackButton
          ? null
          : () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/');
              }
            },

      actions: [
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
        GeneralTab(isReadOnly: widget.isReadOnly),
        ActivityTab(cowId: widget.cowId),
      ],
      bottomBar: widget.isReadOnly
          ? null
          : _buildBottomBar(
              context, colorScheme, theme, cow.animalId!, cow.animalId!),
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

  // ... (ส่วนอื่นๆ ของไฟล์เหมือนเดิม ไม่มีการเปลี่ยนแปลง)

  void _showScanInstructionDialog(BuildContext context) {
    // ... โค้ดเดิม ...
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

    // ✅ 1. สร้าง ScreenshotController
    final screenshotController = ScreenshotController();

    const String baseUrl = 'https://th-cow-passport-web.web.app/#/cow-detail';
    final String qrData = '$baseUrl/$cowId';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cow ID: $cowId',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary, // ใช้สีน้ำตาลตามธีมหลัก
                ),
              ),
              SizedBox(height: 16.h), // เพิ่มระยะห่างก่อนถึงตัว QR Code

              Screenshot(
                controller: screenshotController,
                child: Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: Colors
                        .white, // ✅ สำคัญ: ต้องใส่สีพื้นหลัง ไม่งั้นรูปจะโปร่งใส
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
              ),
              SizedBox(height: 16.h),
              Text('สแกนเพื่อดูข้อมูลวัว',
                  style: TextStyle(color: theme.hintColor)),
            ],
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(
                left: 8.w,
                right: 8.w,
                bottom: 8.h,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'ปิด',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        try {
                          // 1. สั่งจับภาพจาก Screenshot Widget
                          final Uint8List? image =
                              await screenshotController.capture();

                          if (image != null) {
                            // 2. บันทึกลงแกลเลอรีเครื่อง
                            await ImageGallerySaverPlus.saveImage(
                              image,
                              name: "QR_COW_$cowId",
                              quality: 100,
                            );

                            if (mounted) {
                              Navigator.pop(
                                  context); // ปิด Dialog หลังบันทึกสำเร็จ
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'บันทึกรูป QR Code ลงแกลเลอรีเรียบร้อยแล้ว'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          debugPrint("Error saving QR: $e");
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('เกิดข้อผิดพลาดในการบันทึก: $e')),
                            );
                          }
                        }
                      },
                      icon: Icon(Icons.save_alt, size: 20.r),
                      label: const Text('บันทึก'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}