import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:th_cow_passport/ui/screens/cow_detail/tabs/activity/activity_tab.dart';
import 'package:th_cow_passport/ui/screens/cow_detail/tabs/general/general_tab.dart';
import 'package:th_cow_passport/ui/screens/cow_detail/tabs/health/health_tab.dart';
import 'package:th_cow_passport/ui/screens/cow_detail/tabs/vaccine/vaccine_tab.dart';
import 'package:th_cow_passport/ui/screens/cow_identification_screen.dart';
// import 'package:th_cow_passport/ui/widgets/owner_overlay.dart'; // ไม่ได้ใช้แล้วถ้าเอาปุ่มซื้อออก

class CowDetailScreen extends StatelessWidget {
  const CowDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              // 1. ส่วน AppBar ด้านบนสุด (Sticky)
              SliverAppBar(
                pinned: true,
                floating: false,
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                centerTitle: true,
                title: const Text(
                  'ข้อมูลประจำตัววัว',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                leading: BackButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                ),
                actions: [
                  // --- แก้ไขจุดที่ 1: ลบปุ่ม Edit ออก เหลือแค่ QR Code ---
                  IconButton(
                    icon: const Icon(Icons.qr_code_2),
                    tooltip: 'Show QR Code',
                    onPressed: () => _showQrDialog(context, '101'),
                  ),
                ],
              ),

              // 2. ส่วนรูปภาพ
              SliverToBoxAdapter(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    'https://images.unsplash.com/photo-1546445317-29f4545e9d53?q=80&w=1000',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.pets, size: 80, color: Colors.grey[500]),
                      );
                    },
                  ),
                ),
              ),

              // 3. ส่วน TabBar (Sticky)
              SliverPersistentHeader(
                delegate: _StickyTabBarDelegate(
                  TabBar(
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: colorScheme.primary,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    tabs: const [
                      Tab(text: 'ข้อมูลทั่วไป'),
                      // Tab(text: 'ประวัติวัคซีน'),
                      // Tab(text: 'สุขภาพ'),
                      Tab(text: 'กิจกรรม'),
                    ],
                  ),
                  backgroundColor: theme.scaffoldBackgroundColor,
                ),
                pinned: true,
              ),
            ];
          },
          body: const TabBarView(
            children: [
              GeneralTab(),
              // VaccineTab(),
              // HealthTab(),
              ActivityTab(),
            ],
          ),
        ),

        // --- แก้ไขจุดที่ 2: เปลี่ยนปุ่มด้านล่างเป็นปุ่มแก้ไข ---
        bottomNavigationBar: _buildBottomBar(context, colorScheme, theme),
        
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CowIdentificationScreen(),
              ),
            );
          },
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          child: const Icon(Icons.camera_alt),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            // เปลี่ยน Action เป็นการไปหน้าแก้ไข
            onPressed: () => context.go('/edit-form/101'), 
            // เปลี่ยน Icon และข้อความ
            icon: const Icon(Icons.edit), 
            label: const Text('แก้ไขข้อมูล',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Center(
              child: Text('Cow ID: $cowId',
                  style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.scaffoldBackgroundColor, width: 2),
                ),
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: QrImageView(
                    data: cowId,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
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

// Helper Class สำหรับ Sticky TabBar (คงเดิม)
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color backgroundColor;

  _StickyTabBarDelegate(this._tabBar, {required this.backgroundColor});

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}