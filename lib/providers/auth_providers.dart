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

// Auth state provider - tracks if user is logged in.
//
// IMPORTANT: Firebase Auth on Android/iOS restores the persisted session
// asynchronously AFTER Firebase.initializeApp returns. If we subscribed to
// userChanges() alone, the first emission can be `null` on a cold launch
// (because restore hasn't completed yet), which would route the user to
// LoginScreen even though they have a valid session on disk.
//
// To avoid that: this stream prepends FirebaseAuth.instance.currentUser
// (which is already populated by the time main() awaits initializeApp on
// most cold-launch paths) as the very first emission, then yields the
// regular userChanges() stream after it. That way the router never sees a
// spurious null before restoration finishes.
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
    UserCredential? userCredential;
    try {
      final authService = ref.read(firebaseAuthProvider);
      final userService = ref.read(firestoreUserProvider);

      userCredential = await authService.signUp(
        email: email,
        password: password,
      );

      // Set the display name in Firebase Auth so every screen can read it.
      await userCredential.user?.updateDisplayName(username);

      // Fire-and-forget: Firestore profile creation must never block signup.
      // If rules are not yet deployed, the write silently queues or fails.
      final uid = userCredential.user?.uid;
      if (uid != null) {
        userService.createUserProfile(
          userId: uid,
          email: email,
          username: username,
        ).catchError((_) {});
      }

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      // Auth itself failed — roll back nothing (user was never created).
      state = AsyncValue.error(e, stack);
      rethrow;
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
      rethrow;
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
      rethrow;
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
      rethrow;
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

// Scoped user ID — rebuilds game providers when auth user changes
final currentUserIdProvider = Provider<String>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.asData?.value?.uid ?? 'anonymous';
});