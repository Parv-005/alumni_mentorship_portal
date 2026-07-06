import 'package:json_annotation/json_annotation.dart';

part 'booking_request.g.dart';

/// A row in `public.booking_requests`. Represents a student's request to book
/// a session with a mentor.
@JsonSerializable(fieldRename: FieldRename.snake)
class BookingRequest {
  const BookingRequest({
    required this.id,
    required this.studentId,
    required this.mentorId,
    required this.topic,
    required this.sessionType,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.preferredAt,
  });

  factory BookingRequest.fromJson(Map<String, dynamic> json) =>
      _$BookingRequestFromJson(json);

  final String id;
  final String studentId;
  final String mentorId;
  final String topic;

  /// One of `video`, `in_person`, `async`.
  final String sessionType;
  final DateTime? preferredAt;
  final String message;

  /// One of `pending`, `accepted`, `declined`, `rescheduled`, `completed`.
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$BookingRequestToJson(this);

  BookingRequest copyWith({
    String? id,
    String? studentId,
    String? mentorId,
    String? topic,
    String? sessionType,
    DateTime? preferredAt,
    String? message,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingRequest(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      mentorId: mentorId ?? this.mentorId,
      topic: topic ?? this.topic,
      sessionType: sessionType ?? this.sessionType,
      preferredAt: preferredAt ?? this.preferredAt,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
