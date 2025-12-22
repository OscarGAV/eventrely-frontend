import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';
import '../../features/events/domain/entities/event_entity.dart';

class NotificationUtils {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;
  
  /// Inicializa el sistema de notificaciones
  static Future<void> initialize() async {
    if (_initialized) return;
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(initSettings);
    
    // Solicitar permisos para Android 13+
    await _requestPermissions();
    
    _initialized = true;
    AppLogger.success('Notification system initialized', 'NotificationUtils');
  }
  
  /// Solicita permisos necesarios
  static Future<void> _requestPermissions() async {
    try {
      // Android 13+ requiere permiso explícito para notificaciones
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        // Solicitar permiso para mostrar notificaciones
        await androidPlugin.requestNotificationsPermission();
        
        // Solicitar permiso para alarmas exactas (Android 12+)
        final exactAlarmPermission = await androidPlugin.requestExactAlarmsPermission();
        
        if (exactAlarmPermission == true) {
          AppLogger.success('Exact alarms permission granted', 'NotificationUtils');
        } else {
          AppLogger.warning('Exact alarms permission denied', 'NotificationUtils');
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error requesting permissions', e, stackTrace, 'NotificationUtils');
    }
  }

  /// Programa recordatorios para un evento (acepta objeto EventEntity)
  static Future<void> scheduleEventReminders(EventEntity event) async {
    try {
      if (!_initialized) {
        await initialize();
      }
      
      // Convertir a timezone de Lima
      final eventTime = tz.TZDateTime.from(event.eventDate, tz.local);
      
      AppLogger.info(
        'Scheduling reminders for event ${event.id} at $eventTime',
        'NotificationUtils'
      );
      
      // Programar notificaciones para cada intervalo
      for (final minutes in AppConstants.reminderMinutes) {
        final notificationTime = eventTime.subtract(Duration(minutes: minutes));
        
        // Solo programar si la fecha es futura
        if (notificationTime.isAfter(tz.TZDateTime.now(tz.local))) {
          await _scheduleNotification(
            id: event.id * 1000 + minutes,
            title: '🔔 Recordatorio: ${event.title}',
            body: _getNotificationBody(minutes, event.description),
            scheduledDate: notificationTime,
          );
          
          AppLogger.info(
            'Scheduled notification for $minutes minutes before event',
            'NotificationUtils'
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error scheduling event reminders',
        e,
        stackTrace,
        'NotificationUtils'
      );
      // No lanzar la excepción para que el evento se cree de todos modos
    }
  }
  
  /// Cancela todos los recordatorios de un evento
  static Future<void> cancelEventReminders(int eventId) async {
    try {
      for (final minutes in AppConstants.reminderMinutes) {
        await _notifications.cancel(eventId * 1000 + minutes);
      }
      AppLogger.info('Cancelled reminders for event $eventId', 'NotificationUtils');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error cancelling event reminders',
        e,
        stackTrace,
        'NotificationUtils'
      );
    }
  }
  
  /// Programa una notificación individual
  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error scheduling notification',
        e,
        stackTrace,
        'NotificationUtils'
      );
      rethrow;
    }
  }
  
  /// Genera el cuerpo del mensaje de notificación
  static String _getNotificationBody(int minutes, String? description) {
    final timeText = _formatTimeRemaining(minutes);
    final descText = description != null && description.isNotEmpty
        ? '\n$description'
        : '';
    return 'Tu evento comienza en $timeText$descText';
  }
  
  /// Formatea el tiempo restante de manera legible
  static String _formatTimeRemaining(int minutes) {
    if (minutes < 60) {
      return '$minutes minutos';
    } else if (minutes == 60) {
      return '1 hora';
    } else {
      final hours = minutes ~/ 60;
      return '$hours horas';
    }
  }
}