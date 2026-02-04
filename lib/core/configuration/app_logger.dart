import 'package:flutter/foundation.dart';

/// Niveles de log
enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

/// Servicio de logging centralizado sin dependencias externas
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  bool _isProduction = false;

  /// Inicializar el logger
  void initialize({bool isProduction = false}) {
    _isProduction = isProduction;
    if (kDebugMode) {
      info('Logger initialized (${isProduction ? "PRODUCTION" : "DEVELOPMENT"} mode)');
    }
  }

  /// Log de debug (solo en desarrollo)
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isProduction && kDebugMode) {
      _log(LogLevel.debug, message, error, stackTrace);
    }
  }

  /// Log de información
  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _log(LogLevel.info, message, error, stackTrace);
    }
  }

  /// Log de advertencia
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  /// Log de error
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  /// Log crítico/fatal
  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.fatal, message, error, stackTrace);
  }

  /// Método interno para escribir logs
  void _log(LogLevel level, String message, [dynamic error, StackTrace? stackTrace]) {
    if (_isProduction && level.index < LogLevel.warning.index) {
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = _getLevelString(level);
    final emoji = _getEmoji(level);
    
    // Mensaje principal
    if (kDebugMode) {
      debugPrint('$emoji [$levelStr] $timestamp - $message');
      
      if (error != null) {
        debugPrint('  Error: $error');
      }
      
      if (stackTrace != null) {
        debugPrint('  StackTrace: $stackTrace');
      }
    } else {
      if (level.index >= LogLevel.warning.index) {
        debugPrint('$emoji [$levelStr] $message${error != null ? ' - Error: $error' : ''}');
      }
    }
  }

  String _getLevelString(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.fatal:
        return 'FATAL';
    }
  }

  String _getEmoji(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.fatal:
        return '💀';
    }
  }
}

final logger = AppLogger();