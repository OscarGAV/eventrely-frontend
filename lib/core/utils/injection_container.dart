// injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import '../../features/events/data/datasources/event_remote_datasource.dart';
import '../../features/events/data/repositories/event_repository_impl.dart';
import '../../features/events/domain/repositories/event_repository.dart';
import '../../features/events/domain/usecases/event_use_cases.dart';
import '../../features/events/presentation/bloc/event_bloc.dart';
import '../network/api_client.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // BLoC
  sl.registerFactory(() => EventBloc(useCases: sl()));
  
  // Use Cases (ahora es uno solo)
  sl.registerLazySingleton(() => EventUseCases(sl()));
  
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