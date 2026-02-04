import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../features/domain/models.dart';
import '../../core/network/api_client.dart';

class Repository {
  final ApiClient _apiClient;
  
  Repository(this._apiClient);
  
  // ============================================================================
  // AUTHENTICATION
  // ============================================================================
  
  Future<Either<Failure, AuthResponse>> signUp(SignUpRequest request) async {
    try {
      final response = await _apiClient.post('/auth/signup', data: request.toJson());
      final authResponse = AuthResponse.fromJson(response.data);
      await _apiClient.saveTokens(authResponse.accessToken, authResponse.refreshToken);
      return Right(authResponse);
    } on DioException catch (e) {
      return Left(_handleError(e));
    }
  }
  
  Future<Either<Failure, AuthResponse>> signIn(SignInRequest request) async {
    try {
      final response = await _apiClient.post('/auth/signin', data: request.toJson());
      final authResponse = AuthResponse.fromJson(response.data);
      await _apiClient.saveTokens(authResponse.accessToken, authResponse.refreshToken);
      return Right(authResponse);
    } on DioException catch (e) {
      return Left(_handleError(e));
    }
  }
  
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/auth/me');
      return Right(User.fromJson(response.data));
    } on DioException catch (e) {
      return Left(_handleError(e));
    }
  }
  
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _apiClient.clearTokens();
      return const Right(unit);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
  
  // ============================================================================
  // EVENTS
  // ============================================================================
  
  Future<Either<Failure, Event>> createEvent(CreateEventRequest request) async {
    try {
      final response = await _apiClient.post('/events/', data: request.toJson());
      return Right(Event.fromJson(response.data));
    } on DioException catch (e) {
      return Left(_handleError(e));
    }
  }
  
  Future<Either<Failure, List<Event>>> getAllEvents() async {
    try {
      final response = await _apiClient.get('/events/');
      final eventList = EventListResponse.fromJson(response.data);
      return Right(eventList.events);
    } on DioException catch (e) {
      return Left(_handleError(e));
    }
  }
  
  Future<Either<Failure, Event>> getEventById(int id) async {
    try {
      final response = await _apiClient.get('/events/$id');
      return Right(Event.fromJson(response.data));
    } on DioException catch (e) {
      return Left(_handleError(e));
    }
  }
  
  Future<Either<Failure, List<Event>>> getUpcomingEvents({int limit = 50}) async {
    try {
      final response = await _apiClient.get('/events/upcoming', queryParameters: {'limit': limit});
      final eventList = EventListResponse.fromJson(response.data);
      return Right(eventList.events);
    } on DioException catch (e) {
      return Left(_handleError(e));
    }
  }
  
  Future<Either<Failure, Event>> updateEvent(int id, UpdateEventRequest request) async {
    try {
      final response = await _apiClient.put('/events/$id', data: request.toJson());
      return Right(Event.fromJson(response.data));
    } on DioException catch (e) {
      return Left(_handleError(e));
    }
  }
  
  Future<Either<Failure, Unit>> deleteEvent(int id) async {
    try {
      await _apiClient.delete('/events/$id');
      return const Right(unit);
    } on DioException catch (e) {
      return Left(_handleError(e));
    }
  }
  
  Future<Either<Failure, Event>> completeEvent(int id) async {
    try {
      final response = await _apiClient.post('/events/$id/complete');
      return Right(Event.fromJson(response.data));
    } on DioException catch (e) {
      return Left(_handleError(e));
    }
  }
  
  Future<Either<Failure, Event>> cancelEvent(int id) async {
    try {
      final response = await _apiClient.post('/events/$id/cancel');
      return Right(Event.fromJson(response.data));
    } on DioException catch (e) {
      return Left(_handleError(e));
    }
  }
  
  // ============================================================================
  // ERROR HANDLING
  // ============================================================================
  
  Failure _handleError(DioException error) {
    // Manejar timeouts
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const NetworkFailure('Connection timeout');
    }
    
    // Manejar error de conexión
    if (error.type == DioExceptionType.connectionError) {
      return const NetworkFailure('No internet connection');
    }
    
    // Si hay respuesta del servidor
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      String message = 'Unknown error';
      
      // Extraer mensaje de error de forma segura
      try {
        final responseData = error.response!.data;
        
        if (responseData is Map<String, dynamic>) {
          // Intentar obtener 'detail' o 'message'
          final detail = responseData['detail'];
          final msg = responseData['message'];
          
          if (detail != null) {
            if (detail is String) {
              message = detail;
            } else if (detail is List) {
              // Si es una lista, tomar el primer elemento o concatenar
              message = detail.isNotEmpty ? detail.first.toString() : 'Validation error';
            } else {
              message = detail.toString();
            }
          } else if (msg != null) {
            if (msg is String) {
              message = msg;
            } else if (msg is List) {
              message = msg.isNotEmpty ? msg.first.toString() : 'Error';
            } else {
              message = msg.toString();
            }
          }
        } else if (responseData is String) {
          message = responseData;
        } else {
          message = responseData?.toString() ?? 'Unknown error';
        }
      } catch (e) {
        message = _getDefaultMessageForStatusCode(statusCode);
      }
      
      // Retornar el tipo de fallo
      switch (statusCode) {
        case 400:
          return ValidationFailure(message);
        case 401:
          return UnauthorizedFailure(message);
        case 404:
          return NotFoundFailure(message);
        case 500:
          return ServerFailure(message);
        default:
          return UnknownFailure(message);
      }
    }
    
    String errorMessage = 'Unknown error';
    try {
      if (error.message != null) {
        errorMessage = error.message!;
      }
    } catch (e) {
      errorMessage = 'Network error';
    }
    
    return UnknownFailure(errorMessage);
  }
  
  // Helper para mensajes por defecto
  String _getDefaultMessageForStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not found';
      case 500:
        return 'Server error';
      case 502:
        return 'Bad gateway';
      case 503:
        return 'Service unavailable';
      default:
        return 'Unknown error';
    }
  }
}