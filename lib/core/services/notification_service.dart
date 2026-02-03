import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../configuration/app_logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  
  /// Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Inicializar timezones
      tz.initializeTimeZones();
      
      // CRÍTICO: Configurar la zona horaria correcta para Lima, Perú
      final location = tz.getLocation('America/Lima');
      tz.setLocalLocation(location);
      
      logger.info('NotificationService: Timezone set to ${location.name}');
      logger.info('NotificationService: Current TZ time: ${tz.TZDateTime.now(location)}');
      
      // Configuración para Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Configuración para iOS (si se necesita en el futuro)
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );
      
      _initialized = true;
      logger.info('NotificationService: Initialized successfully');
      
      // Solicitar permisos de alarmas exactas
      await _requestExactAlarmPermission();
      
      // Mostrar notificaciones pendientes para debugging
      await _logPendingNotifications();
      
    } catch (e, stackTrace) {
      logger.error('NotificationService: Error during initialization', e, stackTrace);
    }
  }
  
  /// Solicitar permisos de alarmas exactas (Android 12+)
  Future<void> _requestExactAlarmPermission() async {
    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        // Solicitar permiso para alarmas exactas
        final canScheduleExact = await androidPlugin.canScheduleExactNotifications();
        logger.info('NotificationService: Can schedule exact alarms: $canScheduleExact');
        
        if (canScheduleExact != null && !canScheduleExact) {
          logger.warning('NotificationService: Cannot schedule exact alarms! Requesting permission...');
          await androidPlugin.requestExactAlarmsPermission();
        }
      }
    } catch (e, stackTrace) {
      logger.error('NotificationService: Error requesting exact alarm permission', e, stackTrace);
    }
  }
  
  /// Callback cuando se toca una notificación
  void _onNotificationTap(NotificationResponse response) {
    logger.debug('Notification tapped: ${response.payload}');
  }
  
  /// Solicitar permisos de notificación (Android 13+)
  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();
    
    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        logger.info('NotificationService: Notification permission granted: $granted');
        return granted ?? false;
      }
      
      return true;
    } catch (e, stackTrace) {
      logger.error('NotificationService: Error requesting permissions', e, stackTrace);
      return false;
    }
  }
  
  /// Mostrar notificación inmediata de confirmación
  Future<void> showEventCreatedNotification({
    required String title,
    required DateTime eventDate,
  }) async {
    if (!_initialized) await initialize();
    
    try {
      const androidDetails = AndroidNotificationDetails(
        'event_created',
        'Event Created',
        channelDescription: 'Notifications when events are created via voice',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      );
      
      const notificationDetails = NotificationDetails(android: androidDetails);
      
      final formattedDate = _formatDateTime(eventDate);
      
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, // ID único
        '✅ Evento Creado',
        '"$title" programado para $formattedDate',
        notificationDetails,
        payload: 'event_created:$title',
      );
      
      logger.info('NotificationService: Event created notification shown');
    } catch (e, stackTrace) {
      logger.error('NotificationService: Error showing event created notification', e, stackTrace);
    }
  }
  
  /// Programar AMBAS notificaciones: anticipación (5 min antes) + inicio del evento
  Future<void> scheduleEventReminder({
    required int eventId,
    required String title,
    required DateTime eventDate,
    int minutesBefore = 5, // Anticipación configurable (por defecto 5 minutos)
  }) async {
    if (!_initialized) await initialize();
    
    logger.info('═══════════════════════════════════════════════════════════');
    logger.info('📅 SCHEDULING NOTIFICATIONS FOR EVENT $eventId');
    logger.info('   Title: "$title"');
    logger.info('   Event Date (Local): $eventDate');
    logger.info('═══════════════════════════════════════════════════════════');
    
    final now = DateTime.now();
    final location = tz.local;
    
    // Convertir eventDate a TZDateTime
    final tzEventDate = tz.TZDateTime.from(eventDate, location);
    final tzNow = tz.TZDateTime.now(location);
    
    logger.info('⏰ Current time (Local): $now');
    logger.info('⏰ Current time (TZ): $tzNow');
    logger.info('⏰ Event time (TZ): $tzEventDate');
    logger.info('⏰ Time difference: ${tzEventDate.difference(tzNow).inMinutes} minutes');
    
    // ==================================================================
    // NOTIFICACIÓN 1: X minutos ANTES del evento
    // ==================================================================
    final tzReminderTime = tzEventDate.subtract(Duration(minutes: minutesBefore));
    
    logger.info('📢 NOTIFICATION 1 (BEFORE):');
    logger.info('   Scheduled for: $tzReminderTime');
    logger.info('   Time until notification: ${tzReminderTime.difference(tzNow).inMinutes} minutes');
    
    if (tzReminderTime.isAfter(tzNow)) {
      try {
        final androidDetails = AndroidNotificationDetails(
          'event_reminder_before',
          'Event Reminders (Before)',
          channelDescription: 'Notifications before events start',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList(const [0, 500, 250, 500]),
          enableLights: true,
          styleInformation: const BigTextStyleInformation(''),
        );
        
        final notificationDetails = NotificationDetails(android: androidDetails);
        
        // ID único para notificación "antes": eventId * 10
        final notificationId = eventId * 10;
        
        await _notifications.zonedSchedule(
          notificationId,
          '⏰ Recordatorio',
          '"$title" comienza en $minutesBefore minutos',
          tzReminderTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'reminder_before:$eventId',
        );
        
        logger.info('✅ NOTIFICATION 1 SCHEDULED SUCCESSFULLY');
        logger.info('   ID: $notificationId');
        logger.info('   Time: $tzReminderTime');
      } catch (e, stackTrace) {
        logger.error('❌ ERROR SCHEDULING NOTIFICATION 1', e, stackTrace);
      }
    } else {
      logger.warning('⚠️  SKIPPING NOTIFICATION 1: Time is in the past');
      logger.warning('   Reminder time: $tzReminderTime');
      logger.warning('   Current time: $tzNow');
    }
    
    // ==================================================================
    // NOTIFICACIÓN 2: CUANDO COMIENZA el evento
    // ==================================================================
    logger.info('📢 NOTIFICATION 2 (START):');
    logger.info('   Scheduled for: $tzEventDate');
    logger.info('   Time until notification: ${tzEventDate.difference(tzNow).inMinutes} minutes');
    
    if (tzEventDate.isAfter(tzNow)) {
      try {
        final androidDetails = AndroidNotificationDetails(
          'event_reminder_start',
          'Event Reminders (Start)',
          channelDescription: 'Notifications when events start',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList(const [0, 1000, 500, 1000]),
          enableLights: true,
          ledColor: const Color(0xFFFF5722),
          ledOnMs: 1000,
          ledOffMs: 500,
          styleInformation: const BigTextStyleInformation(''),
        );
        
        final notificationDetails = NotificationDetails(android: androidDetails);
        
        // ID único para notificación "al inicio": eventId * 10 + 1
        final notificationId = eventId * 10 + 1;
        
        await _notifications.zonedSchedule(
          notificationId,
          '🔔 ¡Tu evento está comenzando!',
          '"$title" - ${_formatDateTime(eventDate)}',
          tzEventDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'reminder_start:$eventId',
        );
        
        logger.info('✅ NOTIFICATION 2 SCHEDULED SUCCESSFULLY');
        logger.info('   ID: $notificationId');
        logger.info('   Time: $tzEventDate');
      } catch (e, stackTrace) {
        logger.error('❌ ERROR SCHEDULING NOTIFICATION 2', e, stackTrace);
      }
    } else {
      logger.warning('⚠️  SKIPPING NOTIFICATION 2: Time is in the past');
      logger.warning('   Event time: $tzEventDate');
      logger.warning('   Current time: $tzNow');
    }
    
    logger.info('═══════════════════════════════════════════════════════════');
    
    // Mostrar notificaciones pendientes para debugging
    await _logPendingNotifications();
  }
  
  /// Cancelar ambas notificaciones de un evento
  Future<void> cancelEventReminder(int eventId) async {
    if (!_initialized) await initialize();
    
    try {
      // Cancelar notificación "antes"
      await _notifications.cancel(eventId * 10);
      // Cancelar notificación "al inicio"
      await _notifications.cancel(eventId * 10 + 1);
      
      logger.info('NotificationService: Cancelled both reminders for event $eventId');
      await _logPendingNotifications();
    } catch (e, stackTrace) {
      logger.error('NotificationService: Error cancelling notifications', e, stackTrace);
    }
  }
  
  /// Cancelar todas las notificaciones pendientes
  Future<void> cancelAll() async {
    if (!_initialized) await initialize();
    
    try {
      await _notifications.cancelAll();
      logger.info('NotificationService: Cancelled all notifications');
    } catch (e, stackTrace) {
      logger.error('NotificationService: Error cancelling all notifications', e, stackTrace);
    }
  }
  
  /// Mostrar notificación de servicio de voz activo
  Future<void> showVoiceServiceNotification() async {
    if (!_initialized) await initialize();
    
    try {
      const androidDetails = AndroidNotificationDetails(
        'voice_service',
        'Voice Recognition Service',
        channelDescription: 'Shows when voice recognition is active',
        importance: Importance.low,
        priority: Priority.low,
        icon: '@mipmap/ic_launcher',
        ongoing: true,
        autoCancel: false,
        playSound: false,
        enableVibration: false,
      );
      
      const notificationDetails = NotificationDetails(android: androidDetails);
      
      await _notifications.show(
        999999,
        'Escuchando comandos de voz',
        'Di "Evento..." para crear eventos',
        notificationDetails,
        payload: 'voice_service',
      );
      
      logger.info('NotificationService: Voice service notification shown');
    } catch (e, stackTrace) {
      logger.error('NotificationService: Error showing voice service notification', e, stackTrace);
    }
  }
  
  /// Ocultar notificación del servicio de voz
  Future<void> hideVoiceServiceNotification() async {
    if (!_initialized) await initialize();
    
    try {
      await _notifications.cancel(999999);
      logger.info('NotificationService: Voice service notification hidden');
    } catch (e, stackTrace) {
      logger.error('NotificationService: Error hiding voice service notification', e, stackTrace);
    }
  }
  
  /// Logging de notificaciones pendientes (para debugging)
  Future<void> _logPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      logger.info('📋 ═══════════════════════════════════════════════════════');
      logger.info('📋 PENDING NOTIFICATIONS: ${pending.length}');
      logger.info('📋 ═══════════════════════════════════════════════════════');
      
      if (pending.isEmpty) {
        logger.info('📋 No pending notifications');
      } else {
        for (var notification in pending) {
          logger.info('📋 - ID: ${notification.id}');
          logger.info('📋   Title: ${notification.title}');
          logger.info('📋   Body: ${notification.body}');
          logger.info('📋   Payload: ${notification.payload}');
          logger.info('📋   ───────────────────────────────────────────────');
        }
      }
      logger.info('📋 ═══════════════════════════════════════════════════════');
    } catch (e, stackTrace) {
      logger.error('NotificationService: Error getting pending notifications', e, stackTrace);
    }
  }
  
  /// Obtener todas las notificaciones pendientes
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_initialized) await initialize();
    
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e, stackTrace) {
      logger.error('NotificationService: Error getting pending notifications', e, stackTrace);
      return [];
    }
  }
  
  /// Formatear fecha para notificaciones
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final eventDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    
    if (eventDay == today) {
      return 'hoy a las $time';
    } else if (eventDay == tomorrow) {
      return 'mañana a las $time';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} a las $time';
    }
  }
  
  /// Test de notificación inmediata (para debugging)
  Future<void> testNotification() async {
    if (!_initialized) await initialize();
    
    try {
      const androidDetails = AndroidNotificationDetails(
        'test',
        'Test Notifications',
        channelDescription: 'Test notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );
      
      const notificationDetails = NotificationDetails(android: androidDetails);
      
      await _notifications.show(
        99999,
        'Test Notification',
        'If you see this, notifications are working!',
        notificationDetails,
      );
      
      logger.info('NotificationService: Test notification shown');
    } catch (e, stackTrace) {
      logger.error('NotificationService: Error showing test notification', e, stackTrace);
    }
  }
  
  /// Test de notificación programada en 10 segundos
  Future<void> testScheduledNotification() async {
    if (!_initialized) await initialize();
    
    try {
      final location = tz.local;
      final scheduledTime = tz.TZDateTime.now(location).add(const Duration(seconds: 10));
      
      logger.info('🧪 SCHEDULING TEST NOTIFICATION');
      logger.info('   Current time: ${tz.TZDateTime.now(location)}');
      logger.info('   Scheduled for: $scheduledTime');
      logger.info('   Seconds until notification: 10');
      
      const androidDetails = AndroidNotificationDetails(
        'test',
        'Test Notifications',
        channelDescription: 'Test notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );
      
      const notificationDetails = NotificationDetails(android: androidDetails);
      
      await _notifications.zonedSchedule(
        88888,
        '🧪 Test Scheduled Notification',
        'This notification was scheduled 10 seconds ago!',
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      logger.info('✅ Test notification scheduled successfully');
      await _logPendingNotifications();
    } catch (e, stackTrace) {
      logger.error('NotificationService: Error showing test notification', e, stackTrace);
    }
  }
}