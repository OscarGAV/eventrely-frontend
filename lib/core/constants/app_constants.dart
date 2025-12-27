// app_constants.dart (versión optimizada)
class AppConstants {
  // User
  static const userId = 'user_test';
  
  // Timezone
  static const limaTimezone = 'America/Lima';
  static const limaUtcOffset = -5;
  
  // Reminders (minutos antes del evento)
  static const reminderMinutes = [360, 180, 60, 15];
  
  // Notifications
  static const notificationChannelId = 'eventrely_reminders';
  static const notificationChannelName = 'Event Reminders';
  static const notificationChannelDescription = 'Notifications for upcoming events';
  
  // API
  static const apiBaseUrl = 'https://eventrely-api-platofrm.azurewebsites.net'; // URL base de la API
  static const String eventsEndpoint = '/api/v1/events/'; // Endpoint de eventos
  static const apiTimeout = Duration(seconds: 60); // Tiempo máximo de espera para la respuesta de la API
  
  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'EventRELY-Flutter-App/1.0',
  };
}