import 'package:equatable/equatable.dart';
import '../../domain/entities/event_entity.dart';

abstract class EventEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadUpcomingEvents extends EventEvent {
  final String userId;
  
  LoadUpcomingEvents(this.userId);
  
  @override
  List<Object> get props => [userId];
}

class CreateEventRequested extends EventEvent {
  final EventEntity event;
  
  CreateEventRequested(this.event);
  
  @override
  List<Object> get props => [event];
}

class UpdateEventRequested extends EventEvent {
  final int eventId;
  final EventEntity event;
  
  UpdateEventRequested(this.eventId, this.event);
  
  @override
  List<Object> get props => [eventId, event];
}

class DeleteEventRequested extends EventEvent {
  final int eventId;
  
  DeleteEventRequested(this.eventId);
  
  @override
  List<Object> get props => [eventId];
}

class CompleteEventRequested extends EventEvent {
  final int eventId;
  
  CompleteEventRequested(this.eventId);
  
  @override
  List<Object> get props => [eventId];
}

class CancelEventRequested extends EventEvent {
  final int eventId;
  
  CancelEventRequested(this.eventId);
  
  @override
  List<Object> get props => [eventId];
}