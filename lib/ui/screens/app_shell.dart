import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:th_cow_passport/services/notification/farm_alert_service.dart';
import 'package:th_cow_passport/services/offer/offer_badge_provider.dart';
import 'package:th_cow_passport/ui/widgets/common/app_badge.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _CustomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final ImageProvider? imageProvider;

  const _NavItem({
    this.icon = Icons.circle,
    this.selectedIcon = Icons.circle,
    required this.label,
    this.imageProvider,
  });
}

// ConsumerWidget เพื่อให้อ่านค่าจาก Riverpod ได้
class _CustomNavBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<_NavItem> _items = [
    _NavItem(
      imageProvider: AssetImage('assets/images/cow.png'),
      label: 'วัว',
    ),
    _NavItem(
      icon: Icons.handshake_outlined,
      selectedIcon: Icons.handshake,
      label: 'เสนอซื้อ',
    ),
    _NavItem(
      icon: Icons.shopping_cart_outlined,
      selectedIcon: Icons.shopping_cart,
      label: 'ซื้อ',
    ),
    _NavItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'บัญชี',
    ),
  ];

  const _CustomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    const textSecondary = Color(0xFF8D6E63);
    const primaryLight = Color(0xFFD7CCC8);

    final pendingCount = ref.watch(pendingOfferCountProvider).valueOrNull ?? 0;
    final pendingAlertCount = ref.watch(pendingAlertCountProvider);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(top: 8.h, bottom: 16.h, left: 8.w, right: 8.w),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final isSelected = index == currentIndex;

            // Badge: index 0 = farm alerts, index 1 = offers
            final badgeCount = (index == 0)
                ? pendingAlertCount
                : (index == 1)
                    ? pendingCount
                    : 0;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryLight.withValues(alpha: 0.5)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon พร้อม Badge จาก Supabase Realtime
                      AppBadge(
                        showBadge: badgeCount > 0,
                        count: badgeCount,
                        isDot: index == 0,
                        child: item.imageProvider != null
                            ? ImageIcon(
                                item.imageProvider!,
                                size: 22.r,
                                color: isSelected ? primary : textSecondary,
                              )
                            : Icon(
                                isSelected ? item.selectedIcon : item.icon,
                                size: 22.r,
                                color: isSelected ? primary : textSecondary,
                              ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        item.label,
                        style: GoogleFonts.prompt(
                          color: isSelected ? primary : textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
