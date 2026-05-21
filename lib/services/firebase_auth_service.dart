import 'package:firebase_auth/firebase_auth.dart';

/// Service for handling Firebase authentication
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes — uses userChanges() so profile
  /// updates (displayName, photoURL) also trigger downstream rebuilds.
  ///
  /// Cold-launch behaviour: Firebase hydrates the persisted user
  /// asynchronously after Firebase.initializeApp() returns. If a subscriber
  /// reads userChanges() before hydration finishes, the first event is a
  /// spurious `null` — which would bounce a returning user back to the
  /// login screen. To prevent that, we:
  ///   1. Yield `currentUser` immediately (often already populated).
  ///   2. If it was null, give the SDK up to 800ms to emit a non-null user
  ///      via authStateChanges before we proceed.
  ///   3. Then forward userChanges() normally for the rest of the session.
  Stream<User?> get authStateChanges async* {
    final initial = _auth.currentUser;
    if (initial != null) {
      yield initial;
    } else {
      // Wait briefly for hydration. If we see a user, yield it; otherwise
      // yield null after the grace window.
      User? hydrated;
      try {
        hydrated = await _auth
            .authStateChanges()
            .firstWhere((u) => u != null)
            .timeout(const Duration(milliseconds: 800));
      } catch (_) {
        hydrated = null;
      }
      yield hydrated;
    }
    yield* _auth.userChanges();
  }

  /// Sign up with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Reset password via email
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Update user email
  Future<void> updateEmail({required String newEmail}) async {
    try {
      await currentUser?.verifyBeforeUpdateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Update user password
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Delete user account
  Future<void> deleteUser() async {
    try {
      await currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Handle Firebase auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'Email is already in use.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}