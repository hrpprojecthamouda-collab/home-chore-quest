import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firebase_auth_service.dart';
import '../services/firestore_user_service.dart';

// Firebase service providers
final firebaseAuthProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final firestoreUserProvider = Provider<FirestoreUserService>((ref) {
  return FirestoreUserService();
});

// Auth state provider - tracks if user is logged in
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(firebaseAuthProvider);
  return authService.authStateChanges;
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authService = ref.watch(firebaseAuthProvider);
  return authService.currentUser;
});

// User profile provider
final userProfileProvider = FutureProvider.family<UserProfile?, String>((ref, userId) async {
  final userService = ref.watch(firestoreUserProvider);
  return userService.getUserProfile(userId);
});

// User profile stream provider (real-time updates)
final userProfileStreamProvider = StreamProvider.family<UserProfile?, String>((ref, userId) {
  final userService = ref.watch(firestoreUserProvider);
  return userService.userProfileStream(userId);
});

// Authentication notifier for handling sign up/sign in/sign out
class AuthNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> signUp({required String email, required String password, required String username}) async {
    state = const AsyncValue.loading();
    try {
      final authService = ref.read(firebaseAuthProvider);
      final userService = ref.read(firestoreUserProvider);

      final userCredential = await authService.signUp(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      await userService.createUserProfile(
        userId: userCredential.user!.uid,
        email: email,
        username: username,
      );

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final authService = ref.read(firebaseAuthProvider);
      await authService.signIn(email: email, password: password);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      final authService = ref.read(firebaseAuthProvider);
      await authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> resetPassword({required String email}) async {
    state = const AsyncValue.loading();
    try {
      final authService = ref.read(firebaseAuthProvider);
      await authService.resetPassword(email: email);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AsyncValue<void>>(() {
  return AuthNotifier();
});

// Helper provider for checking if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});