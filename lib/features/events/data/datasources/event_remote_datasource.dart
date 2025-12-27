import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/event_model.dart';

abstract class EventRemoteDataSource {
  Future<EventModel> createEvent(EventModel event);
  Future<List<EventModel>> getUpcomingEvents(String userId);
  Future<EventModel> getEventById(int eventId);
  Future<EventModel> updateEvent(int eventId, EventModel event);
  Future<void> deleteEvent(int eventId);
  Future<EventModel> completeEvent(int eventId);
  Future<EventModel> cancelEvent(int eventId);
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  final ApiClient client;
  
  EventRemoteDataSourceImpl({required this.client});
  
  @override
  Future<EventModel> createEvent(EventModel event) async {
    final response = await client.post(
      AppConstants.eventsEndpoint,
      event.toJson(),
    );
    return EventModel.fromJson(response);
  }
  
  @override
  Future<List<EventModel>> getUpcomingEvents(String userId) async {
    final response = await client.get(
      '${AppConstants.eventsEndpoint}/user/$userId/upcoming?limit=50',
    );
    
    final List<dynamic> events = response['events'];
    return events.map((json) => EventModel.fromJson(json)).toList();
  }
  
  @override
  Future<EventModel> getEventById(int eventId) async {
    final response = await client.get(
      '${AppConstants.eventsEndpoint}/$eventId',
    );
    return EventModel.fromJson(response);
  }
  
  @override
  Future<EventModel> updateEvent(int eventId, EventModel event) async {
    final response = await client.put(
      '${AppConstants.eventsEndpoint}/$eventId',
      event.toUpdateJson(),
    );
    return EventModel.fromJson(response);
  }
  
  @override
  Future<void> deleteEvent(int eventId) async {
    await client.delete('${AppConstants.eventsEndpoint}/$eventId');
  }
  
  @override
  Future<EventModel> completeEvent(int eventId) async {
    final response = await client.post(
      '${AppConstants.eventsEndpoint}/$eventId/complete',
      {},
    );
    return EventModel.fromJson(response);
  }
  
  @override
  Future<EventModel> cancelEvent(int eventId) async {
    final response = await client.post(
      '${AppConstants.eventsEndpoint}/$eventId/cancel',
      {},
    );
    return EventModel.fromJson(response);
  }
}