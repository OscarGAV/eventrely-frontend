class ApiConstants {
  // Base URL - Cambiar por tu URL de producción
  static const String baseUrl = 'https://eventrely-api-platofrm.azurewebsites.net';
  
  // Endpoints
  static const String eventsEndpoint = '/api/v1/events/';
  
  // Timeout
  static const Duration timeout = Duration(seconds: 60);
  
  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'EventRELY-Flutter-App/1.0',
  };
}