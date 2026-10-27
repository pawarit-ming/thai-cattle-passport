import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// Real values are passed at build time and never committed:
//   flutter run --dart-define-from-file=supabase_env.json
// (copy supabase_env.example.json; the real file is gitignored).
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );
  static const String bucketName = 'cow';
}

// In-memory flag to mark that the app has recognized the session during this runtime.
// This is intentionally not persisted so a hot restart will require re-login.
bool sessionRecognized = false;
