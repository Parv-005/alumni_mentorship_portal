import 'dart:async';
import 'dart:developer' as developer;

import 'package:alumni_mentorship_platform/data/models/mentor.dart';
import 'package:alumni_mentorship_platform/data/repositories/booking_repository.dart';
import 'package:alumni_mentorship_platform/data/repositories/mentor_repository.dart';
import 'package:flutter/foundation.dart';

/// Session type values mapped 1:1 to the SQL `booking_requests.session_type`
/// check constraint. Exposed as a static list for the UI choice chips.
const List<String> kSessionTypes = <String>['video', 'in_person', 'async'];

/// View model for the [BookingRequestScreen]. Loads the target mentor (for
/// name display), owns the form fields, and calls
/// [BookingRepository.create] when the user submits.
class BookingRequestViewModel extends ChangeNotifier {
  BookingRequestViewModel({
    required this.mentorId,
    BookingRepository? bookingRepository,
    MentorRepository? mentorRepository,
  }) : _bookingRepository = bookingRepository ?? const BookingRepository(),
       _mentorRepository = mentorRepository ?? const MentorRepository() {
    unawaited(_loadMentor());
  }

  final String mentorId;
  final BookingRepository _bookingRepository;
  final MentorRepository _mentorRepository;

  Mentor? _mentor;
  bool _mentorLoading = true;
  String? _mentorError;

  String _topic = '';
  String _sessionType = 'video';
  DateTime? _preferredAt;
  String _message = '';

  bool _submitting = false;
  String? _submitError;
  bool _success = false;

  Mentor? get mentor => _mentor;
  bool get mentorLoading => _mentorLoading;
  String? get mentorError => _mentorError;

  String get topic => _topic;
  String get sessionType => _sessionType;
  DateTime? get preferredAt => _preferredAt;
  String get message => _message;

  bool get submitting => _submitting;
  String? get submitError => _submitError;
  bool get success => _success;

  /// True when [topic] has non-whitespace content and no submit is in flight.
  bool get canSubmit => _topic.trim().isNotEmpty && !_submitting;

  void setTopic(String value) {
    if (value == _topic) {
      return;
    }
    _topic = value;
    notifyListeners();
  }

  void setSessionType(String value) {
    if (value == _sessionType) {
      return;
    }
    _sessionType = value;
    notifyListeners();
  }

  void setPreferredAt(DateTime? value) {
    if (value == _preferredAt) {
      return;
    }
    _preferredAt = value;
    notifyListeners();
  }

  void setMessage(String value) {
    if (value == _message) {
      return;
    }
    _message = value;
    notifyListeners();
  }

  Future<void> _loadMentor() async {
    _mentorLoading = true;
    _mentorError = null;
    notifyListeners();
    try {
      _mentor = await _mentorRepository.fetchById(mentorId);
      if (_mentor == null) {
        _mentorError = 'Mentor not found';
      }
    } on Object catch (e, st) {
      developer.log(
        'BookingRequest load mentor failed',
        error: e,
        stackTrace: st,
      );
      _mentorError = e.toString();
    } finally {
      _mentorLoading = false;
      notifyListeners();
    }
  }

  /// Submits the booking request. On success, [success] flips to `true`.
  Future<void> submit() async {
    if (!canSubmit) {
      return;
    }
    _submitting = true;
    _submitError = null;
    notifyListeners();
    try {
      await _bookingRepository.create(
        mentorId: mentorId,
        topic: _topic.trim(),
        sessionType: _sessionType,
        preferredAt: _preferredAt,
        message: _message.trim().isEmpty ? null : _message.trim(),
      );
      _success = true;
    } on Object catch (e, st) {
      developer.log('BookingRequest submit failed', error: e, stackTrace: st);
      _submitError = e.toString();
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
