import 'dart:developer' as developer;

import 'package:alumni_mentorship_platform/core/supabase/supabase_client.dart';
import 'package:alumni_mentorship_platform/data/models/user_profile.dart';

/// Repository for `public.profiles` rows.
class ProfileRepository {
  const ProfileRepository();

  /// Fetches the profile for the currently signed-in user.
  /// Returns `null` if no row exists (e.g. trigger has not run yet).
  Future<UserProfile?> fetchOwn() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      return null;
    }
    developer.log('fetchOwn id=${user.id}', name: 'ProfileRepository');
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (data == null) {
      return null;
    }
    return UserProfile.fromJson(data);
  }

  /// Fetches a profile by id. Returns `null` if not found.
  Future<UserProfile?> fetchById(String id) async {
    developer.log('fetchById id=$id', name: 'ProfileRepository');
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) {
      return null;
    }
    return UserProfile.fromJson(data);
  }

  /// Updates the current user's profile. `null` parameters are not modified.
  Future<UserProfile> updateOwn({
    String? fullName,
    int? graduationYear,
    String? program,
    String? avatarUrl,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Cannot update profile when not signed in');
    }
    final Map<String, dynamic> values = <String, dynamic>{};
    if (fullName != null) values['full_name'] = fullName;
    if (graduationYear != null) values['graduation_year'] = graduationYear;
    if (program != null) values['program'] = program;
    if (avatarUrl != null) values['avatar_url'] = avatarUrl;

    developer.log(
      'updateOwn id=${user.id} keys=${values.keys.toList()}',
      name: 'ProfileRepository',
    );

    final data = await supabase
        .from('profiles')
        .update(values)
        .eq('id', user.id)
        .select()
        .single();
    return UserProfile.fromJson(data);
  }
}
