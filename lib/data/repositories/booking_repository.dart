import 'dart:developer' as developer;

import 'package:alumni_mentorship_platform/core/supabase/supabase_client.dart';
import 'package:alumni_mentorship_platform/data/models/booking_request.dart';

/// Repository for `public.booking_requests`.
class BookingRepository {
  const BookingRepository();

  /// Creates a booking request from the current user (as student) to a
  /// [mentorId]. Returns the freshly inserted row.
  Future<BookingRequest> create({
    required String mentorId,
    required String topic,
    required String sessionType,
    DateTime? preferredAt,
    String? message,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Cannot create booking when not signed in');
    }
    final Map<String, dynamic> values = <String, dynamic>{
      'student_id': user.id,
      'mentor_id': mentorId,
      'topic': topic,
      'session_type': sessionType,
      if (preferredAt != null) 'preferred_at': preferredAt.toIso8601String(),
      'message': message ?? '',
    };
    developer.log('create mentorId=$mentorId', name: 'BookingRepository');
    final data = await supabase
        .from('booking_requests')
        .insert(values)
        .select()
        .single();
    return BookingRequest.fromJson(data);
  }

  /// Lists booking requests where the current user is the student.
  Future<List<BookingRequest>> listForStudent() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      return const <BookingRequest>[];
    }
    developer.log('listForStudent id=${user.id}', name: 'BookingRepository');
    final List<dynamic> rows = await supabase
        .from('booking_requests')
        .select()
        .eq('student_id', user.id)
        .order('created_at', ascending: false);
    return rows
        .cast<Map<String, dynamic>>()
        .map(BookingRequest.fromJson)
        .toList(growable: false);
  }

  /// Lists booking requests where the current user is the mentor.
  Future<List<BookingRequest>> listForMentor() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      return const <BookingRequest>[];
    }
    developer.log('listForMentor id=${user.id}', name: 'BookingRepository');
    final List<dynamic> rows = await supabase
        .from('booking_requests')
        .select()
        .eq('mentor_id', user.id)
        .order('created_at', ascending: false);
    return rows
        .cast<Map<String, dynamic>>()
        .map(BookingRequest.fromJson)
        .toList(growable: false);
  }

  /// Fetches a booking by id. Returns `null` if the row is not visible to
  /// the current user (RLS would have rejected it).
  Future<BookingRequest?> fetchById(String id) async {
    developer.log('fetchById id=$id', name: 'BookingRepository');
    final data = await supabase
        .from('booking_requests')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) {
      return null;
    }
    return BookingRequest.fromJson(data);
  }

  /// Updates the status of a booking (mentor accepts / declines; etc.).
  /// [status] must be one of `pending`, `accepted`, `declined`, `rescheduled`,
  /// `completed`.
  Future<BookingRequest> updateStatus(String id, String status) async {
    developer.log(
      'updateStatus id=$id status=$status',
      name: 'BookingRepository',
    );
    final data = await supabase
        .from('booking_requests')
        .update(<String, dynamic>{'status': status})
        .eq('id', id)
        .select()
        .single();
    return BookingRequest.fromJson(data);
  }
}
