import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:th_cow_passport/supabase_config.dart';
import 'package:th_cow_passport/services/profile/models/user_model.dart';

final logger = Logger();

class AuthService {
  final supabaseClient = supabase;

  // Sign up with email, password, and user metadata
  // The Supabase auth trigger will automatically create the user record in the 'users' table
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String citizenId,
  }) async {
    try {
      logger.i(
          '[AuthService] Signing up user: $email, name: $firstName $lastName, citizenId: $citizenId');
      final response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'citizen_id': citizenId,
        },
      );

      logger.i(
          '[AuthService.signUp] Sign up returned session: ${supabaseClient.auth.currentSession != null}');
      logger.i('[AuthService.signUp] [SUCCESS] Sign up successful for: $email');

      // Mark session recognized for this runtime so router allows navigation
      if (response.session != null) {
        sessionRecognized = true;
      }

      return response;
    } catch (e) {
      logger.e('[AuthService] Sign up error', error: e);
      rethrow;
    }
  }

  // [DEPRECATED] User record is now created automatically by Supabase trigger
  // This method is kept for backward compatibility but does nothing.
  Future<void> createUserInDatabase({
    String? userId,
    required String firstName,
    required String lastName,
    required String email,
    required UserRole role,
  }) async {
    logger.i(
        '[AuthService.createUserInDatabase] User record is created automatically by trigger. No manual insert needed.');
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      logger.i('[AuthService] Signing in user: $email');
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      logger.i('[AuthService.signIn] [SUCCESS] Sign in successful for: $email');
      // Mark session recognized for this runtime so router allows navigation
      sessionRecognized = true;
      return response;
    } catch (e) {
      logger.e('[AuthService] Sign in error', error: e);
      rethrow;
    }
  }

  // Sign in with citizen ID and password
  Future<AuthResponse> signInWithCitizenId({
    required String citizenId,
    required String password,
  }) async {
    try {
      logger.i('[AuthService] Attempting lookup for citizenId: $citizenId');

      // 1. Lookup email from users table
      // Note: This assumes public.users table has an 'email' column populated by trigger.
      // If not, this needs a different approach (e.g. Edge Function).
      final data = await supabaseClient
          .from('users')
          .select('email')
          .eq('citizen_id', citizenId)
          .maybeSingle();

      if (data == null || data['email'] == null) {
        logger.w('[AuthService] No user found with citizenId: $citizenId');
        throw 'invalid_credentials'; // Use generic error to match auth errors
      }

      final email = data['email'] as String;
      logger.i('[AuthService] Found email for citizenId: $email');

      // 2. Sign in with the found email
      return await signIn(email: email, password: password);
    } catch (e) {
      if (e is PostgrestException) {
        logger.e('[AuthService] Database error during lookup', error: e);
        // If column 'email' doesn't exist or other DB error
        throw 'database_error';
      }
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      logger.i('[AuthService] Signing out user');
      await supabaseClient.auth.signOut();
      logger.i('[AuthService.signOut] [SUCCESS] Sign out successful');
      // Clear runtime recognition so hot restart or next run requires fresh login
      sessionRecognized = false;
    } catch (e) {
      logger.e('[AuthService] Sign out error', error: e);
      rethrow;
    }
  }

  // Get current user from auth
  User? getCurrentUser() {
    final session = supabaseClient.auth.currentSession;
    if (session == null) return null;

    // Extract name from email or metadata
    final nameParts =
        session.user.userMetadata?['full_name'] as String? ?? 'User';
    final nameList = nameParts.split(' ');
    final firstName = nameList.isNotEmpty ? nameList.first : 'User';
    final lastName = nameList.length > 1 ? nameList.skip(1).join(' ') : '';

    return User(
      id: session.user.id,
      firstName: firstName,
      lastName: lastName,
      role: UserRole.FARMER,
      mobilePhone: null,
      address: null,
      province: null,
      title: null,
      birthDate: null,
      createdAt: DateTime.now(),
    );
  }

  // Get current user details from database
  Future<User?> getCurrentUserFromDatabase() async {
    final session = supabaseClient.auth.currentSession;
    if (session == null) return null;

    try {
      final response = await supabaseClient
          .from('users')
          .select()
          .eq('id', session.user.id)
          .single();

      return User.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return supabaseClient.auth.currentSession != null;
  }

  // Get auth user ID
  String? getUserId() {
    return supabaseClient.auth.currentSession?.user.id;
  }
}
