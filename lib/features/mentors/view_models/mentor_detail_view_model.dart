import 'dart:developer' as developer;

import 'package:alumni_mentorship_platform/data/models/mentor.dart';
import 'package:alumni_mentorship_platform/data/repositories/mentor_repository.dart';
import 'package:flutter/foundation.dart';

/// View model for [MentorDetailScreen]. Loads a single mentor by id.
class MentorDetailViewModel extends ChangeNotifier {
  MentorDetailViewModel({
    required this._mentorRepository,
    required this.mentorId,
  });

  final MentorRepository _mentorRepository;
  final String mentorId;

  Mentor? _mentor;
  bool _loading = false;
  String? _error;

  Mentor? get mentor => _mentor;
  bool get loading => _loading;
  String? get error => _error;

  /// True when the mentor is currently accepting session requests.
  bool get isAccepting => _mentor?.availability == 'accepting';

  /// Fetches (or re-fetches) the mentor record. Sets [error] if the record
  /// is missing or the underlying call throws.
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final Mentor? result = await _mentorRepository.fetchById(mentorId);
      if (result == null) {
        _error = 'Mentor not found.';
      } else {
        _mentor = result;
      }
    } on Object catch (e, st) {
      developer.log('MentorDetail load failed', error: e, stackTrace: st);
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();
}

