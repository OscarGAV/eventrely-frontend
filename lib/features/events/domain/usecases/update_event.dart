import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/event_entity.dart';
import '../repositories/event_repository.dart';

class UpdateEvent implements UseCase<EventEntity, UpdateEventParams> {
  final EventRepository repository;
  
  UpdateEvent(this.repository);
  
  @override
  Future<Either<Failure, EventEntity>> call(UpdateEventParams params) async {
    return await repository.updateEvent(params.eventId, params.event);
  }
}

class UpdateEventParams extends Equatable {
  final int eventId;
  final EventEntity event;
  
  const UpdateEventParams({
    required this.eventId,
    required this.event,
  });
  
  @override
  List<Object> get props => [eventId, event];
}