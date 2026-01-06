import 'package:flutter/material.dart';
import 'package:th_cow_passport/routes/app_router.dart';
import 'package:th_cow_passport/ui/theme/app_theme.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TH Cow Passport',
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
