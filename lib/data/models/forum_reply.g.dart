// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forum_reply.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ForumReply _$ForumReplyFromJson(Map<String, dynamic> json) => ForumReply(
  id: json['id'] as String,
  postId: json['post_id'] as String,
  authorId: json['author_id'] as String,
  body: json['body'] as String,
  upvotes: (json['upvotes'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  parentReplyId: json['parent_reply_id'] as String?,
  author: json['author'] == null
      ? null
      : UserProfile.fromJson(json['author'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ForumReplyToJson(ForumReply instance) =>
    <String, dynamic>{
      'id': instance.id,
      'post_id': instance.postId,
      'author_id': instance.authorId,
      'parent_reply_id': instance.parentReplyId,
      'body': instance.body,
      'upvotes': instance.upvotes,
      'created_at': instance.createdAt.toIso8601String(),
      'author': instance.author?.toJson(),
    };
