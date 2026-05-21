import 'package:firebase_auth/firebase_auth.dart';

/// Converts a Firebase Auth exception into a short, friendly sentence.
String friendlyAuthError(Object e) {
  if (e is FirebaseAuthException) {
    return switch (e.code) {
      // ── Sign-up ────────────────────────────────────────────────
      'email-already-in-use'  => 'That email is already linked to an account. Try logging in instead.',
      'weak-password'         => 'That password is too short — pick something with at least 6 characters.',
      'operation-not-allowed' => 'Account creation is temporarily unavailable. Try again later.',

      // ── Sign-in ────────────────────────────────────────────────
      // Firebase v9+ merges user-not-found + wrong-password into invalid-credential
      'invalid-credential'    => 'Email or password is incorrect. Please double-check and try again.',
      'user-not-found'        => 'No account found with that email. Did you mean to sign up?',
      'wrong-password'        => 'Wrong password. Double-check and try again.',
      'user-disabled'         => 'This account has been suspended. Please contact support.',
      'too-many-requests'     => "Too many failed attempts. Take a breather and try again in a moment.",

      // ── Shared ─────────────────────────────────────────────────
      'invalid-email'          => "That doesn't look like a valid email address.",
      'network-request-failed' => 'No internet connection. Check your network and try again.',

      // ── Password reset ─────────────────────────────────────────
      'missing-email'          => 'Enter your email address first.',

      // Fallback — still better than the raw Firebase message
      _ => 'Something went wrong (${e.code}). Please try again.',
    };
  }
  return 'An unexpected error occurred. Please try again.';
}
