import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        items: const [
          BottomNavigationBarItem(
            // แนะนำ Icons.pets (สัตว์) หรือ Icons.agriculture (เกษตรกรรม)
            icon: ImageIcon(AssetImage('assets/images/cow.png')),
            label: 'วัว',
          ),
          BottomNavigationBarItem(
            // แนะนำ Icons.handshake (ตกลงซื้อขาย) หรือ Icons.gavel (ประมูล)
            icon: Icon(Icons.handshake),
            label: 'เสนอซื้อ',
          ),
          BottomNavigationBarItem(
            // แนะนำ Icons.shopping_cart (ตะกร้าสินค้า)
            icon: Icon(Icons.shopping_cart),
            label: 'ซื้อ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'บัญชี',
          ),
        ],
      ),
    );
  }
}
