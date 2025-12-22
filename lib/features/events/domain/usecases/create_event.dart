import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/event_entity.dart';
import '../repositories/event_repository.dart';

class CreateEvent implements UseCase<EventEntity, CreateEventParams> {
  final EventRepository repository;
  
  CreateEvent(this.repository);
  
  @override
  Future<Either<Failure, EventEntity>> call(CreateEventParams params) async {
    return await repository.createEvent(params.event);
  }
}

class CreateEventParams extends Equatable {
  final EventEntity event;
  
  const CreateEventParams({required this.event});
  
  @override
  List<Object> get props => [event];
}