import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class SupabaseConfig {
  static const String url = 'https://YOUR_PROJECT.supabase.co';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const String bucketName = 'cow';
}

// In-memory flag to mark that the app has recognized the session during this runtime.
// This is intentionally not persisted so a hot restart will require re-login.
bool sessionRecognized = false;
