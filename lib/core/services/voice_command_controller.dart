import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/domain/models.dart';
import '../../features/data/repository.dart';
import '../../features/presentation/providers.dart';
import '../configuration/app_logger.dart';
import 'voice_recognition_service.dart';
import 'voice_command_parser.dart';
import 'notification_service.dart';

/// Estado del servicio de voz
class VoiceServiceState {
  final bool isActive;
  final bool isListening;
  final String? lastCommand;
  final String? lastRecognizedText;
  final String? error;
  final bool isProcessing;
  
  const VoiceServiceState({
    this.isActive = false,
    this.isListening = false,
    this.lastCommand,
    this.lastRecognizedText,
    this.error,
    this.isProcessing = false,
  });
  
  VoiceServiceState copyWith({
    bool? isActive,
    bool? isListening,
    String? lastCommand,
    String? lastRecognizedText,
    String? error,
    bool? isProcessing,
  }) {
    return VoiceServiceState(
      isActive: isActive ?? this.isActive,
      isListening: isListening ?? this.isListening,
      lastCommand: lastCommand,
      lastRecognizedText: lastRecognizedText,
      error: error,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
  
  VoiceServiceState clearError() {
    return copyWith(error: '');
  }
}

/// Controlador del servicio de comandos de voz
class VoiceCommandController extends StateNotifier<VoiceServiceState> {
  final Repository _repository;
  final VoiceRecognitionService _voiceService = VoiceRecognitionService();
  final NotificationService _notificationService = NotificationService();
  
  VoiceCommandController(this._repository) : super(const VoiceServiceState()) {
    // Configurar callback de logs
    _voiceService.setLogCallback((message) {
      logger.debug('[VoiceController] $message');
    });
  }
  
  /// Inicializar servicios
  Future<void> initialize() async {
    logger.info('VoiceController: Initializing services...');
    
    try {
      // Inicializar notificaciones
      await _notificationService.initialize();
      await _notificationService.requestPermissions();
      logger.info('VoiceController: Notifications initialized');
      
      // Inicializar reconocimiento de voz
      final initialized = await _voiceService.initialize();
      
      if (!initialized) {
        state = state.copyWith(
          error: 'Could not initialize voice recognition. Check microphone permissions.',
        );
        logger.warning('VoiceController: Failed to initialize voice service');
      } else {
        logger.info('VoiceController: Voice service initialized successfully');
      }
    } catch (e, stackTrace) {
      logger.error('VoiceController: Error during initialization', e, stackTrace);
      state = state.copyWith(error: 'Error initializing: $e');
    }
  }
  
  /// Iniciar el servicio de voz
  Future<void> startVoiceService() async {
    logger.info('VoiceController: Starting voice service...');
    
    if (state.isActive) {
      logger.debug('VoiceController: Voice service already active');
      return;
    }
    
    // Limpiar errores previos
    state = state.clearError();
    
    // Verificar permisos
    final hasPermissions = await _voiceService.hasPermissions();
    if (!hasPermissions) {
      logger.warning('VoiceController: No microphone permissions');
      
      // Solicitar permisos
      final granted = await _voiceService.requestPermissions();
      if (!granted) {
        state = state.copyWith(
          error: 'Microphone permissions required. Please enable in Settings.',
        );
        return;
      }
    }
    
    try {
      // Mostrar notificación de servicio activo
      await _notificationService.showVoiceServiceNotification();
      logger.debug('VoiceController: Voice notification shown');
      
      // Iniciar escucha
      final started = await _voiceService.startListening(
        onCommandDetected: _handleVoiceCommand,
      );
      
      if (started) {
        state = state.copyWith(
          isActive: true,
          isListening: true,
          error: null,
        );
        logger.info('VoiceController: Voice service started successfully');
      } else {
        await _notificationService.hideVoiceServiceNotification();
        state = state.copyWith(
          error: 'Could not start voice recognition. Check your microphone.',
        );
        logger.error('VoiceController: Failed to start voice service');
      }
    } catch (e, stackTrace) {
      logger.error('VoiceController: Error starting voice service', e, stackTrace);
      await _notificationService.hideVoiceServiceNotification();
      state = state.copyWith(error: 'Error starting service: $e');
    }
  }
  
  /// Detener el servicio de voz
  Future<void> stopVoiceService() async {
    logger.info('VoiceController: Stopping voice service...');
    
    try {
      await _voiceService.stopListening();
      await _notificationService.hideVoiceServiceNotification();
      
      state = state.copyWith(
        isActive: false,
        isListening: false,
        error: null,
      );
      
      logger.info('VoiceController: Voice service stopped successfully');
    } catch (e, stackTrace) {
      logger.error('VoiceController: Error stopping voice service', e, stackTrace);
      state = state.copyWith(error: 'Error stopping service: $e');
    }
  }
  
  /// Manejar comando de voz detectado
  Future<void> _handleVoiceCommand(EventCommand command) async {
    logger.info('VoiceController: Processing voice command: $command');
    
    state = state.copyWith(
      lastCommand: command.title,
      lastRecognizedText: command.toString(),
      isProcessing: true,
      error: null,
    );
    
    try {
      // Crear el evento en el backend
      logger.debug('VoiceController: Creating event in backend...');
      final result = await _repository.createEvent(
        CreateEventRequest(
          title: command.title,
          eventDate: command.eventDate,
        ),
      );
      
      await result.fold(
        // Error al crear
        (failure) async {
          logger.error('VoiceController: Failed to create event: ${failure.message}');
          
          state = state.copyWith(
            isProcessing: false,
            error: failure.message,
          );
          
          // Notificar error
          await _notificationService.showEventCreatedNotification(
            title: '❌ Error: ${failure.message}',
            eventDate: command.eventDate,
          );
        },
        // Éxito al crear
        (event) async {
          logger.info('VoiceController: Event created successfully: ${event.id}');
          
          state = state.copyWith(
            isProcessing: false,
            error: null,
          );
          
          // Notificar que se creó el evento
          await _notificationService.showEventCreatedNotification(
            title: event.title,
            eventDate: event.eventDate,
          );
          
          // Programar recordatorio 1 minuto antes
          await _notificationService.scheduleEventReminder(
            eventId: event.id,
            title: event.title,
            eventDate: event.eventDate,
          );
          
          logger.info('VoiceController: Reminder scheduled for event ${event.id}');
        },
      );
    } catch (e, stackTrace) {
      logger.error('VoiceController: Error handling voice command', e, stackTrace);
      
      state = state.copyWith(
        isProcessing: false,
        error: 'Error processing command: $e',
      );
      
      // Notificar error
      await _notificationService.showEventCreatedNotification(
        title: '❌ Error creating event',
        eventDate: command.eventDate,
      );
    }
  }
  
  /// Toggle del servicio de voz
  Future<void> toggleVoiceService() async {
    if (state.isActive) {
      await stopVoiceService();
    } else {
      await startVoiceService();
    }
  }
  
  /// Limpiar error
  void clearError() {
    state = state.clearError();
  }
  
  @override
  void dispose() {
    logger.debug('VoiceController: Disposing...');
    stopVoiceService();
    super.dispose();
  }
}

/// Provider del controlador de voz
final voiceCommandControllerProvider = 
    StateNotifierProvider<VoiceCommandController, VoiceServiceState>((ref) {
  final repository = ref.watch(repositoryProvider);
  return VoiceCommandController(repository);
});

/// Provider para saber si el servicio de voz está activo
final isVoiceServiceActiveProvider = Provider<bool>((ref) {
  return ref.watch(voiceCommandControllerProvider).isActive;
});

/// Provider para saber si está procesando un comando
final isProcessingVoiceCommandProvider = Provider<bool>((ref) {
  return ref.watch(voiceCommandControllerProvider).isProcessing;
});