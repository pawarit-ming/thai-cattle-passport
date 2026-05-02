import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:th_cow_passport/services/cow_management/cow_detail/cow_detail_service.dart';
import 'package:th_cow_passport/services/cow_management/cow_activity/activity_service.dart';
import 'package:th_cow_passport/services/cow_management/cow_list/cow_list_service.dart';
import 'package:th_cow_passport/ui/screens/camera_screen.dart';
import 'package:th_cow_passport/ui/screens/cow_detail/tabs/activity/activity_tab.dart';
import 'package:th_cow_passport/ui/screens/cow_detail/tabs/general/general_tab.dart';
import 'package:th_cow_passport/ui/widgets/cow_detail_widget.dart';
import 'dart:typed_data';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:th_cow_passport/ui/widgets/common/app_shimmer.dart';
import 'package:th_cow_passport/core/utils/cow_status_utils.dart';
import 'package:th_cow_passport/services/cow_management/cow_detail/cow_verification_service.dart';
import 'package:th_cow_passport/services/cow_management/models/cow_model.dart';
import 'package:image_picker/image_picker.dart';

class CowDetailScreen extends ConsumerStatefulWidget {
  final int cowId;
  final bool isReadOnly;
  final bool hideBackButton; // ✅ 1. เพิ่มตัวแปรนี้เพื่อคุมการแสดงปุ่มถอยกลับ

  const CowDetailScreen({
    super.key,
    required this.cowId,
    this.isReadOnly = false,
    this.hideBackButton =
        false, // ✅ 2. ค่า Default เป็น false (แสดงปุ่มตามปกติ)
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

    // ตรวจสอบว่าหน้านี้เป็นหน้าปัจจุบันหรือไม่ (ป้องกันการโหลดซ้อนตอนอยู่หน้าอื่น)
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;

    // ถ้ามีข้อมูลวัวอยู่ (cow != null) แต่ ID ไม่ตรงกับที่หน้านี้ต้องการ (cow.animalId != widget.cowId)
    // และหน้านี้กำลังแสดงผลอยู่ (isCurrentRoute) -> ให้โหลดข้อมูลใหม่กลับมาเป็นของแม่โค
    if (cow != null && cow.animalId != widget.cowId && isCurrentRoute) {
      if (!detailState.isLoading) {
        logger.i('Reloading parent cow data: ID ${widget.cowId}');
        Future.microtask(() =>
            ref.read(cowDetailServiceProvider).fetchCowById(widget.cowId));
      }
      // แสดง Loading ระหว่างรอโหลดข้อมูลแม่โคกลับมา
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              AppShimmer(
                child: Container(
                  height: 300.h,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: AppShimmer(
                  child: Container(
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (detailState.isLoading) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              AppShimmer(
                child: Container(
                  height: 300.h,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: AppShimmer(
                  child: Container(
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (cow == null) {
      if (!detailState.isLoading) {
        Future.microtask(() =>
            ref.read(cowDetailServiceProvider).fetchCowById(widget.cowId));
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                AppShimmer(
                  child: Container(
                    height: 300.h,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: AppShimmer(
                    child: Container(
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return const Scaffold(body: Center(child: Text("ไม่พบข้อมูลวัว")));
    }

    final isDead = cow.status == 'DEATH';

    return CowDetailWidget(
      title: 'ข้อมูลประจำตัววัว',
      images: [
        if (cow.facePic != null) ...cow.facePic!,
        if (cow.bodyPic != null) ...cow.bodyPic!,
      ],
      tabController: _tabController,

      // ✅ 3. ปรับ Logic ตรงนี้: ถ้า hideBackButton เป็น true ให้ส่ง null (เพื่อซ่อนปุ่ม)
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
            onPressed: () =>
                _showQrDialog(context, cow.animalId.toString(), cow.nidNumber),
          ),
      ],
      // แสดง banner เตือนเมื่อวัวตาย
      banner: isDead && !widget.isReadOnly
          ? Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              color: Colors.grey.shade800,
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.white, size: 18.r),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'วัวตัวนี้ตายแล้ว — สามารถเปลี่ยนสถานะเท่านั้น',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
      profileHeader: Container(
        color: theme.scaffoldBackgroundColor,
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 4.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    cow.nidNumber,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: CowStatusUtils.getColor(cow.status)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                    border:
                        Border.all(color: CowStatusUtils.getColor(cow.status)),
                  ),
                  child: Text(
                    CowStatusUtils.getLabel(cow.status),
                    style: TextStyle(
                      color: CowStatusUtils.getColor(cow.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              'ชื่อ: ${cow.animalName}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.pets, size: 16.r, color: Colors.grey.shade600),
                SizedBox(width: 4.w),
                Text(cow.breed ?? 'ไม่ระบุสายพันธุ์',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 14.sp)),
                SizedBox(width: 16.w),
                Icon(cow.sex == 'MALE' ? Icons.male : Icons.female,
                    size: 16.r,
                    color: cow.sex == 'MALE' ? Colors.blue : Colors.pink),
                SizedBox(width: 4.w),
                Text(cow.sex == 'MALE' ? 'พ่อพันธุ์' : 'แม่พันธุ์',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 14.sp)),
              ],
            ),
          ],
        ),
      ),
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
          : _buildBottomBar(context, colorScheme, theme, cow.animalId!,
              cow.animalId!, isDead),
      // ซ่อน FAB กล้องเมื่อวัวตาย
      floatingActionButton: widget.isReadOnly || isDead
          ? null
          : FloatingActionButton(
              onPressed: () => _showScanInstructionDialog(context, cow),
              backgroundColor: colorScheme.secondary,
              foregroundColor: colorScheme.onSecondary,
              child: const Icon(Icons.camera_alt),
            ),
    );
  }

  void _showScanInstructionDialog(BuildContext context, Cow cow) {
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
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final result = await Navigator.push<List<String>?>(
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

                      if (result != null && result.isNotEmpty) {
                        final facePath = result[0]; // รูปหน้า
                        _verifyCowIdentity(facePath, cow);
                      }
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
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      
                      if (image != null) {
                        _verifyCowIdentity(image.path, cow);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r)),
                    ),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: Text('อัปโหลดเพื่อทดสอบ',
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

  Future<void> _verifyCowIdentity(String facePath, Cow cow) async {
    final originalFaces = cow.facePic;
    if (originalFaces == null || originalFaces.isEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('ไม่สามารถตรวจสอบได้'),
            content: const Text('ไม่มีรูปภาพใบหน้าเดิมของวัวเพื่อใช้ในการยืนยันตัวตน'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ตกลง'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // แสดงหน้า loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final isVerified = await ref
          .read(cowVerificationServiceProvider)
          .verifyCowIdentity(facePath, originalFaces);

      if (mounted) {
        Navigator.pop(context); // ปิด loading

        // แสดงผล
        showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r)),
              contentPadding: EdgeInsets.all(24.r),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isVerified ? Icons.check_circle : Icons.cancel,
                    color: isVerified ? Colors.green : Colors.red,
                    size: 80.r,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    isVerified ? 'ยืนยันตัวตนสำเร็จ!' : 'ยืนยันตัวตนไม่สำเร็จ',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: isVerified ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    isVerified
                        ? 'ระบบตรวจสอบสำเร็จ'
                        : 'กรุณาลองใหม่อีกครั้ง',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: FilledButton.styleFrom(
                        backgroundColor: isVerified ? Colors.green : Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'ตกลง',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // ปิด loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการตรวจสอบ: $e')),
        );
      }
    }
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
      ThemeData theme, int animalId, int cowId, bool isDead) {
    final isActivityTab = _tabController.index == 1;

    // ถ้าวัวตาย + อยู่แท็บกิจกรรม → ซ่อน bottom bar
    if (isDead && isActivityTab) {
      return const SizedBox.shrink();
    }

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
          child: isDead
              // ===== วัวตาย: ปุ่มเปลี่ยนสถานะ =====
              ? ElevatedButton.icon(
                  onPressed: () => _showStatusChangeModal(context, cowId),
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(
                    'เปลี่ยนสถานะ',
                    style:
                        TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r)),
                  ),
                )
              // ===== วัวปกติ: ปุ่มแก้ไข/เพิ่มกิจกรรม =====
              : ElevatedButton.icon(
                  onPressed: () async {
                    if (isActivityTab) {
                      context.push('/add-activity/$cowId');
                    } else {
                      final didEdit =
                          await context.push<bool>('/edit-form/$animalId');
                      if (didEdit == true) {
                        ref.invalidate(activitiesProvider(cowId));
                      }
                    }
                  },
                  icon: Icon(isActivityTab ? Icons.add : Icons.edit),
                  label: Text(
                    isActivityTab ? 'เพิ่มกิจกรรม' : 'แก้ไขข้อมูล',
                    style:
                        TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
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

  /// Bottom modal sheet สำหรับเปลี่ยนสถานะวัว (ใช้เมื่อวัวสถานะ DEATH)
  void _showStatusChangeModal(BuildContext context, int cowId) {
    String? selectedStatus;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24.w,
                right: 24.w,
                top: 16.h,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // Title
                  Text(
                    'เปลี่ยนสถานะวัว',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'วัวตัวนี้มีสถานะ "ตายแล้ว" — เลือกสถานะใหม่ด้านล่าง',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // Status options — ใช้สีที่เข้ากับ earth-tone theme
                  ...[
                    _StatusOption(
                      value: 'ACTIVE',
                      label: 'สุขภาพดี',
                      icon: Icons.favorite_rounded,
                      color: const Color(0xFF4CAF50), // Muted green
                    ),
                    _StatusOption(
                      value: 'SICK',
                      label: 'ป่วย',
                      icon: Icons.local_hospital_rounded,
                      color: const Color(0xFFE6A23C), // Warm amber
                    ),
                    _StatusOption(
                      value: 'SOLD',
                      label: 'ขายแล้ว',
                      icon: Icons.sell_rounded,
                      color: const Color(0xFF5C6BC0), // Muted indigo
                    ),
                  ].map((option) {
                    final isSelected = selectedStatus == option.value;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20.r),
                        onTap: () {
                          setModalState(() => selectedStatus = option.value);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 14.h),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? option.color.withValues(alpha: 0.08)
                                : colorScheme.surface,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isSelected
                                  ? option.color
                                  : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Icon in tinted circle
                              Container(
                                width: 40.r,
                                height: 40.r,
                                decoration: BoxDecoration(
                                  color: option.color.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(option.icon,
                                    color: option.color, size: 22.r),
                              ),
                              SizedBox(width: 14.w),
                              Text(
                                option.label,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? option.color
                                      : colorScheme.onSurface,
                                ),
                              ),
                              const Spacer(),
                              if (isSelected)
                                Icon(Icons.check_circle_rounded,
                                    color: option.color, size: 24.r),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 12.h),
                  // Save button — pill shape ตาม theme
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedStatus == null
                          ? null
                          : () async {
                              try {
                                await Supabase.instance.client
                                    .from('animals')
                                    .update({
                                  'status': selectedStatus,
                                  'updated_at':
                                      DateTime.now().toIso8601String(),
                                }).eq('animal_id', cowId);

                                // Refresh cow detail + cow list
                                ref
                                    .read(cowDetailServiceProvider)
                                    .fetchCowById(cowId);
                                ref
                                    .read(cowServiceProvider)
                                    .fetchCows(forceRefresh: true);

                                if (ctx.mounted && context.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                          'เปลี่ยนสถานะเรียบร้อยแล้ว'),
                                      backgroundColor: colorScheme.primary,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('เกิดข้อผิดพลาด: $e'),
                                      backgroundColor: Colors.red.shade700,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.r)),
                      ),
                      child: Text(
                        'บันทึก',
                        style: TextStyle(
                            fontSize: 16.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showQrDialog(BuildContext context, String cowId, String tagId) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenshotController = ScreenshotController();

    const String baseUrl = 'https://cowd-485909.web.app/#/cow-detail';
    final String qrData = '$baseUrl/$cowId';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tag ID: $tagId',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
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

                            if (context.mounted) {
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
                          if (context.mounted) {
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

/// Helper class for status options in the bottom modal
class _StatusOption {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatusOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}
