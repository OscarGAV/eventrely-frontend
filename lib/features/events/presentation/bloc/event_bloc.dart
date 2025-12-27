// event_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/event_use_cases.dart';
import '../../../../core/utils/notification_utils.dart';
import 'event_event.dart';
import 'event_state.dart';

class EventBloc extends Bloc<EventEvent, EventState> {
  final EventUseCases useCases;
  
  EventBloc({required this.useCases}) : super(EventInitial()) {
    on<LoadUpcomingEvents>(_onLoadUpcomingEvents);
    on<CreateEventRequested>(_onCreateEventRequested);
    on<UpdateEventRequested>(_onUpdateEventRequested);
    on<DeleteEventRequested>(_onDeleteEventRequested);
    on<CompleteEventRequested>(_onCompleteEventRequested);
  }
  
  Future<void> _onLoadUpcomingEvents(
    LoadUpcomingEvents event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    final result = await useCases.getUpcomingEvents(event.userId);
    result.fold(
      (failure) => emit(EventError(failure.message)),
      (events) => emit(EventsLoaded(events)),
    );
  }
  
  Future<void> _onCreateEventRequested(
    CreateEventRequested event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    final result = await useCases.createEvent(event.event);
    await result.fold(
      (failure) async => emit(EventError(failure.message)),
      (createdEvent) async {
        await NotificationUtils.scheduleEventReminders(createdEvent);
        emit(EventOperationSuccess('Evento creado exitosamente', event: createdEvent));
      },
    );
  }
  
  Future<void> _onUpdateEventRequested(
    UpdateEventRequested event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    final result = await useCases.updateEvent(event.eventId, event.event);
    await result.fold(
      (failure) async => emit(EventError(failure.message)),
      (updatedEvent) async {
        await NotificationUtils.scheduleEventReminders(updatedEvent);
        emit(EventOperationSuccess('Evento actualizado exitosamente', event: updatedEvent));
      },
    );
  }
  
  Future<void> _onDeleteEventRequested(
    DeleteEventRequested event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    final result = await useCases.deleteEvent(event.eventId);
    await result.fold(
      (failure) async => emit(EventError(failure.message)),
      (_) async {
        await NotificationUtils.cancelEventReminders(event.eventId);
        emit(EventOperationSuccess('Evento eliminado exitosamente'));
      },
    );
  }
  
  Future<void> _onCompleteEventRequested(
    CompleteEventRequested event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    final result = await useCases.completeEvent(event.eventId);
    await result.fold(
      (failure) async => emit(EventError(failure.message)),
      (completedEvent) async {
        await NotificationUtils.cancelEventReminders(event.eventId);
        emit(EventOperationSuccess('Evento completado', event: completedEvent));
      },
    );
  }
}