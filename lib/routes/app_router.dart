import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:th_cow_passport/supabase_config.dart';
import 'package:th_cow_passport/ui/screens/app_shell.dart';
import 'package:th_cow_passport/ui/screens/cow_detail_screen.dart';
import 'package:th_cow_passport/ui/screens/cow_form/cow_form_screen.dart';
import 'package:th_cow_passport/ui/screens/cow_list/cow_list_screen.dart';
import 'package:th_cow_passport/ui/screens/edit_cow_screen.dart';
import 'package:th_cow_passport/ui/screens/auth/login_screen.dart';
import 'package:th_cow_passport/ui/screens/auth/register_screen.dart';
import 'package:th_cow_passport/ui/screens/auth/forgot_password_screen.dart';
import 'package:th_cow_passport/ui/screens/auth/update_password_screen.dart';
import 'package:th_cow_passport/ui/screens/activity/wizard/add_activity_wizard.dart';
import 'package:th_cow_passport/ui/screens/notification/notification_center_screen.dart';

import 'package:th_cow_passport/ui/screens/profile_screen.dart';
import 'package:th_cow_passport/ui/screens/offer_screen.dart';
import 'package:th_cow_passport/ui/screens/buy_screen.dart';

// private navigators
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorAKey = GlobalKey<NavigatorState>(debugLabel: 'shellA');
final _shellNavigatorBKey = GlobalKey<NavigatorState>(debugLabel: 'shellB');
final _shellNavigatorCKey = GlobalKey<NavigatorState>(debugLabel: 'shellC');
final _shellNavigatorDKey = GlobalKey<NavigatorState>(debugLabel: 'shellD');

// ตัวแปรสำหรับเช็คว่าเปิดแอปมาจากการกดลิงก์กู้รหัสผ่านหรือไม่
bool isRecoveringPassword = false;

final router = GoRouter(
  initialLocation: '/',
  navigatorKey: _rootNavigatorKey,
  debugLogDiagnostics: true,
  // ให้ Router ประเมิน redirect ใหม่ทุกครั้งที่สถานะ Auth เปลี่ยน
  refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),

  // Redirect ตามสถานะการเข้าสู่ระบบ
  redirect: (context, state) {
    final session = supabase.auth.currentSession;
    final isLoggingIn = state.matchedLocation == '/login';
    final isRegistering = state.matchedLocation == '/register';
    final isForgotPassword = state.matchedLocation == '/forgot-password';
    final isResetPassword = state.matchedLocation == '/reset-password';
    final isPublicView = state.matchedLocation.startsWith('/cow-detail');

    // ถ้ากำลังอยู่ในโหมดกู้รหัสผ่าน ให้บังคับไปหน้า /reset-password ทันที
    if (isRecoveringPassword && !isResetPassword) {
      return '/reset-password';
    }

    // ถ้ายังไม่ Login และไม่ได้อยู่ที่หน้า Login หรือ Register -> บังคับไป Login
    if (session == null && !isLoggingIn && !isRegistering && !isForgotPassword && !isResetPassword && !isPublicView) {
      return '/login';
    }

    // ถ้า Login แล้ว แต่อยู่ที่หน้า Login, Register หรือ ลืมรหัสผ่าน -> ให้ไปหน้าแรก (Home)
    // เช็ค sessionRecognized ด้วย ไม่งั้นจะวนกับเงื่อนไขด้านล่างที่ส่งกลับมา /login
    if (session != null && sessionRecognized && (isLoggingIn || isRegistering || isForgotPassword)) {
      return '/';
    }

    // If there is an existing Supabase session restored on hot restart but
    // the app hasn't recognized it in this runtime, require the user to
    // explicitly log in again. This prevents the app from silently landing
    // on the home/profile screens after a hot restart.
    if (session != null &&
        !sessionRecognized &&
        !isLoggingIn &&
        !isRegistering &&
        !isForgotPassword &&
        !isResetPassword) {
      return '/login';
    }

    return null; // ไม่มีการ redirect
  },

  routes: [
    // หน้า Login
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    // หน้า Register
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // หน้า Forgot Password
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),

    // หน้า Update Password (ปลายทางของลิงก์กู้รหัสผ่าน)
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const UpdatePasswordScreen(),
    ),

    GoRoute(
      path: '/cow-detail/:id', // ชื่อ path นี้ต้องตรงกับ QR Code ที่เจนออกมา
      parentNavigatorKey:
          _rootNavigatorKey, // สำคัญ: ให้ทับ Shell Route ทั้งหมด
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return CowDetailScreen(
          cowId: id,
          isReadOnly: true,
          hideBackButton: true,
        );
      },
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
        return AddActivityWizard(cowId: cowId);
      },
    ),

    GoRoute(
      path: '/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationCenterScreen(),
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

// แปลง Stream ของ Supabase เป็น Listenable สำหรับ GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (AuthState authState) {
        
        // --- ดักจับ Event กู้รหัสผ่าน ---
        if (authState.event == AuthChangeEvent.passwordRecovery) {
          isRecoveringPassword = true;
        } 
        else if (authState.event == AuthChangeEvent.signedOut) {
          isRecoveringPassword = false;
        }
        // -----------------------------

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
