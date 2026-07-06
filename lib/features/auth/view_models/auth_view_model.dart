import 'dart:async';
import 'dart:developer' as developer;

import 'package:alumni_mentorship_platform/data/models/user_profile.dart';
import 'package:alumni_mentorship_platform/data/repositories/auth_repository.dart';
import 'package:alumni_mentorship_platform/data/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Top-level app state: current session + user profile, plus
/// authentication actions. Screens listen to this view model for sign-in
/// status, role checks, and to drive the auth-aware router redirect.
///
/// The view model listens to `onAuthStateChange` and re-fetches the
/// `profiles` row whenever the auth state changes.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    AuthRepository? authRepository,
    ProfileRepository? profileRepository,
  }) : _authRepository = authRepository ?? const AuthRepository(),
       _profileRepository = profileRepository ?? const ProfileRepository() {
    _bootstrap();
  }

  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;

  Session? _session;
  UserProfile? _profile;
  bool _loading = false;
  String? _error;
  StreamSubscription<AuthState>? _authSub;

  /// The current Supabase session, or `null` when signed out.
  Session? get session => _session;

  /// The current user's profile row, or `null` while loading or signed out.
  UserProfile? get profile => _profile;

  /// True while a sign-in / register / sign-out action is in flight.
  bool get loading => _loading;

  /// Last error message (cleared on the next action).
  String? get error => _error;

  bool get isAuthenticated => _session != null;
  bool get isStudent => _profile?.role == 'student';
  bool get isMentor => _profile?.role == 'alumni';
  bool get isAdmin => _profile?.role == 'admin';

  /// Role string (`student`, `alumni`, `admin`, or `null` if no profile).
  String? get role => _profile?.role;

  Future<void> _bootstrap() async {
    _session = _authRepository.currentSession;
    if (_session != null) {
      await _loadProfile();
    }
    _authSub = _authRepository.onAuthChanges.listen(_onAuthChanged);
    notifyListeners();
  }

  Future<void> _onAuthChanged(AuthState state) async {
    developer.log('auth state: ${state.event}', name: 'AuthViewModel');
    final Session? next = state.session;
    if (next?.accessToken == _session?.accessToken && _profile != null) {
      return;
    }
    _session = next;
    if (next == null) {
      _profile = null;
    } else {
      await _loadProfile();
    }
    notifyListeners();
  }

  Future<void> _loadProfile() async {
    try {
      _profile = await _profileRepository.fetchOwn();
    } on Object catch (e, st) {
      developer.log('Failed to load profile', error: e, stackTrace: st);
      _profile = null;
    }
  }

  /// Signs in with email + password. Returns `true` on success.
  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    try {
      final response = await _authRepository.signIn(
        email: email,
        password: password,
      );
      if (response.session != null) {
        _session = response.session;
        await _loadProfile();
      }
      _error = null;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } on Object catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Registers a new user and triggers profile creation via SQL.
  /// Returns `true` on success.
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    _setLoading(true);
    try {
      final response = await _authRepository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
      if (response.session != null) {
        _session = response.session;
        await _loadProfile();
      }
      _error = null;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } on Object catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authRepository.signOut();
    } on Object catch (e, st) {
      developer.log('signOut error', error: e, stackTrace: st);
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
