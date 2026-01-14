import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart'; // import package qr_flutter
import 'package:th_cow_passport/ui/screens/cow_detail/tabs/activity/activity_tab.dart';
import 'package:th_cow_passport/ui/screens/cow_detail/tabs/general/general_tab.dart';
import 'package:th_cow_passport/ui/screens/cow_detail/tabs/health/health_tab.dart';
import 'package:th_cow_passport/ui/screens/cow_detail/tabs/vaccine/vaccine_tab.dart';
import 'package:th_cow_passport/ui/widgets/owner_overlay.dart';

class CowDetailScreen extends StatelessWidget {
  const CowDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          title: const Text('Cow Details'),
          actions: [
            // --- เพิ่มปุ่ม QR Code ตรงนี้ ---
            IconButton(
              icon: const Icon(
                  Icons.qr_code_2), // ใช้ icon qr_code_2 ให้ดูชัดเจนขึ้น
              tooltip: 'Show QR Code',
              onPressed: () =>
                  _showQrDialog(context, '101'), // ส่ง Cow ID ไปสร้าง QR
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.go('/edit-form/101'),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'ข้อมูลทั่วไป'),
              Tab(text: 'วัคซีน'),
              Tab(text: 'สุขภาพ'),
              Tab(text: 'กิจกรรม'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            GeneralTab(),
            VaccineTab(),
            HealthTab(),
            ActivityTab(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => showOwnerOverlay(context),
              icon: const Icon(Icons.shopping_cart),
              label: const Text('เสนอซื้อวัวตัวนี้',
                  style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Starting cow identification...')));
          },
          child: const Icon(Icons.camera_alt),
        ),
      ),
    );
  }

  // --- ฟังก์ชันแสดง QR Code Dialog ---
  void _showQrDialog(BuildContext context, String cowId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // --- เพิ่มบรรทัดนี้เพื่อจัดปุ่มให้อยู่กึ่งกลาง ---
          actionsAlignment: MainAxisAlignment.center,

          title: Center(child: Text('Cow ID: $cowId')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: QrImageView(
                  data: cowId,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'สแกนเพื่อดูข้อมูลวัว',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ปิด'),
            ),
            const SizedBox(width: 8), // เว้นระยะห่างระหว่างปุ่มเล็กน้อย
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('บันทึก QR Code แล้ว (Mock)')),
                );
              },
              icon: const Icon(Icons.save_alt),
              label: const Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }
}
