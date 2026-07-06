import 'dart:developer' as developer;

import 'package:alumni_mentorship_platform/data/models/booking_request.dart';
import 'package:alumni_mentorship_platform/data/models/forum_post.dart';
import 'package:alumni_mentorship_platform/data/repositories/booking_repository.dart';
import 'package:alumni_mentorship_platform/data/repositories/forum_repository.dart';
import 'package:alumni_mentorship_platform/data/repositories/mentor_repository.dart';
import 'package:flutter/foundation.dart';

/// View model that powers the role-aware dashboard. Loads upcoming / incoming
/// bookings and recent forum posts in a single `load()` call.
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({
    BookingRepository? bookingRepository,
    ForumRepository? forumRepository,
    MentorRepository? mentorRepository,
  }) : _bookingRepository = bookingRepository ?? const BookingRepository(),
       _forumRepository = forumRepository ?? const ForumRepository(),
       _mentorRepository = mentorRepository ?? const MentorRepository();

  final BookingRepository _bookingRepository;
  final ForumRepository _forumRepository;
  final MentorRepository _mentorRepository;

  bool _loading = false;
  String? _error;
  List<BookingRequest> _studentBookings = const <BookingRequest>[];
  List<BookingRequest> _mentorBookings = const <BookingRequest>[];
  List<ForumPost> _recentPosts = const <ForumPost>[];
  bool _isMentor = false;
  int _mentorCount = 0;

  bool get loading => _loading;
  String? get error => _error;

  /// Bookings the current user made as a student.
  List<BookingRequest> get studentBookings => _studentBookings;

  /// Bookings where the current user is the mentor.
  List<BookingRequest> get mentorBookings => _mentorBookings;

  /// Most recent forum posts (any sort).
  List<ForumPost> get recentPosts => _recentPosts;

  /// True when the signed-in user has a mentor profile.
  bool get isMentor => _isMentor;

  /// Total mentor count (used for admin dashboard).
  int get mentorCount => _mentorCount;

  /// Number of incoming booking requests still in `pending` status.
  int get pendingMentorRequestCount =>
      _mentorBookings.where((BookingRequest b) => b.status == 'pending').length;

  /// Number of the user's own bookings that are awaiting mentor action.
  int get pendingStudentRequestCount => _studentBookings
      .where((BookingRequest b) => b.status == 'pending')
      .length;

  /// Loads all dashboard data. Safe to call repeatedly.
  Future<void> load({required String role}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final Future<List<BookingRequest>> studentFuture = _bookingRepository
          .listForStudent();
      final Future<List<BookingRequest>> mentorFuture = _bookingRepository
          .listForMentor();
      final Future<List<ForumPost>> postsFuture = _forumRepository.listPosts(
        sort: 'newest',
      );
      final Future<List<dynamic>> mentorListFuture = _mentorRepository.list();

      final results = await Future.wait(<Future<dynamic>>[
        studentFuture,
        mentorFuture,
        postsFuture,
        mentorListFuture,
      ]);

      _studentBookings = results[0] as List<BookingRequest>;
      _mentorBookings = results[1] as List<BookingRequest>;
      _recentPosts = results[2] as List<ForumPost>;
      final mentorList = results[3] as List<dynamic>;
      _mentorCount = mentorList.length;
      _isMentor = role == 'alumni';
    } on Object catch (e, st) {
      developer.log('Dashboard load error', error: e, stackTrace: st);
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
