import 'dart:async'; // เพิ่ม import นี้
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:th_cow_passport/supabase_config.dart'; // import supabase config
import 'package:th_cow_passport/ui/screens/app_shell.dart';
import 'package:th_cow_passport/ui/screens/cow_detail_screen.dart';
import 'package:th_cow_passport/ui/screens/cow_form/cow_form_screen.dart';
import 'package:th_cow_passport/ui/screens/cow_list/cow_list_screen.dart';
import 'package:th_cow_passport/ui/screens/edit_cow_screen.dart';
import 'package:th_cow_passport/ui/screens/auth/login_screen.dart'; // เพิ่ม import หน้า Login
import 'package:th_cow_passport/ui/screens/auth/register_screen.dart'; // เพิ่ม import หน้า Register
import 'package:th_cow_passport/ui/screens/cow_activity/add_activity_screen.dart';
import 'package:th_cow_passport/services/cow_management/models/activity_model.dart';
import 'package:th_cow_passport/ui/screens/profile_screen.dart';
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
  // 1. เพิ่ม refreshListenable เพื่อให้ Router ทำงานใหม่เมื่อ Auth เปลี่ยนแปลง
  refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),

  // 2. เพิ่ม logic การ Redirect
  redirect: (context, state) {
    final session = supabase.auth.currentSession;
    final isLoggingIn = state.matchedLocation == '/login';
    final isRegistering = state.matchedLocation == '/register';

    // ถ้ายังไม่ Login และไม่ได้อยู่ที่หน้า Login หรือ Register -> บังคับไป Login
    if (session == null && !isLoggingIn && !isRegistering) {
      return '/login';
    }

    // ถ้า Login แล้ว แต่อยู่ที่หน้า Login -> ให้ไปหน้าแรก (Home)
    if (session != null && isLoggingIn) {
      return '/';
    }

    // If there is an existing Supabase session restored on hot restart but
    // the app hasn't recognized it in this runtime, require the user to
    // explicitly log in again. This prevents the app from silently landing
    // on the home/profile screens after a hot restart.
    if (session != null &&
        !sessionRecognized &&
        !isLoggingIn &&
        !isRegistering) {
      return '/login';
    }

    return null; // ไม่มีการ redirect
  },

  routes: [
    // 3. เพิ่ม Route สำหรับหน้า Login
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    // เพิ่ม Route สำหรับหน้า Register
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    GoRoute(
      path: '/detail/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return CowDetailScreen(cowId: id);
      },
    ),
    GoRoute(
      path: '/edit-form/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return EditCowScreen(cowId: id);
      },
    ),
    GoRoute(
      path: '/form',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CowFormScreen(),
    ),

    GoRoute(
      path: '/add-activity/:cowId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final cowId = int.parse(state.pathParameters['cowId']!);
        final activityType = state.extra as ActivityType;
        return AddActivityScreen(cowId: cowId, activityType: activityType);
      },
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

        // Tab 2: เสนอซื้อ (Offer)
        StatefulShellBranch(
          navigatorKey: _shellNavigatorBKey,
          routes: [
            GoRoute(
              path: '/offers',
              builder: (context, state) => const OfferScreen(),
            ),
          ],
        ),

        // Tab 3: ซื้อ (Buy)
        StatefulShellBranch(
          navigatorKey: _shellNavigatorCKey,
          routes: [
            GoRoute(
              path: '/market',
              builder: (context, state) => const BuyScreen(),
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

// 4. Class ช่วยแปลง Stream ของ Supabase เป็น Listenable สำหรับ GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (AuthState authState) {
        notifyListeners();
      },
    );
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
