import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:th_cow_passport/services/cow_management/cow_detail/cow_detail_service.dart';
import 'package:th_cow_passport/ui/screens/camera_screen.dart';

import 'package:th_cow_passport/ui/screens/cow_detail/tabs/activity/activity_tab.dart';
import 'package:th_cow_passport/ui/screens/cow_detail/tabs/general/general_tab.dart';
import 'package:th_cow_passport/ui/widgets/cow_detail_widget.dart';

class CowDetailScreen extends ConsumerStatefulWidget {
  final int cowId;
  const CowDetailScreen({super.key, required this.cowId});

  @override
  ConsumerState<CowDetailScreen> createState() => _CowDetailScreenState();
}

class _CowDetailScreenState extends ConsumerState<CowDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // รีเฟรช UI เมื่อ Tab เปลี่ยน
    });
    // ดึงข้อมูลเมื่อเข้าหน้าจอ
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
      return const Scaffold(body: Center(child: Text("ไม่พบข้อมูลวัว")));
    }

    return CowDetailWidget(
      title: 'ข้อมูลประจำตัววัว',
      images: [
        if (cow.facePic != null) ...cow.facePic!,
        if (cow.bodyPic != null) ...cow.bodyPic!,
        if (cow.markPic != null) ...cow.markPic!,
      ],
      tabController: _tabController,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_2),
          tooltip: 'Show QR Code',
          onPressed: () => _showQrDialog(context, cow.nidNumber ?? 'unknown'),
        ),
      ],
      tabs: const [
        Tab(text: 'ข้อมูลทั่วไป'),
        Tab(text: 'กิจกรรม'),
      ],
      tabViews: [
        const GeneralTab(),
        ActivityTab(cowId: cow.animalId!),
      ],
      bottomBar: _buildBottomBar(
          context, colorScheme, theme, cow.animalId!, cow.animalId!),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CameraScreen(
                baseTitle: 'ระบุตัวตนวัว',
                steps: ['หน้าวัว', 'ตัววัว', 'ขาวัว'],
              ),
            ),
          );
        },
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        child: const Icon(Icons.camera_alt),
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
            onPressed: () {
// ... (context handled by tool)
              if (isActivityTab) {
                context.push('/add-activity/$cowId');
              } else {
                context.push('/edit-form/$animalId');
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
                  borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ),
      ),
    );
  }

  void _showQrDialog(BuildContext context, String cowId) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
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
                    data: cowId,
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
