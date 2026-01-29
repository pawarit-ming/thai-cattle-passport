import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/routes/app_router.dart';
import 'package:th_cow_passport/supabase_config.dart';
import 'package:th_cow_passport/ui/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  
  // If there's already a session when the app starts (e.g., from previous login
  // or hot restart with session persistence), mark it as recognized so the router
  // doesn't force a redirect to /login.
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
