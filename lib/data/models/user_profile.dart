import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

/// A row in `public.profiles`. One-to-one with an `auth.users` row.
@JsonSerializable(fieldRename: FieldRename.snake)
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.graduationYear,
    this.program,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  final String id;
  final String email;
  final String fullName;

  /// One of `student`, `alumni`, `admin`.
  final String role;

  final int? graduationYear;
  final String? program;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    int? graduationYear,
    String? program,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      graduationYear: graduationYear ?? this.graduationYear,
      program: program ?? this.program,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
