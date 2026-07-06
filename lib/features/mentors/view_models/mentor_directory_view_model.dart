import 'dart:async';
import 'dart:developer' as developer;

import 'package:alumni_mentorship_platform/data/models/mentor.dart';
import 'package:alumni_mentorship_platform/data/repositories/mentor_repository.dart';
import 'package:flutter/foundation.dart';

/// Drives the [MentorDirectoryScreen]. Owns the list of mentors, loading /
/// error state, and the active search / domain / availability filters.
class MentorDirectoryViewModel extends ChangeNotifier {
  MentorDirectoryViewModel({required this._mentorRepository});

  final MentorRepository _mentorRepository;

  /// Fixed list of domains surfaced as filter chips in the UI.
  static const List<String> kDomains = <String>[
    'AI/ML',
    'Product',
    'Finance',
    'Engineering',
    'Design',
    'Career',
  ];

  List<Mentor> _mentors = const <Mentor>[];
  bool _loading = false;
  String? _error;
  String _search = '';
  String? _domain;
  bool _availableOnly = false;

  List<Mentor> get mentors => _mentors;
  bool get loading => _loading;
  String? get error => _error;
  String get search => _search;
  String? get domain => _domain;
  bool get availableOnly => _availableOnly;

  /// Loads mentors using the current filter state. Safe to call multiple
  /// times — a request already in flight will be coalesced.
  Future<void> load() async {
    if (_loading) {
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _mentors = await _mentorRepository.list(
        search: _search,
        domain: _domain,
        availability: _availableOnly ? 'accepting' : null,
      );
    } on Object catch (e, st) {
      developer.log('MentorDirectory load failed', error: e, stackTrace: st);
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Alias for [load] used by pull-to-refresh.
  Future<void> refresh() => load();

  void setSearch(String value) {
    if (value == _search) {
      return;
    }
    _search = value;
  }

  void setDomain(String? value) {
    if (value == _domain) {
      return;
    }
    _domain = value;
    notifyListeners();
    unawaited(load());
  }

  void setAvailableOnly(bool value) {
    if (value == _availableOnly) {
      return;
    }
    _availableOnly = value;
    notifyListeners();
    unawaited(load());
  }
}
