import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_event.dart';
import '../../domain/usecases/get_upcoming_events.dart';
import '../../domain/usecases/update_event.dart';
import '../../domain/usecases/delete_event.dart';
import '../../domain/usecases/complete_event.dart';
import '../../../../core/utils/notification_utils.dart';
import 'event_event.dart';
import 'event_state.dart';

class EventBloc extends Bloc<EventEvent, EventState> {
  final GetUpcomingEvents getUpcomingEvents;
  final CreateEvent createEvent;
  final UpdateEvent updateEvent;
  final DeleteEvent deleteEvent;
  final CompleteEvent completeEvent;
  
  EventBloc({
    required this.getUpcomingEvents,
    required this.createEvent,
    required this.updateEvent,
    required this.deleteEvent,
    required this.completeEvent,
  }) : super(EventInitial()) {
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
    
    final result = await getUpcomingEvents(
      GetUpcomingEventsParams(userId: event.userId),
    );
    
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
    
    final result = await createEvent(
      CreateEventParams(event: event.event),
    );
    
    await result.fold(
      (failure) async => emit(EventError(failure.message)),
      (createdEvent) async {
        // Programar notificaciones
        await NotificationUtils.scheduleEventReminders(createdEvent);
        
        emit(EventOperationSuccess(
          'Evento creado exitosamente',
          event: createdEvent,
        ));
      },
    );
  }
  
  Future<void> _onUpdateEventRequested(
    UpdateEventRequested event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    
    final result = await updateEvent(
      UpdateEventParams(
        eventId: event.eventId,
        event: event.event,
      ),
    );
    
    await result.fold(
      (failure) async => emit(EventError(failure.message)),
      (updatedEvent) async {
        // Re-programar notificaciones
        await NotificationUtils.scheduleEventReminders(updatedEvent);
        
        emit(EventOperationSuccess(
          'Evento actualizado exitosamente',
          event: updatedEvent,
        ));
      },
    );
  }
  
  Future<void> _onDeleteEventRequested(
    DeleteEventRequested event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    
    final result = await deleteEvent(
      DeleteEventParams(eventId: event.eventId),
    );
    
    await result.fold(
      (failure) async => emit(EventError(failure.message)),
      (_) async {
        // Cancelar notificaciones
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
    
    final result = await completeEvent(
      CompleteEventParams(eventId: event.eventId),
    );
    
    await result.fold(
      (failure) async => emit(EventError(failure.message)),
      (completedEvent) async {
        // Cancelar notificaciones
        await NotificationUtils.cancelEventReminders(event.eventId);
        
        emit(EventOperationSuccess(
          'Evento completado',
          event: completedEvent,
        ));
      },
    );
  }
}