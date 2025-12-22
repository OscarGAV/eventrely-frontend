import 'package:flutter/foundation.dart';

/// Logger centralizado para la aplicación
class AppLogger {
  static const String _tag = 'EventRELY';
  
  /// Log de información general
  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      debugPrint('ℹ️ [$_tag${tag != null ? ':$tag' : ''}] $message');
    }
  }
  
  /// Log de advertencias
  static void warning(String message, [String? tag]) {
    if (kDebugMode) {
      debugPrint('⚠️ [$_tag${tag != null ? ':$tag' : ''}] $message');
    }
  }
  
  /// Log de errores
  static void error(String message, [dynamic error, StackTrace? stackTrace, String? tag]) {
    if (kDebugMode) {
      debugPrint('❌ [$_tag${tag != null ? ':$tag' : ''}] $message');
      if (error != null) {
        debugPrint('   Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('   StackTrace: $stackTrace');
      }
    }
  }
  
  /// Log de éxito
  static void success(String message, [String? tag]) {
    if (kDebugMode) {
      debugPrint('✅ [$_tag${tag != null ? ':$tag' : ''}] $message');
    }
  }
  
  /// Log de red/API
  static void network(String message, [String? tag]) {
    if (kDebugMode) {
      debugPrint('🌐 [$_tag${tag != null ? ':$tag' : ''}] $message');
    }
  }
  
  /// Log de datos/payload
  static void data(String message, [String? tag]) {
    if (kDebugMode) {
      debugPrint('📦 [$_tag${tag != null ? ':$tag' : ''}] $message');
    }
  }
  
  /// Log de respuestas
  static void response(String message, [String? tag]) {
    if (kDebugMode) {
      debugPrint('📄 [$_tag${tag != null ? ':$tag' : ''}] $message');
    }
  }
  
  /// Log de debug general
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      debugPrint('🔍 [$_tag${tag != null ? ':$tag' : ''}] $message');
    }
  }
}