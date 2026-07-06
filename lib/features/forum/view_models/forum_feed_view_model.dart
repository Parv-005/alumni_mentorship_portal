import 'dart:developer' as developer;

import 'package:alumni_mentorship_platform/data/models/forum_post.dart';
import 'package:alumni_mentorship_platform/data/repositories/forum_repository.dart';
import 'package:flutter/foundation.dart';

/// Drives [ForumFeedScreen]. Owns the current sort, the loaded list of
/// posts, and the loading / error state. Reloads automatically whenever
/// the sort changes.
class ForumFeedViewModel extends ChangeNotifier {
  ForumFeedViewModel({required ForumRepository forumRepository})
    // ignore: prefer_initializing_formals
    : _forumRepository = forumRepository;

  final ForumRepository _forumRepository;

  static const String sortNewest = 'newest';
  static const String sortUnanswered = 'unanswered';
  static const String sortTop = 'top';

  static const List<String> kSorts = <String>[
    sortNewest,
    sortUnanswered,
    sortTop,
  ];

  List<ForumPost> _posts = const <ForumPost>[];
  String _sort = sortNewest;
  bool _loading = false;
  String? _error;

  /// Currently loaded posts.
  List<ForumPost> get posts => _posts;

  /// Active sort key (`newest`, `unanswered`, or `top`).
  String get sort => _sort;

  /// True while a `listPosts` call is in flight.
  bool get loading => _loading;

  /// Last error message (cleared on the next successful or failed load).
  String? get error => _error;

  /// Loads posts for the current sort. Safe to call multiple times — a
  /// request already in flight will be coalesced.
  Future<void> listPosts([String? sort]) async {
    if (sort != null && sort != _sort) {
      _sort = sort;
    }
    if (_loading) {
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _posts = await _forumRepository.listPosts(sort: _sort);
    } on Object catch (e, st) {
      developer.log('ForumFeed listPosts failed', error: e, stackTrace: st);
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Alias for [listPosts] used by pull-to-refresh.
  Future<void> refresh() => listPosts();

  /// Updates the active sort and reloads.
  Future<void> setSort(String value) => listPosts(value);
}
