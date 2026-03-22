import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/routes/app_router.dart';
import 'package:th_cow_passport/services/notification/notification_service.dart';
import 'package:th_cow_passport/supabase_config.dart';
import 'package:th_cow_passport/ui/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:th_cow_passport/features/address/data/datasources/thai_address_datasource.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Initialize notification service
  await NotificationService().initialize();

  // Pre-load Thai address data (Non-blocking or awaited)
  // We can await it if we want it ready before the UI shows, 
  // or just fire and forget if it's okay for it to load in background.
  ThaiAddressDatasource().loadData();

  // If there's already a session when the app starts
  if (supabase.auth.currentSession != null) {
    sessionRecognized = true;
  }

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'CowD',
          theme: AppTheme.lightTheme,
          routerConfig: router,
        );
      },
    );
  }
}
