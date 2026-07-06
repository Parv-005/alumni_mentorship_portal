import 'dart:developer' as developer;

import 'package:alumni_mentorship_platform/core/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication repository — wraps Supabase Auth and exposes the
/// operations the app needs (sign-up, sign-in, sign-out, session stream).
///
/// `signUp` passes `full_name` and `role` through `data`, which is then read
/// by the `public.handle_new_user` SQL trigger to populate `profiles`.
class AuthRepository {
  const AuthRepository();

  GoTrueClient get _auth => supabase.auth;

  /// Current session, or `null` if signed out.
  Session? get currentSession => _auth.currentSession;

  /// Stream of auth state changes (sign-in, sign-out, token refresh).
  Stream<AuthState> get onAuthChanges => _auth.onAuthStateChange;

  /// Creates a new user. The `fullName` and `role` are forwarded as
  /// `raw_user_meta_data` so the SQL trigger can populate the profile row.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    developer.log('signUp email=$email role=$role', name: 'AuthRepository');
    return _auth.signUp(
      email: email,
      password: password,
      data: <String, dynamic>{'full_name': fullName, 'role': role},
    );
  }

  /// Signs in an existing user with email + password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    developer.log('signIn email=$email', name: 'AuthRepository');
    return _auth.signInWithPassword(email: email, password: password);
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    developer.log('signOut', name: 'AuthRepository');
    await _auth.signOut();
  }
}
