import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Starting cow identification...'))
            );
          },
          child: const Icon(Icons.camera_alt),
        ),
      ),
    );
  }
}
