// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingRequest _$BookingRequestFromJson(Map<String, dynamic> json) =>
    BookingRequest(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      mentorId: json['mentor_id'] as String,
      topic: json['topic'] as String,
      sessionType: json['session_type'] as String,
      message: json['message'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      preferredAt: json['preferred_at'] == null
          ? null
          : DateTime.parse(json['preferred_at'] as String),
    );

Map<String, dynamic> _$BookingRequestToJson(BookingRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'student_id': instance.studentId,
      'mentor_id': instance.mentorId,
      'topic': instance.topic,
      'session_type': instance.sessionType,
      'preferred_at': instance.preferredAt?.toIso8601String(),
      'message': instance.message,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
