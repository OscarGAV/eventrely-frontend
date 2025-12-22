import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

class DateTimeUtils {
  /// Convierte UTC a hora de Lima (UTC-5)
  static DateTime utcToLima(DateTime utcDateTime) {
    final lima = tz.getLocation('America/Lima');
    final utcTz = tz.TZDateTime.from(utcDateTime, tz.UTC);
    return tz.TZDateTime.from(utcTz, lima);
  }
  
  /// Convierte hora de Lima a UTC
  static DateTime limaToUtc(DateTime limaDateTime) {
    final lima = tz.getLocation('America/Lima');
    final limaTz = tz.TZDateTime.from(limaDateTime, lima);
    return limaTz.toUtc();
  }
  
  /// Parse fecha UTC desde string ISO 8601
  static DateTime parseUtcDate(String isoString) {
    return DateTime.parse(isoString).toUtc();
  }
  
  /// Formatea fecha para mostrar al usuario (hora de Lima)
  static String formatDisplayDate(DateTime dateTime) {
    final limaTime = utcToLima(dateTime);
    return DateFormat('dd MMM yyyy, HH:mm', 'es').format(limaTime);
  }
  
  /// Formatea fecha corta
  static String formatShortDate(DateTime dateTime) {
    final limaTime = utcToLima(dateTime);
    return DateFormat('dd/MM/yyyy').format(limaTime);
  }
  
  /// Formatea solo la hora
  static String formatTime(DateTime dateTime) {
    final limaTime = utcToLima(dateTime);
    return DateFormat('HH:mm').format(limaTime);
  }
  
  /// Obtiene hora actual en Lima
  static DateTime nowInLima() {
    final lima = tz.getLocation('America/Lima');
    return tz.TZDateTime.now(lima);
  }
  
  /// Verifica si un evento es próximo (dentro de 24 horas)
  static bool isUpcoming(DateTime eventDate) {
    final now = DateTime.now().toUtc();
    final difference = eventDate.difference(now);
    return difference.inHours >= 0 && difference.inHours <= 24;
  }
  
  /// Calcula tiempo restante hasta el evento
  static String timeUntilEvent(DateTime eventDate) {
    final now = DateTime.now().toUtc();
    final difference = eventDate.difference(now);
    
    if (difference.isNegative) return 'Expirado';
    
    if (difference.inDays > 0) {
      return '${difference.inDays} días';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} horas';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutos';
    } else {
      return 'Ahora';
    }
  }
}