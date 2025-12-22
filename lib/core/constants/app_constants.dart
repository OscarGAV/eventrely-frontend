class AppConstants {
  // User ID temporal (más adelante se implementará autenticación)
  static const String userId = 'user_test';
  
  // Timezone de Lima, Perú (UTC-5)
  static const String limaTimezone = 'America/Lima';
  static const int limaUtcOffset = -5;
  
  // Recordatorios (minutos antes del evento)
  static const List<int> reminderMinutes = [
    360,  // 6 horas
    180,  // 3 horas
    60,   // 1 hora
    15,   // 15 minutos
  ];
  
  // Notificaciones
  static const String notificationChannelId = 'eventrely_reminders';
  static const String notificationChannelName = 'Event Reminders';
  static const String notificationChannelDescription = 'Notifications for upcoming events';
}