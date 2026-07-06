import 'dart:developer' as developer;

import 'package:alumni_mentorship_platform/core/supabase/supabase_client.dart';
import 'package:alumni_mentorship_platform/data/models/mentor.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for `public.mentors` rows. Mentor listings always include the
/// joined `profiles!inner(*)` so the UI can show the mentor's name and avatar.
class MentorRepository {
  const MentorRepository();

  /// Lists mentors. [search] matches against `profiles.full_name` and
  /// `mentors.domain`. [domain] filters by exact domain. [availability]
  /// filters by availability status. Results are ordered newest first.
  Future<List<Mentor>> list({
    String? search,
    String? domain,
    String? availability,
  }) async {
    developer.log(
      'list search=$search domain=$domain availability=$availability',
      name: 'MentorRepository',
    );
    PostgrestFilterBuilder<PostgrestList> query = supabase
        .from('mentors')
        .select('*, profiles!inner(*)');

    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('profiles.full_name', '%${search.trim()}%');
    }
    if (domain != null && domain.isNotEmpty) {
      query = query.eq('domain', domain);
    }
    if (availability != null && availability.isNotEmpty) {
      query = query.eq('availability', availability);
    }

    final List<dynamic> rows = await query.order(
      'created_at',
      ascending: false,
    );
    return rows
        .cast<Map<String, dynamic>>()
        .map(Mentor.fromJson)
        .toList(growable: false);
  }

  /// Fetches a single mentor by id, including the joined profile.
  Future<Mentor?> fetchById(String id) async {
    developer.log('fetchById id=$id', name: 'MentorRepository');
    final data = await supabase
        .from('mentors')
        .select('*, profiles!inner(*)')
        .eq('id', id)
        .maybeSingle();
    if (data == null) {
      return null;
    }
    return Mentor.fromJson(data);
  }

  /// Upserts the current user's mentor profile. The id is set to the
  /// currently signed-in user; if no row exists, a new one is inserted.
  Future<Mentor> upsertOwn(Mentor mentor) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Cannot upsert mentor profile when not signed in');
    }
    final Map<String, dynamic> values = <String, dynamic>{
      'id': user.id,
      'domain': mentor.domain,
      'experience_years': mentor.experienceYears,
      'bio': mentor.bio,
      'availability': mentor.availability,
      'skills': mentor.skills,
      'is_featured': mentor.isFeatured,
      if (mentor.linkedinUrl != null) 'linkedin_url': mentor.linkedinUrl,
    };
    developer.log('upsertOwn id=${user.id}', name: 'MentorRepository');
    final data = await supabase
        .from('mentors')
        .upsert(values)
        .select('*, profiles!inner(*)')
        .single();
    return Mentor.fromJson(data);
  }

  /// Convenience for the "I'm available" toggle. Updates the availability
  /// column on the current user's mentor row.
  Future<Mentor> setAvailability(String availability) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Cannot update availability when not signed in');
    }
    developer.log(
      'setAvailability $availability id=${user.id}',
      name: 'MentorRepository',
    );
    final data = await supabase
        .from('mentors')
        .update(<String, dynamic>{'availability': availability})
        .eq('id', user.id)
        .select('*, profiles!inner(*)')
        .single();
    return Mentor.fromJson(data);
  }

  /// Returns the current user's mentor profile, or `null` if they have not
  /// yet created one.
  Future<Mentor?> fetchOwnMentorProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      return null;
    }
    return fetchById(user.id);
  }
}
