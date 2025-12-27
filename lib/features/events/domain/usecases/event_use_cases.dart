// event_use_cases.dart
import 'package:dartz/dartz.dart';
import '../entities/event_entity.dart';
import '../repositories/event_repository.dart';
import '../../../../core/error/failures.dart';

class EventUseCases {
  final EventRepository repository;
  
  EventUseCases(this.repository);
  
  Future<Either<Failure, List<EventEntity>>> getUpcomingEvents(String userId) =>
      repository.getUpcomingEvents(userId);
  
  Future<Either<Failure, EventEntity>> createEvent(EventEntity event) =>
      repository.createEvent(event);
  
  Future<Either<Failure, EventEntity>> updateEvent(int eventId, EventEntity event) =>
      repository.updateEvent(eventId, event);
  
  Future<Either<Failure, void>> deleteEvent(int eventId) =>
      repository.deleteEvent(eventId);
  
  Future<Either<Failure, EventEntity>> completeEvent(int eventId) =>
      repository.completeEvent(eventId);
  
  Future<Either<Failure, EventEntity>> cancelEvent(int eventId) =>
      repository.cancelEvent(eventId);
}