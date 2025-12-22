import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_remote_datasource.dart';
import '../models/event_model.dart';

class EventRepositoryImpl implements EventRepository {
  final EventRemoteDataSource remoteDataSource;
  
  EventRepositoryImpl({required this.remoteDataSource});
  
  @override
  Future<Either<Failure, EventEntity>> createEvent(EventEntity event) async {
    try {
      final eventModel = EventModel(
        id: 0,
        userId: event.userId,
        title: event.title,
        description: event.description,
        eventDate: event.eventDate,
        status: event.status,
        createdAt: event.createdAt,
        updatedAt: event.updatedAt,
      );
      
      final result = await remoteDataSource.createEvent(eventModel);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }
  
  @override
  Future<Either<Failure, List<EventEntity>>> getUpcomingEvents(String userId) async {
    try {
      final result = await remoteDataSource.getUpcomingEvents(userId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }
  
  @override
  Future<Either<Failure, EventEntity>> getEventById(int eventId) async {
    try {
      final result = await remoteDataSource.getEventById(eventId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }
  
  @override
  Future<Either<Failure, EventEntity>> updateEvent(int eventId, EventEntity event) async {
    try {
      final eventModel = EventModel(
        id: eventId,
        userId: event.userId,
        title: event.title,
        description: event.description,
        eventDate: event.eventDate,
        status: event.status,
        createdAt: event.createdAt,
        updatedAt: event.updatedAt,
      );
      
      final result = await remoteDataSource.updateEvent(eventId, eventModel);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }
  
  @override
  Future<Either<Failure, void>> deleteEvent(int eventId) async {
    try {
      await remoteDataSource.deleteEvent(eventId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }
  
  @override
  Future<Either<Failure, EventEntity>> completeEvent(int eventId) async {
    try {
      final result = await remoteDataSource.completeEvent(eventId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }
  
  @override
  Future<Either<Failure, EventEntity>> cancelEvent(int eventId) async {
    try {
      final result = await remoteDataSource.cancelEvent(eventId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }
}