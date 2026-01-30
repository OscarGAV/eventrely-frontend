import 'dart:async';
import 'package:speech_to_text/speech_recognition_result.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../configuration/app_logger.dart';
import 'voice_command_parser.dart';

/// Callback cuando se detecta un comando válido
typedef OnVoiceCommandCallback = void Function(EventCommand command);

/// Callback para logs y debugging
typedef OnVoiceLogCallback = void Function(String message);

/// Servicio para reconocimiento de voz continuo
class VoiceRecognitionService {
  static final VoiceRecognitionService _instance = VoiceRecognitionService._internal();
  factory VoiceRecognitionService() => _instance;
  VoiceRecognitionService._internal();
  
  final stt.SpeechToText _speech = stt.SpeechToText();
  final VoiceCommandParser _parser = VoiceCommandParser();
  
  bool _isInitialized = false;
  bool _isListening = false;
  OnVoiceCommandCallback? _onCommandDetected;
  OnVoiceLogCallback? _onLog;
  
  Timer? _restartTimer;
  int _restartAttempts = 0;
  static const int _maxRestartAttempts = 3;
  
  /// Estado actual de reconocimiento
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  
  /// Configurar callback de logs
  void setLogCallback(OnVoiceLogCallback callback) {
    _onLog = callback;
  }
  
  void _log(String message) {
    logger.debug('[VoiceService] $message');
    _onLog?.call(message);
  }
  
  /// Inicializar el servicio de reconocimiento de voz
  Future<bool> initialize() async {
    if (_isInitialized) {
      _log('Already initialized');
      return true;
    }
    
    // Solicitar permisos primero
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      logger.warning('VoiceService: Microphone permission denied');
      return false;
    }
    
    try {
      // Inicializar speech-to-text
      _isInitialized = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
        debugLogging: false, // Cambiar a false en producción
      );
      
      if (_isInitialized) {
        logger.info('VoiceService: Voice recognition initialized successfully');
        
        // Mostrar idiomas disponibles
        final locales = await _speech.locales();
        logger.debug('VoiceService: Available locales: ${locales.length}');
        for (var locale in locales) {
          if (locale.localeId.startsWith('es')) {
            logger.debug('VoiceService:   - ${locale.localeId}: ${locale.name}');
          }
        }
      } else {
        logger.error('VoiceService: Failed to initialize voice recognition');
      }
      
      return _isInitialized;
    } catch (e, stackTrace) {
      logger.error('VoiceService: Error during initialization', e, stackTrace);
      return false;
    }
  }
  
  /// Solicitar permisos de micrófono
  Future<bool> requestPermissions() async {
    try {
      final status = await Permission.microphone.request();
      logger.info('VoiceService: Microphone permission status: ${status.name}');
      return status.isGranted;
    } catch (e, stackTrace) {
      logger.error('VoiceService: Error requesting permissions', e, stackTrace);
      return false;
    }
  }
  
  /// Verificar si tiene permisos
  Future<bool> hasPermissions() async {
    try {
      final status = await Permission.microphone.status;
      return status.isGranted;
    } catch (e, stackTrace) {
      logger.error('VoiceService: Error checking permissions', e, stackTrace);
      return false;
    }
  }
  
  /// Iniciar escucha continua
  Future<bool> startListening({
    required OnVoiceCommandCallback onCommandDetected,
  }) async {
    logger.info('VoiceService: Starting continuous listening...');
    
    if (!_isInitialized) {
      logger.debug('VoiceService: Not initialized, initializing now...');
      final initialized = await initialize();
      if (!initialized) {
        logger.error('VoiceService: Failed to initialize');
        return false;
      }
    }
    
    if (_isListening) {
      logger.debug('VoiceService: Already listening');
      return true;
    }
    
    _onCommandDetected = onCommandDetected;
    _restartAttempts = 0;
    
    final started = await _startListeningSession();
    if (started) {
      _isListening = true;
      logger.info('VoiceService: Started continuous listening successfully');
    } else {
      logger.error('VoiceService: Failed to start listening');
    }
    
    return started;
  }
  
  /// Iniciar sesión de escucha
  Future<bool> _startListeningSession() async {
    try {
      // Verificar que el servicio esté disponible
      if (!await _speech.hasPermission) {
        logger.warning('VoiceService: No microphone permission');
        return false;
      }
      
      logger.debug('VoiceService: Starting new listening session...');
      
      // Probar diferentes locales españoles en orden de preferencia
      final preferredLocales = [
        'es-ES',  // Español de España (más universal)
        'es-MX',  // Español de México
        'es-US',  // Español de Estados Unidos
        'es-AR',  // Español de Argentina
        'es',     // Español genérico
      ];
      
      String? selectedLocale;
      final availableLocales = await _speech.locales();
      
      for (var preferred in preferredLocales) {
        if (availableLocales.any((l) => l.localeId == preferred)) {
          selectedLocale = preferred;
          logger.debug('VoiceService: Selected locale: $selectedLocale');
          break;
        }
      }
      
      // Si no encontramos ninguno específico, usar el primero que contenga 'es'
      selectedLocale ??= availableLocales
          .firstWhere(
            (l) => l.localeId.startsWith('es'),
            orElse: () => availableLocales.first,
          )
          .localeId;
      
      logger.info('VoiceService: Using locale: $selectedLocale');
      
      // Usar la nueva API con SpeechListenOptions
      await _speech.listen(
        onResult: _onSpeechResult,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          partialResults: true,
          cancelOnError: false,
        ),
        pauseFor: const Duration(seconds: 5),       // Más tiempo para pausas
        listenFor: const Duration(seconds: 60),     // Escuchar por 60 segundos
        localeId: selectedLocale,
      );
      
      _restartAttempts = 0;
      return true;
    } catch (e, stackTrace) {
      logger.error('VoiceService: Error starting listening session', e, stackTrace);
      return false;
    }
  }
  
  /// Callback cuando cambia el estado del reconocimiento
  void _onSpeechStatus(String status) {
    logger.debug('VoiceService: Speech status: $status');
    
    // Si terminó de escuchar, reiniciar después de 1 segundo
    if (status == 'done' || status == 'notListening') {
      if (_isListening && _restartAttempts < _maxRestartAttempts) {
        _restartTimer?.cancel();
        _restartTimer = Timer(const Duration(seconds: 2), () {
          if (_isListening) {
            _restartAttempts++;
            logger.debug('VoiceService: Restarting listening session (attempt $_restartAttempts)...');
            _startListeningSession();
          }
        });
      } else if (_restartAttempts >= _maxRestartAttempts) {
        logger.warning('VoiceService: Max restart attempts reached, stopping service');
        stopListening();
      }
    } else if (status == 'listening') {
      _restartAttempts = 0; // Reset counter when successfully listening
    }
  }
  
  /// Callback cuando hay un error
  void _onSpeechError(dynamic error) {
    logger.warning('VoiceService: Speech error: $error');
    
    // Analizar el tipo de error
    final errorMsg = error.toString().toLowerCase();
    
    if (errorMsg.contains('no match') || errorMsg.contains('no speech')) {
      logger.debug('VoiceService: No speech detected, will retry...');
    } else if (errorMsg.contains('network')) {
      logger.warning('VoiceService: Network error, check internet connection');
    } else if (errorMsg.contains('permission')) {
      logger.error('VoiceService: Permission error, stopping service');
      stopListening();
      return;
    }
    
    // Reintentar si está en modo continuo
    if (_isListening && _restartAttempts < _maxRestartAttempts) {
      _restartTimer?.cancel();
      _restartTimer = Timer(const Duration(seconds: 3), () {
        if (_isListening) {
          _restartAttempts++;
          logger.debug('VoiceService: Retrying after error (attempt $_restartAttempts)...');
          _startListeningSession();
        }
      });
    }
  }
  
  /// Callback cuando se recibe un resultado
  void _onSpeechResult(stt.SpeechRecognitionResult result) {
    final recognizedText = result.recognizedWords;
    final confidence = result.confidence;
    
    logger.debug('VoiceService: Recognized: "$recognizedText" (confidence: ${(confidence * 100).toStringAsFixed(1)}%)');
    
    // Solo procesar resultados finales con confianza mínima
    if (!result.finalResult) {
      logger.debug('VoiceService: Partial result, waiting for final...');
      return;
    }
    
    if (confidence < 0.5) {
      logger.debug('VoiceService: Low confidence, ignoring result');
      return;
    }
    
    // Intentar parsear como comando
    final command = _parser.parseCommand(recognizedText);
    
    if (command != null) {
      logger.info('VoiceService: Valid command detected: $command');
      _onCommandDetected?.call(command);
    } else {
      logger.debug('VoiceService: Not a valid event command');
    }
  }
  
  /// Detener escucha continua
  Future<void> stopListening() async {
    logger.info('VoiceService: Stopping listening...');
    _isListening = false;
    _restartTimer?.cancel();
    _restartAttempts = 0;
    
    try {
      await _speech.stop();
      logger.info('VoiceService: Stopped listening successfully');
    } catch (e, stackTrace) {
      logger.error('VoiceService: Error stopping listening', e, stackTrace);
    }
  }
  
  /// Limpiar recursos
  Future<void> dispose() async {
    logger.debug('VoiceService: Disposing voice service...');
    await stopListening();
    _restartTimer?.cancel();
    _onCommandDetected = null;
    _onLog = null;
  }
  
  /// Obtener idiomas disponibles
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return await _speech.locales();
  }
  
  /// Verificar si el reconocimiento de voz está disponible en el dispositivo
  Future<bool> isAvailable() async {
    try {
      return await _speech.initialize();
    } catch (e, stackTrace) {
      logger.error('VoiceService: Error checking availability', e, stackTrace);
      return false;
    }
  }
}