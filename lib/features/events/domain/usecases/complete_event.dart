import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/event_entity.dart';
import '../repositories/event_repository.dart';

class CompleteEvent implements UseCase<EventEntity, CompleteEventParams> {
  final EventRepository repository;
  
  CompleteEvent(this.repository);
  
  @override
  Future<Either<Failure, EventEntity>> call(CompleteEventParams params) async {
    return await repository.completeEvent(params.eventId);
  }
}

class CompleteEventParams extends Equatable {
  final int eventId;
  
  const CompleteEventParams({required this.eventId});
  
  @override
  List<Object> get props => [eventId];
}