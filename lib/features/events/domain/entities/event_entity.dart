import 'package:equatable/equatable.dart';

class EventEntity extends Equatable {
  final int id;
  final String userId;
  final String title;
  final String? description;
  final DateTime eventDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const EventEntity({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.eventDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isExpired => status == 'expired';
  
  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    description,
    eventDate,
    status,
    createdAt,
    updatedAt,
  ];
}
