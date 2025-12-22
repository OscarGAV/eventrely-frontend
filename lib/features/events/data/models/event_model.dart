import '../../domain/entities/event_entity.dart';
import '../../../../core/utils/date_utils.dart';

class EventModel extends EventEntity {
  const EventModel({
    required super.id,
    required super.userId,
    required super.title,
    super.description,
    required super.eventDate,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  });
  
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      eventDate: DateTimeUtils.parseUtcDate(json['event_date']),
      status: json['status'],
      createdAt: DateTimeUtils.parseUtcDate(json['created_at']),
      updatedAt: DateTimeUtils.parseUtcDate(json['updated_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'event_date': eventDate.toIso8601String(),
    };
  }
  
  Map<String, dynamic> toUpdateJson() {
    final map = <String, dynamic>{};
    if (title.isNotEmpty) map['title'] = title;
    if (description != null) map['description'] = description;
    map['event_date'] = eventDate.toIso8601String();
    return map;
  }
}