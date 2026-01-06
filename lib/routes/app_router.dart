import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:th_cow_passport/ui/screens/app_shell.dart';
import 'package:th_cow_passport/ui/screens/cow_detail_screen.dart';
import 'package:th_cow_passport/ui/screens/cow_form_screen.dart';
import 'package:th_cow_passport/ui/screens/cow_list_screen.dart';
import 'package:th_cow_passport/ui/screens/edit_cow_screen.dart';
import 'package:th_cow_passport/ui/screens/profile_screen.dart';

// private navigators
final _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  initialLocation: '/',
  navigatorKey: _rootNavigatorKey,
  debugLogDiagnostics: true,
  routes: [
    // These screens are outside the shell and will cover the nav bar
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
    
    // The main app shell with bottom navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // Branch A: Home (Cow List)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const CowListScreen(),
            ),
          ],
        ),

        // Branch B: Add Cow
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/form',
              builder: (context, state) => const CowFormScreen(),
            ),
          ],
        ),

        // Branch C: Profile
        StatefulShellBranch(
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