import 'package:alumni_mentorship_platform/data/models/user_profile.dart';
import 'package:json_annotation/json_annotation.dart';

part 'forum_reply.g.dart';

/// A row in `public.forum_replies`. Single-level threading via
/// [parentReplyId].
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ForumReply {
  const ForumReply({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.body,
    required this.upvotes,
    required this.createdAt,
    this.parentReplyId,
    this.author,
  });

  factory ForumReply.fromJson(Map<String, dynamic> json) =>
      _$ForumReplyFromJson(json);

  final String id;
  final String postId;
  final String authorId;
  final String? parentReplyId;
  final String body;
  final int upvotes;
  final DateTime createdAt;

  /// Optional joined author profile.
  final UserProfile? author;

  Map<String, dynamic> toJson() => _$ForumReplyToJson(this);

  ForumReply copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? parentReplyId,
    String? body,
    int? upvotes,
    DateTime? createdAt,
    UserProfile? author,
  }) {
    return ForumReply(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      parentReplyId: parentReplyId ?? this.parentReplyId,
      body: body ?? this.body,
      upvotes: upvotes ?? this.upvotes,
      createdAt: createdAt ?? this.createdAt,
      author: author ?? this.author,
    );
  }
}
