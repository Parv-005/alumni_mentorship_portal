import 'dart:developer' as developer;

import 'package:alumni_mentorship_platform/data/models/forum_post.dart';
import 'package:alumni_mentorship_platform/data/models/forum_reply.dart';
import 'package:alumni_mentorship_platform/data/repositories/forum_repository.dart';
import 'package:flutter/foundation.dart';

/// Drives [ForumPostDetailScreen]. Owns the loaded post and its replies,
/// loading / error state, and the action of adding a new reply.
class ForumPostDetailViewModel extends ChangeNotifier {
  ForumPostDetailViewModel({
    required ForumRepository forumRepository,
    required String postId,
  })
    // ignore: prefer_initializing_formals
    : _forumRepository = forumRepository,
       // ignore: prefer_initializing_formals
       _postId = postId;

  final ForumRepository _forumRepository;
  final String _postId;

  ForumPost? _post;
  List<ForumReply> _replies = const <ForumReply>[];
  bool _loading = false;
  String? _error;
  bool _sending = false;
  String? _sendError;

  /// The currently loaded post, or `null` while loading.
  ForumPost? get post => _post;

  /// The list of replies, oldest first.
  List<ForumReply> get replies => _replies;

  /// True while the initial load is in flight.
  bool get loading => _loading;

  /// Last error message from the initial load.
  String? get error => _error;

  /// True while a new reply is being submitted.
  bool get sending => _sending;

  /// Last error message from the last `addReply` attempt.
  String? get sendError => _sendError;

  /// Loads the post and its replies concurrently.
  Future<void> load() async {
    if (_loading) {
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _forumRepository.fetchPost(_postId),
        _forumRepository.listReplies(_postId),
      ]);
      _post = results[0] as ForumPost?;
      _replies = results[1] as List<ForumReply>;
    } on Object catch (e, st) {
      developer.log('ForumPostDetail load failed', error: e, stackTrace: st);
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Alias for [load] used by pull-to-refresh.
  Future<void> refresh() => load();

  /// Posts a new reply and, on success, appends it to the in-memory list
  /// of replies. Returns `true` on success.
  Future<bool> addReply({required String body, String? parentReplyId}) async {
    if (_sending) {
      return false;
    }
    _sending = true;
    _sendError = null;
    notifyListeners();
    try {
      final ForumReply reply = await _forumRepository.addReply(
        postId: _postId,
        body: body,
        parentReplyId: parentReplyId,
      );
      _replies = <ForumReply>[..._replies, reply];
      return true;
    } on Object catch (e, st) {
      developer.log(
        'ForumPostDetail addReply failed',
        error: e,
        stackTrace: st,
      );
      _sendError = e.toString();
      return false;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }
}
