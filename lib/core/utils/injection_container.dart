import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../network/api_client.dart';
import '../../features/events/data/datasources/event_remote_datasource.dart';
import '../../features/events/data/repositories/event_repository_impl.dart';
import '../../features/events/domain/repositories/event_repository.dart';
import '../../features/events/domain/usecases/create_event.dart';
import '../../features/events/domain/usecases/get_upcoming_events.dart';
import '../../features/events/domain/usecases/update_event.dart';
import '../../features/events/domain/usecases/delete_event.dart';
import '../../features/events/domain/usecases/complete_event.dart';
import '../../features/events/presentation/bloc/event_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // BLoC
  sl.registerFactory(
    () => EventBloc(
      getUpcomingEvents: sl(),
      createEvent: sl(),
      updateEvent: sl(),
      deleteEvent: sl(),
      completeEvent: sl(),
    ),
  );
  
  // Use Cases
  sl.registerLazySingleton(() => GetUpcomingEvents(sl()));
  sl.registerLazySingleton(() => CreateEvent(sl()));
  sl.registerLazySingleton(() => UpdateEvent(sl()));
  sl.registerLazySingleton(() => DeleteEvent(sl()));
  sl.registerLazySingleton(() => CompleteEvent(sl()));
  
  // Repository
  sl.registerLazySingleton<EventRepository>(
    () => EventRepositoryImpl(remoteDataSource: sl()),
  );
  
  // Data Sources
  sl.registerLazySingleton<EventRemoteDataSource>(
    () => EventRemoteDataSourceImpl(client: sl()),
  );
  
  // Core
  sl.registerLazySingleton(() => ApiClient(client: sl()));
  
  // External
  sl.registerLazySingleton(() => http.Client());
}