import 'package:intl/intl.dart';
import '../configuration/app_logger.dart';

/// Servicio para parsear comandos de voz y extraer información de eventos
class VoiceCommandParser {
  /// Parsea un comando de voz y extrae título y fecha del evento
  /// Retorna null si no es un comando válido
  EventCommand? parseCommand(String text) {
    final lowerText = text.toLowerCase().trim();
    
    logger.debug('[Parser] Parsing: "$lowerText"');
    
    // Verificar si contiene palabras clave relacionadas con eventos
    final eventKeywords = [
      'evento',
      'recordatorio',
      'recordar',
      'avisar',
      'avisarme',
      'notificar',
      'cita',
      'reunión',
      'reunion',
      'alarma'
    ];
    
    final hasEventKeyword = eventKeywords.any((keyword) => lowerText.contains(keyword));
    
    if (!hasEventKeyword) {
      logger.debug('[Parser] No event keyword found');
      return null;
    }
    
    // Extraer título y calcular fecha
    final title = _extractTitle(lowerText);
    if (title == null || title.isEmpty) {
      logger.debug('[Parser] No title found');
      return null;
    }
    
    final eventDate = _extractDateTime(lowerText);
    if (eventDate == null) {
      logger.debug('[Parser] No date found');
      return null;
    }
    
    logger.debug('[Parser] Command parsed successfully');
    return EventCommand(title: title, eventDate: eventDate);
  }
  
  /// Extrae el título del evento del comando de voz
  String? _extractTitle(String text) {
    // Lista de patrones para extraer el título
    
    // Patrón 1: "evento/recordatorio/cita llamado/llamada [TÍTULO]"
    final pattern1 = RegExp(
      r'(?:evento|recordatorio|cita|reunión|reunion|alarma)\s+(?:llamado|llamada|de nombre|con nombre)\s+([^,]+?)(?:\s+(?:para|dentro|en|mañana|hoy|a las|el|la|los|las)|\s*$)',
      caseSensitive: false,
    );
    final match1 = pattern1.firstMatch(text);
    if (match1 != null) {
      final title = match1.group(1)?.trim();
      if (title != null && title.isNotEmpty) {
        logger.debug('[Parser] Title extracted (pattern 1): "$title"');
        return _cleanTitle(title);
      }
    }
    
    // Patrón 2: "evento/recordatorio de [TÍTULO]"
    final pattern2 = RegExp(
      r'(?:evento|recordatorio|cita|reunión|reunion|alarma)\s+de\s+([^,]+?)(?:\s+(?:para|dentro|en|mañana|hoy|a las|el|la|los|las)|\s*$)',
      caseSensitive: false,
    );
    final match2 = pattern2.firstMatch(text);
    if (match2 != null) {
      final title = match2.group(1)?.trim();
      if (title != null && title.isNotEmpty) {
        logger.debug('[Parser] Title extracted (pattern 2): "$title"');
        return _cleanTitle(title);
      }
    }
    
    // Patrón 3: "recordar/recordarme/avisar [TÍTULO]"
    final pattern3 = RegExp(
      r'(?:recordar|recordarme|avisar|avisarme|notificar)\s+([^,]+?)(?:\s+(?:para|dentro|en|mañana|hoy|a las|el|la|los|las)|\s*$)',
      caseSensitive: false,
    );
    final match3 = pattern3.firstMatch(text);
    if (match3 != null) {
      final title = match3.group(1)?.trim();
      if (title != null && title.isNotEmpty) {
        logger.debug('[Parser] Title extracted (pattern 3): "$title"');
        return _cleanTitle(title);
      }
    }
    
    // Patrón 4: "tengo un/una evento/cita/reunión de [TÍTULO]"
    final pattern4 = RegExp(
      r'tengo\s+(?:un|una)\s+(?:evento|cita|reunión|reunion)\s+(?:de|llamado|llamada)\s+([^,]+?)(?:\s+(?:para|dentro|en|mañana|hoy|a las|el|la|los|las)|\s*$)',
      caseSensitive: false,
    );
    final match4 = pattern4.firstMatch(text);
    if (match4 != null) {
      final title = match4.group(1)?.trim();
      if (title != null && title.isNotEmpty) {
        logger.debug('[Parser] Title extracted (pattern 4): "$title"');
        return _cleanTitle(title);
      }
    }
    
    // Patrón 5: "crear/programar evento/cita/reunión [TÍTULO]"
    final pattern5 = RegExp(
      r'(?:crear|programar|agendar)\s+(?:un|una)?\s*(?:evento|cita|reunión|reunion|recordatorio)\s+(?:de|llamado|llamada)?\s*([^,]+?)(?:\s+(?:para|dentro|en|mañana|hoy|a las|el|la|los|las)|\s*$)',
      caseSensitive: false,
    );
    final match5 = pattern5.firstMatch(text);
    if (match5 != null) {
      final title = match5.group(1)?.trim();
      if (title != null && title.isNotEmpty) {
        logger.debug('[Parser] Title extracted (pattern 5): "$title"');
        return _cleanTitle(title);
      }
    }
    
    // Patrón 6: Genérico - "evento [TÍTULO]"
    final pattern6 = RegExp(
      r'(?:evento|cita|reunión|reunion|recordatorio)\s+([^,]+?)(?:\s+(?:para|dentro|en|mañana|hoy|a las|el|la|los|las)|\s*$)',
      caseSensitive: false,
    );
    final match6 = pattern6.firstMatch(text);
    if (match6 != null) {
      final title = match6.group(1)?.trim();
      // Evitar palabras clave como título
      if (title != null && 
          title.isNotEmpty && 
          !['llamado', 'de', 'para', 'con'].contains(title.toLowerCase())) {
        logger.debug('[Parser] Title extracted (pattern 6): "$title"');
        return _cleanTitle(title);
      }
    }
    
    logger.debug('[Parser] No title pattern matched');
    return null;
  }
  
  /// Limpiar el título removiendo palabras innecesarias
  String _cleanTitle(String title) {
    // Remover artículos y preposiciones al inicio
    final cleaned = title
        .replaceAll(RegExp(r'^\s*(?:el|la|los|las|un|una|de|del|al)\s+', caseSensitive: false), '')
        .trim();
    return cleaned;
  }
  
  /// Extrae y calcula la fecha/hora del evento
  DateTime? _extractDateTime(String text) {
    final now = DateTime.now();
    
    // Patrón: "dentro de X minutos/horas/días"
    final withinPattern = RegExp(
      r'dentro\s+de\s+(\d+)\s+(minuto|minutos|hora|horas|día|días|dia|dias)',
      caseSensitive: false,
    );
    final withinMatch = withinPattern.firstMatch(text);
    if (withinMatch != null) {
      final amount = int.tryParse(withinMatch.group(1) ?? '');
      final unit = withinMatch.group(2)?.toLowerCase();
      
      if (amount != null) {
        if (unit?.contains('minuto') == true) {
          final result = now.add(Duration(minutes: amount));
          logger.debug('[Parser] Date extracted (within minutes): $result');
          return result;
        } else if (unit?.contains('hora') == true) {
          final result = now.add(Duration(hours: amount));
          logger.debug('[Parser] Date extracted (within hours): $result');
          return result;
        } else if (unit?.contains('día') == true || unit?.contains('dia') == true) {
          final result = now.add(Duration(days: amount));
          logger.debug('[Parser] Date extracted (within days): $result');
          return result;
        }
      }
    }
    
    // Patrón: "en X minutos/horas/días"
    final inPattern = RegExp(
      r'en\s+(\d+)\s+(minuto|minutos|hora|horas|día|días|dia|dias)',
      caseSensitive: false,
    );
    final inMatch = inPattern.firstMatch(text);
    if (inMatch != null) {
      final amount = int.tryParse(inMatch.group(1) ?? '');
      final unit = inMatch.group(2)?.toLowerCase();
      
      if (amount != null) {
        if (unit?.contains('minuto') == true) {
          final result = now.add(Duration(minutes: amount));
          logger.debug('[Parser] Date extracted (in minutes): $result');
          return result;
        } else if (unit?.contains('hora') == true) {
          final result = now.add(Duration(hours: amount));
          logger.debug('[Parser] Date extracted (in hours): $result');
          return result;
        } else if (unit?.contains('día') == true || unit?.contains('dia') == true) {
          final result = now.add(Duration(days: amount));
          logger.debug('[Parser] Date extracted (in days): $result');
          return result;
        }
      }
    }
    
    // Patrón: "en una hora", "en un minuto", "en un día"
    if (text.contains('en una hora')) {
      final result = now.add(const Duration(hours: 1));
      logger.debug('[Parser] Date extracted (in one hour): $result');
      return result;
    }
    if (text.contains('en un minuto')) {
      final result = now.add(const Duration(minutes: 1));
      logger.debug('[Parser] Date extracted (in one minute): $result');
      return result;
    }
    if (text.contains(RegExp(r'en un día|en un dia', caseSensitive: false))) {
      final result = now.add(const Duration(days: 1));
      logger.debug('[Parser] Date extracted (in one day): $result');
      return result;
    }
    
    // Patrón: "mañana a las HH:MM" o "mañana a las H"
    final tomorrowPattern = RegExp(
      r'mañana\s+a\s+las\s+(\d{1,2})(?::(\d{2}))?(?:\s+(am|pm|de la tarde|de la mañana|de la noche|am\.|pm\.))?',
      caseSensitive: false,
    );
    final tomorrowMatch = tomorrowPattern.firstMatch(text);
    if (tomorrowMatch != null) {
      var hour = int.tryParse(tomorrowMatch.group(1) ?? '');
      final minute = int.tryParse(tomorrowMatch.group(2) ?? '0') ?? 0;
      final period = tomorrowMatch.group(3)?.toLowerCase().replaceAll('.', '');
      
      if (hour != null) {
        // Convertir a formato 24 horas
        hour = _convertTo24Hour(hour, period);
        
        final tomorrow = now.add(const Duration(days: 1));
        final result = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);
        logger.debug('[Parser] Date extracted (tomorrow): $result');
        return result;
      }
    }
    
    // Patrón: "hoy a las HH:MM"
    final todayPattern = RegExp(
      r'hoy\s+a\s+las\s+(\d{1,2})(?::(\d{2}))?(?:\s+(am|pm|de la tarde|de la mañana|de la noche|am\.|pm\.))?',
      caseSensitive: false,
    );
    final todayMatch = todayPattern.firstMatch(text);
    if (todayMatch != null) {
      var hour = int.tryParse(todayMatch.group(1) ?? '');
      final minute = int.tryParse(todayMatch.group(2) ?? '0') ?? 0;
      final period = todayMatch.group(3)?.toLowerCase().replaceAll('.', '');
      
      if (hour != null) {
        // Convertir a formato 24 horas
        hour = _convertTo24Hour(hour, period);
        
        var eventDateTime = DateTime(now.year, now.month, now.day, hour, minute);
        
        // Si la hora ya pasó hoy, asumir que es mañana
        if (eventDateTime.isBefore(now)) {
          eventDateTime = eventDateTime.add(const Duration(days: 1));
          logger.debug('[Parser] Time passed today, moving to tomorrow');
        }
        
        logger.debug('[Parser] Date extracted (today): $eventDateTime');
        return eventDateTime;
      }
    }
    
    // Patrón: "a las HH:MM" (sin especificar día)
    final timePattern = RegExp(
      r'a\s+las\s+(\d{1,2})(?::(\d{2}))?(?:\s+(am|pm|de la tarde|de la mañana|de la noche|am\.|pm\.))?',
      caseSensitive: false,
    );
    final timeMatch = timePattern.firstMatch(text);
    if (timeMatch != null) {
      var hour = int.tryParse(timeMatch.group(1) ?? '');
      final minute = int.tryParse(timeMatch.group(2) ?? '0') ?? 0;
      final period = timeMatch.group(3)?.toLowerCase().replaceAll('.', '');
      
      if (hour != null) {
        // Convertir a formato 24 horas
        hour = _convertTo24Hour(hour, period);
        
        var eventDateTime = DateTime(now.year, now.month, now.day, hour, minute);
        
        // Si la hora ya pasó hoy, asumir que es mañana
        if (eventDateTime.isBefore(now)) {
          eventDateTime = eventDateTime.add(const Duration(days: 1));
          logger.debug('[Parser] Time passed today, moving to tomorrow');
        }
        
        logger.debug('[Parser] Date extracted (at time): $eventDateTime');
        return eventDateTime;
      }
    }
    
    // Patrón: "el lunes/martes/etc a las HH:MM"
    final dayOfWeekPattern = RegExp(
      r'el\s+(lunes|martes|miércoles|miercoles|jueves|viernes|sábado|sabado|domingo)(?:\s+a\s+las\s+(\d{1,2})(?::(\d{2}))?)?',
      caseSensitive: false,
    );
    final dayMatch = dayOfWeekPattern.firstMatch(text);
    if (dayMatch != null) {
      final dayName = dayMatch.group(1)?.toLowerCase();
      var hour = int.tryParse(dayMatch.group(2) ?? '12') ?? 12;
      final minute = int.tryParse(dayMatch.group(3) ?? '0') ?? 0;
      
      final targetDay = _getWeekdayFromName(dayName);
      if (targetDay != null) {
        final result = _getNextWeekday(now, targetDay, hour, minute);
        logger.debug('[Parser] Date extracted (day of week): $result');
        return result;
      }
    }
    
    // Si no se encontró ningún patrón de tiempo específico, usar 1 hora por defecto
    final result = now.add(const Duration(hours: 1));
    logger.debug('[Parser] No time pattern found, using default (1 hour): $result');
    return result;
  }
  
  /// Convertir hora a formato 24 horas
  int _convertTo24Hour(int hour, String? period) {
    if (period == null) return hour;
    
    if ((period.contains('tarde') || period == 'pm') && hour < 12) {
      return hour + 12;
    } else if ((period.contains('mañana') || period == 'am') && hour == 12) {
      return 0;
    } else if (period.contains('noche') && hour < 12) {
      return hour + 12;
    }
    
    return hour;
  }
  
  /// Obtener número de día de la semana desde el nombre
  int? _getWeekdayFromName(String? dayName) {
    if (dayName == null) return null;
    
    switch (dayName.toLowerCase()) {
      case 'lunes':
        return DateTime.monday;
      case 'martes':
        return DateTime.tuesday;
      case 'miércoles':
      case 'miercoles':
        return DateTime.wednesday;
      case 'jueves':
        return DateTime.thursday;
      case 'viernes':
        return DateTime.friday;
      case 'sábado':
      case 'sabado':
        return DateTime.saturday;
      case 'domingo':
        return DateTime.sunday;
      default:
        return null;
    }
  }
  
  /// Obtener el próximo día de la semana
  DateTime _getNextWeekday(DateTime from, int targetDay, int hour, int minute) {
    var daysToAdd = targetDay - from.weekday;
    if (daysToAdd <= 0) {
      daysToAdd += 7;
    }
    
    final targetDate = from.add(Duration(days: daysToAdd));
    return DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);
  }
}

/// Comando de evento parseado desde voz
class EventCommand {
  final String title;
  final DateTime eventDate;
  
  const EventCommand({
    required this.title,
    required this.eventDate,
  });
  
  @override
  String toString() => 'EventCommand(title: $title, date: ${DateFormat('dd/MM/yyyy HH:mm').format(eventDate)})';
}