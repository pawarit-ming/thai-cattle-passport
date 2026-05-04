import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:th_cow_passport/services/auth/auth_service.dart';
import 'package:th_cow_passport/services/profile/models/user_model.dart';

final authServiceProvider = Provider((ref) => AuthService());

// Current logged-in user from database
final currentUserProvider = FutureProvider<User?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.getCurrentUserFromDatabase();
});

// Auth state (is user logged in)
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.isAuthenticated();
});

// Current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.getUserId();
});

// Sign up provider
final signUpProvider = FutureProvider.autoDispose.family<
    void,
    ({
      String email,
      String password,
      String firstName,
      String lastName,
      String phone
    })>(
  (ref, params) async {
    final authService = ref.watch(authServiceProvider);

    // Sign up with metadata; Supabase trigger will create the user record
    await authService.signUp(
      email: params.email,
      password: params.password,
      firstName: params.firstName,
      lastName: params.lastName,
      phone: params.phone,
    );
  },
);

// Sign in provider
final signInProvider =
    FutureProvider.autoDispose.family<void, ({String input, String password})>(
  (ref, params) async {
    final authService = ref.watch(authServiceProvider);
    final input = params.input.trim();

    // Simple check: if contains '@', assume email. Otherwise assume Citizen ID/Username
    final isEmail = input.contains('@');

    if (isEmail) {
      await authService.signIn(
        email: input,
        password: params.password,
      );
    } else {
      // Assume phone number
      await authService.signInWithPhone(
        phone: input,
        password: params.password,
      );
    }
  },
);

// Reset password provider
final resetPasswordProvider = FutureProvider.autoDispose.family<void, String>(
  (ref, email) async {
    final authService = ref.watch(authServiceProvider);
    
    // เรียกฟังก์ชันรีเซ็ตรหัสผ่านจาก AuthService
    await authService.resetPassword(email); 
  },
);

// Update password provider
final updatePasswordProvider = FutureProvider.autoDispose.family<void, String>(
  (ref, newPassword) async {
    final authService = ref.watch(authServiceProvider);
    await authService.updatePassword(newPassword); 
  },
);

// Sign out provider
final signOutProvider = FutureProvider.autoDispose<void>((ref) async {
  final authService = ref.watch(authServiceProvider);
  await authService.signOut();
});