import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/event_entity.dart';
import '../repositories/event_repository.dart';

class GetUpcomingEvents implements UseCase<List<EventEntity>, GetUpcomingEventsParams> {
  final EventRepository repository;
  
  GetUpcomingEvents(this.repository);
  
  @override
  Future<Either<Failure, List<EventEntity>>> call(GetUpcomingEventsParams params) async {
    return await repository.getUpcomingEvents(params.userId);
  }
}

class GetUpcomingEventsParams extends Equatable {
  final String userId;
  
  const GetUpcomingEventsParams({required this.userId});
  
  @override
  List<Object> get props => [userId];
}