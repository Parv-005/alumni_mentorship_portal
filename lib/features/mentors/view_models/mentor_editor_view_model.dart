import 'dart:async';
import 'dart:developer' as developer;

import 'package:alumni_mentorship_platform/data/models/mentor.dart';
import 'package:alumni_mentorship_platform/data/repositories/mentor_repository.dart';
import 'package:flutter/foundation.dart';

/// Allowed values for the [Mentor] `availability` field.
const List<String> kAvailabilityOptions = <String>[
  'accepting',
  'booked',
  'break',
];

/// View model for [MentorProfileEditorScreen]. Loads any existing mentor
/// row for the current user, exposes form state, and persists via
/// [MentorRepository.upsertOwn].
class MentorEditorViewModel extends ChangeNotifier {
  MentorEditorViewModel({required this._mentorRepository});

  final MentorRepository _mentorRepository;

  String _domain = '';
  int _experienceYears = 0;
  String _bio = '';
  String _availability = 'accepting';
  String _skillsText = '';
  String _linkedinUrl = '';

  bool _loading = false;
  bool _saving = false;
  String? _error;
  String? _validationError;
  bool _hasExisting = false;

  String get domain => _domain;
  int get experienceYears => _experienceYears;
  String get bio => _bio;
  String get availability => _availability;
  String get skillsText => _skillsText;
  String get linkedinUrl => _linkedinUrl;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;
  String? get validationError => _validationError;
  bool get hasExisting => _hasExisting;

  /// Loads the current user's mentor row, if any, and seeds the form
  /// fields. If no row exists, the form starts with sensible defaults.
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final Mentor? existing = await _mentorRepository.fetchOwnMentorProfile();
      if (existing != null) {
        _hasExisting = true;
        _domain = existing.domain;
        _experienceYears = existing.experienceYears;
        _bio = existing.bio;
        _availability = existing.availability;
        _skillsText = existing.skills.join(', ');
        _linkedinUrl = existing.linkedinUrl ?? '';
      }
    } on Object catch (e, st) {
      developer.log('MentorEditor load failed', error: e, stackTrace: st);
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setDomain(String value) {
    if (value == _domain) {
      return;
    }
    _domain = value;
    _validationError = null;
    notifyListeners();
  }

  void setExperienceYears(int value) {
    if (value == _experienceYears) {
      return;
    }
    _experienceYears = value;
    notifyListeners();
  }

  void setBio(String value) {
    if (value == _bio) {
      return;
    }
    _bio = value;
    _validationError = null;
    notifyListeners();
  }

  void setAvailability(String value) {
    if (value == _availability) {
      return;
    }
    _availability = value;
    notifyListeners();
  }

  void setSkillsText(String value) {
    if (value == _skillsText) {
      return;
    }
    _skillsText = value;
    notifyListeners();
  }

  void setLinkedinUrl(String value) {
    if (value == _linkedinUrl) {
      return;
    }
    _linkedinUrl = value;
    notifyListeners();
  }

  /// Validates the form, persists via [MentorRepository.upsertOwn], and
  /// returns the saved [Mentor] (or `null` on validation / save failure).
  Future<Mentor?> save() async {
    final String domain = _domain.trim();
    final String bio = _bio.trim();
    if (domain.isEmpty) {
      _validationError = 'Please enter a domain (e.g. "Engineering").';
      notifyListeners();
      return null;
    }
    if (bio.isEmpty) {
      _validationError = 'Please share a short bio.';
      notifyListeners();
      return null;
    }
    if (_experienceYears < 0) {
      _validationError = 'Experience years cannot be negative.';
      notifyListeners();
      return null;
    }

    final List<String> skills = _skillsText
        .split(',')
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList(growable: false);

    _saving = true;
    _error = null;
    _validationError = null;
    notifyListeners();

    try {
      final Mentor draft = Mentor(
        id: '',
        domain: domain,
        experienceYears: _experienceYears,
        bio: bio,
        availability: _availability,
        skills: skills,
        isFeatured: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        linkedinUrl: _linkedinUrl.trim().isEmpty ? null : _linkedinUrl.trim(),
      );
      final Mentor saved = await _mentorRepository.upsertOwn(draft);
      _hasExisting = true;
      return saved;
    } on Object catch (e, st) {
      developer.log('MentorEditor save failed', error: e, stackTrace: st);
      _error = e.toString();
      return null;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
