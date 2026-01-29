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
final signUpProvider = FutureProvider.autoDispose
    .family<void, ({String email, String password, String firstName, String lastName, String citizenId})>(
  (ref, params) async {
    final authService = ref.watch(authServiceProvider);
    
    // Sign up with metadata; Supabase trigger will create the user record
    await authService.signUp(
      email: params.email,
      password: params.password,
      firstName: params.firstName,
      lastName: params.lastName,
      citizenId: params.citizenId,
    );
  },
);

// Sign in provider
final signInProvider = FutureProvider.autoDispose
    .family<void, ({String email, String password})>(
  (ref, params) async {
    final authService = ref.watch(authServiceProvider);
    
    await authService.signIn(
      email: params.email,
      password: params.password,
    );
  },
);

// Sign out provider
final signOutProvider = FutureProvider.autoDispose<void>((ref) async {
  final authService = ref.watch(authServiceProvider);
  await authService.signOut();
});
