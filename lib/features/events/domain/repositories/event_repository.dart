import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/event_entity.dart';

abstract class EventRepository {
  Future<Either<Failure, EventEntity>> createEvent(EventEntity event);
  Future<Either<Failure, List<EventEntity>>> getUpcomingEvents(String userId);
  Future<Either<Failure, EventEntity>> getEventById(int eventId);
  Future<Either<Failure, EventEntity>> updateEvent(int eventId, EventEntity event);
  Future<Either<Failure, void>> deleteEvent(int eventId);
  Future<Either<Failure, EventEntity>> completeEvent(int eventId);
  Future<Either<Failure, EventEntity>> cancelEvent(int eventId);
}