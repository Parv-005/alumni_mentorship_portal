// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mentor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Mentor _$MentorFromJson(Map<String, dynamic> json) => Mentor(
  id: json['id'] as String,
  domain: json['domain'] as String,
  experienceYears: (json['experience_years'] as num).toInt(),
  bio: json['bio'] as String,
  availability: json['availability'] as String,
  skills: (json['skills'] as List<dynamic>).map((e) => e as String).toList(),
  isFeatured: json['is_featured'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  linkedinUrl: json['linkedin_url'] as String?,
  profile: json['profiles'] == null
      ? null
      : UserProfile.fromJson(json['profiles'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MentorToJson(Mentor instance) => <String, dynamic>{
  'id': instance.id,
  'domain': instance.domain,
  'experience_years': instance.experienceYears,
  'bio': instance.bio,
  'availability': instance.availability,
  'skills': instance.skills,
  'linkedin_url': instance.linkedinUrl,
  'is_featured': instance.isFeatured,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'profiles': instance.profile?.toJson(),
};
