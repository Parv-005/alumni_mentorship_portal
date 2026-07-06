import 'dart:developer' as developer;

import 'package:alumni_mentorship_platform/data/models/booking_request.dart';
import 'package:alumni_mentorship_platform/data/models/mentor.dart';
import 'package:alumni_mentorship_platform/data/models/user_profile.dart';
import 'package:alumni_mentorship_platform/data/repositories/booking_repository.dart';
import 'package:alumni_mentorship_platform/data/repositories/mentor_repository.dart';
import 'package:alumni_mentorship_platform/data/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';

/// View model for the [BookingDetailScreen]. Fetches a single booking by id
/// and resolves the related mentor / student profile for display.
class BookingDetailViewModel extends ChangeNotifier {
  BookingDetailViewModel({
    required this.bookingId,
    BookingRepository? bookingRepository,
    MentorRepository? mentorRepository,
    ProfileRepository? profileRepository,
  }) : _bookingRepository = bookingRepository ?? const BookingRepository(),
       _mentorRepository = mentorRepository ?? const MentorRepository(),
       _profileRepository = profileRepository ?? const ProfileRepository();

  final String bookingId;
  final BookingRepository _bookingRepository;
  final MentorRepository _mentorRepository;
  final ProfileRepository _profileRepository;

  BookingRequest? _booking;
  Mentor? _mentor;
  UserProfile? _student;
  bool _loading = false;
  String? _error;
  bool _updating = false;
  String? _updateError;

  BookingRequest? get booking => _booking;
  Mentor? get mentor => _mentor;
  UserProfile? get student => _student;
  bool get loading => _loading;
  String? get error => _error;
  bool get updating => _updating;
  String? get updateError => _updateError;

  /// Loads the booking + counterparty profiles. Coalesces concurrent loads.
  Future<void> load() async {
    if (_loading) {
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final BookingRequest? fetched = await _bookingRepository.fetchById(
        bookingId,
      );
      if (fetched == null) {
        _error = 'Booking not found';
        return;
      }
      _booking = fetched;
      final List<Future<void>> related = <Future<void>>[
        _loadMentor(fetched.mentorId),
        _loadStudent(fetched.studentId),
      ];
      await Future.wait(related);
    } on Object catch (e, st) {
      developer.log('BookingDetail load failed', error: e, stackTrace: st);
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadMentor(String id) async {
    try {
      _mentor = await _mentorRepository.fetchById(id);
    } on Object catch (e, st) {
      developer.log(
        'BookingDetail load mentor failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _loadStudent(String id) async {
    try {
      _student = await _profileRepository.fetchById(id);
    } on Object catch (e, st) {
      developer.log(
        'BookingDetail load student failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Updates the booking status. [status] must be one of
  /// `pending|accepted|declined|rescheduled|completed`.
  Future<bool> updateStatus(String status) async {
    if (_updating || _booking == null) {
      return false;
    }
    _updating = true;
    _updateError = null;
    notifyListeners();
    try {
      _booking = await _bookingRepository.updateStatus(_booking!.id, status);
      return true;
    } on Object catch (e, st) {
      developer.log(
        'BookingDetail updateStatus failed',
        error: e,
        stackTrace: st,
      );
      _updateError = e.toString();
      return false;
    } finally {
      _updating = false;
      notifyListeners();
    }
  }
}
