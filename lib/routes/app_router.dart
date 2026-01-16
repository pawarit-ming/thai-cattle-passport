import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:th_cow_passport/ui/screens/app_shell.dart';
import 'package:th_cow_passport/ui/screens/cow_detail_screen.dart';
import 'package:th_cow_passport/ui/screens/cow_form_screen.dart';
import 'package:th_cow_passport/ui/screens/cow_list_screen.dart';
import 'package:th_cow_passport/ui/screens/edit_cow_screen.dart';
import 'package:th_cow_passport/ui/screens/profile_screen.dart';
// เพิ่ม import 2 บรรทัดนี้ (ตรวจสอบ path ให้ตรงกับโฟลเดอร์ที่คุณวางไฟล์ไว้)
import 'package:th_cow_passport/ui/screens/offer_screen.dart';
import 'package:th_cow_passport/ui/screens/buy_screen.dart';

// private navigators
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorAKey = GlobalKey<NavigatorState>(debugLabel: 'shellA');
final _shellNavigatorBKey = GlobalKey<NavigatorState>(debugLabel: 'shellB');
final _shellNavigatorCKey = GlobalKey<NavigatorState>(debugLabel: 'shellC');
final _shellNavigatorDKey = GlobalKey<NavigatorState>(debugLabel: 'shellD');

final router = GoRouter(
  initialLocation: '/',
  navigatorKey: _rootNavigatorKey,
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: '/detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CowDetailScreen(),
    ),
    GoRoute(
      path: '/edit-form/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return EditCowScreen(cowId: id);
      },
    ),
    GoRoute(
      path: '/form',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CowFormScreen(),
    ),

    // --- Shell Route (Bottom Navigation) ---
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // Tab 1: วัว (Home / Cow List)
        StatefulShellBranch(
          navigatorKey: _shellNavigatorAKey,
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const CowListScreen(),
            ),
          ],
        ),

        // Tab 2: เสนอซื้อ (Offer) -> แก้ไขให้ชี้ไปที่ OfferScreen
        StatefulShellBranch(
          navigatorKey: _shellNavigatorBKey,
          routes: [
            GoRoute(
              path: '/offers',
              builder: (context, state) => const OfferScreen(), // เปลี่ยนตรงนี้
            ),
          ],
        ),

        // Tab 3: ซื้อ (Buy) -> แก้ไขให้ชี้ไปที่ BuyScreen
        StatefulShellBranch(
          navigatorKey: _shellNavigatorCKey,
          routes: [
            GoRoute(
              path: '/market',
              builder: (context, state) => const BuyScreen(), // เปลี่ยนตรงนี้
            ),
          ],
        ),

        // Tab 4: บัญชี (Profile)
        StatefulShellBranch(
          navigatorKey: _shellNavigatorDKey,
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);