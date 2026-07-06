// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forum_post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ForumPost _$ForumPostFromJson(Map<String, dynamic> json) => ForumPost(
  id: json['id'] as String,
  authorId: json['author_id'] as String,
  type: json['type'] as String,
  title: json['title'] as String,
  body: json['body'] as String,
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  upvotes: (json['upvotes'] as num).toInt(),
  answered: json['answered'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
  author: json['author'] == null
      ? null
      : UserProfile.fromJson(json['author'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ForumPostToJson(ForumPost instance) => <String, dynamic>{
  'id': instance.id,
  'author_id': instance.authorId,
  'type': instance.type,
  'title': instance.title,
  'body': instance.body,
  'tags': instance.tags,
  'upvotes': instance.upvotes,
  'answered': instance.answered,
  'created_at': instance.createdAt.toIso8601String(),
  'author': instance.author?.toJson(),
};
