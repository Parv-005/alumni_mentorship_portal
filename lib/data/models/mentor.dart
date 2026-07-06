import 'package:alumni_mentorship_platform/data/models/user_profile.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mentor.g.dart';

/// A row in `public.mentors`, optionally joined with the mentor's
/// [UserProfile]. The repository selects `*, profiles!inner(*)` so the nested
/// profile is available in [profile].
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Mentor {
  const Mentor({
    required this.id,
    required this.domain,
    required this.experienceYears,
    required this.bio,
    required this.availability,
    required this.skills,
    required this.isFeatured,
    required this.createdAt,
    required this.updatedAt,
    this.linkedinUrl,
    this.profile,
  });

  factory Mentor.fromJson(Map<String, dynamic> json) => _$MentorFromJson(json);

  final String id;
  final String domain;
  final int experienceYears;
  final String bio;

  /// One of `accepting`, `booked`, `break`.
  final String availability;
  final List<String> skills;
  final String? linkedinUrl;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Nested profile (selected via `profiles!inner(*)`). May be null in tests
  /// or when the join is not used.
  @JsonKey(name: 'profiles')
  final UserProfile? profile;

  Map<String, dynamic> toJson() => _$MentorToJson(this);

  Mentor copyWith({
    String? id,
    String? domain,
    int? experienceYears,
    String? bio,
    String? availability,
    List<String>? skills,
    String? linkedinUrl,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserProfile? profile,
  }) {
    return Mentor(
      id: id ?? this.id,
      domain: domain ?? this.domain,
      experienceYears: experienceYears ?? this.experienceYears,
      bio: bio ?? this.bio,
      availability: availability ?? this.availability,
      skills: skills ?? this.skills,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profile: profile ?? this.profile,
    );
  }
}
