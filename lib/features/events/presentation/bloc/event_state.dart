import 'package:equatable/equatable.dart';
import '../../domain/entities/event_entity.dart';

abstract class EventState extends Equatable {
  @override
  List<Object?> get props => [];
}

class EventInitial extends EventState {}

class EventLoading extends EventState {}

class EventsLoaded extends EventState {
  final List<EventEntity> events;
  
  EventsLoaded(this.events);
  
  @override
  List<Object> get props => [events];
}

class EventOperationSuccess extends EventState {
  final String message;
  final EventEntity? event;
  
  EventOperationSuccess(this.message, {this.event});
  
  @override
  List<Object?> get props => [message, event];
}

class EventError extends EventState {
  final String message;
  
  EventError(this.message);
  
  @override
  List<Object> get props => [message];
}