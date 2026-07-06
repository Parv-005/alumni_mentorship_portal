import 'dart:developer' as developer;

import 'package:alumni_mentorship_platform/data/repositories/forum_repository.dart';
import 'package:flutter/foundation.dart';

/// Drives [ForumComposeScreen]. Owns the form fields for a new forum post
/// and submits them via [ForumRepository.createPost].
class ForumComposeViewModel extends ChangeNotifier {
  ForumComposeViewModel({required ForumRepository forumRepository})
    // ignore: prefer_initializing_formals
    : _forumRepository = forumRepository;

  final ForumRepository _forumRepository;

  /// Allowed post types shown as choice chips in the form.
  static const List<String> kTypes = <String>[
    'question',
    'insight',
    'discussion',
  ];

  static const Map<String, String> kTypeLabels = <String, String>{
    'question': 'Question',
    'insight': 'Insight',
    'discussion': 'Discussion',
  };

  String _type = 'question';
  String _title = '';
  String _body = '';
  String _tagsText = '';
  bool _loading = false;
  String? _error;
  bool _success = false;

  String get type => _type;
  String get title => _title;
  String get body => _body;
  String get tagsText => _tagsText;
  bool get loading => _loading;
  String? get error => _error;

  /// `true` after a successful submission, until cleared.
  bool get success => _success;

  void setType(String value) {
    if (value == _type) {
      return;
    }
    _type = value;
    notifyListeners();
  }

  void setTitle(String value) {
    if (value == _title) {
      return;
    }
    _title = value;
    notifyListeners();
  }

  void setBody(String value) {
    if (value == _body) {
      return;
    }
    _body = value;
    notifyListeners();
  }

  void setTagsText(String value) {
    if (value == _tagsText) {
      return;
    }
    _tagsText = value;
    notifyListeners();
  }

  /// Returns `true` when the form has a non-empty title and body.
  bool get isValid => _title.trim().isNotEmpty && _body.trim().isNotEmpty;

  /// Parses the comma-separated tag text into a clean list of tags.
  List<String> get _parsedTags {
    return _tagsText
        .split(',')
        .map((String t) => t.trim())
        .where((String t) => t.isNotEmpty)
        .toList(growable: false);
  }

  /// Submits the post. Returns `true` on success.
  Future<bool> submit() async {
    if (_loading || !isValid) {
      return false;
    }
    _loading = true;
    _error = null;
    _success = false;
    notifyListeners();
    try {
      await _forumRepository.createPost(
        type: _type,
        title: _title.trim(),
        body: _body.trim(),
        tags: _parsedTags,
      );
      _success = true;
      return true;
    } on Object catch (e, st) {
      developer.log('ForumCompose submit failed', error: e, stackTrace: st);
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
