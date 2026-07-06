import 'dart:developer' as developer;

import 'package:alumni_mentorship_platform/core/supabase/supabase_client.dart';
import 'package:alumni_mentorship_platform/data/models/forum_post.dart';
import 'package:alumni_mentorship_platform/data/models/forum_reply.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for `public.forum_posts` and `public.forum_replies`.
class ForumRepository {
  const ForumRepository();

  /// Lists forum posts. [sort] may be `newest`, `unanswered`, or `top`.
  /// Each result includes the joined `author:profiles(*)` profile when the
  /// caller is authenticated.
  Future<List<ForumPost>> listPosts({String sort = 'newest'}) async {
    developer.log('listPosts sort=$sort', name: 'ForumRepository');
    final PostgrestTransformBuilder<PostgrestList> query = switch (sort) {
      'top' =>
        supabase
            .from('forum_posts')
            .select('*, author:profiles!forum_posts_author_id_fkey(*)')
            .order('upvotes', ascending: false),
      'unanswered' =>
        supabase
            .from('forum_posts')
            .select('*, author:profiles!forum_posts_author_id_fkey(*)')
            .eq('answered', false)
            .order('created_at', ascending: false),
      _ =>
        supabase
            .from('forum_posts')
            .select('*, author:profiles!forum_posts_author_id_fkey(*)')
            .order('created_at', ascending: false),
    };

    final List<dynamic> rows = await query;
    return rows
        .cast<Map<String, dynamic>>()
        .map(ForumPost.fromJson)
        .toList(growable: false);
  }

  /// Fetches a single post including the joined author profile.
  Future<ForumPost?> fetchPost(String id) async {
    developer.log('fetchPost id=$id', name: 'ForumRepository');
    final data = await supabase
        .from('forum_posts')
        .select('*, author:profiles!forum_posts_author_id_fkey(*)')
        .eq('id', id)
        .maybeSingle();
    if (data == null) {
      return null;
    }
    return ForumPost.fromJson(data);
  }

  /// Creates a forum post on behalf of the current user.
  Future<ForumPost> createPost({
    required String type,
    required String title,
    required String body,
    List<String> tags = const <String>[],
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Cannot create a post when not signed in');
    }
    developer.log('createPost type=$type', name: 'ForumRepository');
    final Map<String, dynamic> values = <String, dynamic>{
      'author_id': user.id,
      'type': type,
      'title': title,
      'body': body,
      'tags': tags,
    };
    final data = await supabase
        .from('forum_posts')
        .insert(values)
        .select('*, author:profiles!forum_posts_author_id_fkey(*)')
        .single();
    return ForumPost.fromJson(data);
  }

  /// Lists replies for a post, oldest first. Each reply includes the joined
  /// author profile.
  Future<List<ForumReply>> listReplies(String postId) async {
    developer.log('listReplies postId=$postId', name: 'ForumRepository');
    final List<dynamic> rows = await supabase
        .from('forum_replies')
        .select('*, author:profiles!forum_replies_author_id_fkey(*)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);
    return rows
        .cast<Map<String, dynamic>>()
        .map(ForumReply.fromJson)
        .toList(growable: false);
  }

  /// Adds a reply to a post. [parentReplyId] enables single-level threading.
  Future<ForumReply> addReply({
    required String postId,
    required String body,
    String? parentReplyId,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Cannot reply when not signed in');
    }
    developer.log('addReply postId=$postId', name: 'ForumRepository');
    final Map<String, dynamic> values = <String, dynamic>{
      'post_id': postId,
      'author_id': user.id,
      'body': body,
      // ignore: use_null_aware_elements
      if (parentReplyId != null) 'parent_reply_id': parentReplyId,
    };
    final data = await supabase
        .from('forum_replies')
        .insert(values)
        .select('*, author:profiles!forum_replies_author_id_fkey(*)')
        .single();
    return ForumReply.fromJson(data);
  }
}
