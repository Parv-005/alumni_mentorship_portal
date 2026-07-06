import 'package:alumni_mentorship_platform/data/models/user_profile.dart';
import 'package:json_annotation/json_annotation.dart';

part 'forum_post.g.dart';

/// A row in `public.forum_posts`. May include a nested author profile.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ForumPost {
  const ForumPost({
    required this.id,
    required this.authorId,
    required this.type,
    required this.title,
    required this.body,
    required this.tags,
    required this.upvotes,
    required this.answered,
    required this.createdAt,
    this.author,
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) =>
      _$ForumPostFromJson(json);

  final String id;
  final String authorId;

  /// One of `question`, `insight`, `discussion`.
  final String type;
  final String title;
  final String body;
  final List<String> tags;
  final int upvotes;
  final bool answered;
  final DateTime createdAt;

  /// Optional joined author profile (e.g. `author:profiles(...)`).
  final UserProfile? author;

  Map<String, dynamic> toJson() => _$ForumPostToJson(this);

  ForumPost copyWith({
    String? id,
    String? authorId,
    String? type,
    String? title,
    String? body,
    List<String>? tags,
    int? upvotes,
    bool? answered,
    DateTime? createdAt,
    UserProfile? author,
  }) {
    return ForumPost(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      tags: tags ?? this.tags,
      upvotes: upvotes ?? this.upvotes,
      answered: answered ?? this.answered,
      createdAt: createdAt ?? this.createdAt,
      author: author ?? this.author,
    );
  }
}
