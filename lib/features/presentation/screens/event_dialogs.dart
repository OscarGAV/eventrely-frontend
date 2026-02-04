import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/configuration/app_config.dart';
import '../../../core/configuration/app_logger.dart';
import '../../../core/services/notification_service.dart';
import '../../domain/models.dart';
import '../providers.dart';

class EventDialogs {
  /// Mostrar diálogo para crear evento
  static Future<void> showCreateEventDialog(BuildContext context) async {
    if (!context.mounted) return;
    
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    
    await showDialog(
      context: context,
      builder: (context) => _CreateEventDialog(
        initialDate: selectedDate,
      ),
    );
  }
  
  /// Mostrar diálogo de detalles del evento con opción de editar
  static Future<void> showEventDetailsDialog(
    BuildContext context,
    WidgetRef ref,
    Event event,
  ) async {
    if (!context.mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) => _EventDetailsDialog(event: event, ref: ref),
    );
  }
  
  /// Mostrar diálogo para EDITAR evento
  static Future<void> showEditEventDialog(
    BuildContext context,
    WidgetRef ref,
    Event event,
  ) async {
    if (!context.mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) => _EditEventDialog(event: event),
    );
  }
  
  /// Completar evento
  static Future<void> completeEvent(WidgetRef ref, int eventId) async {
    final success = await ref.read(eventsProvider.notifier).completeEvent(eventId);
    
    if (success && ref.context.mounted) {
      ScaffoldMessenger.of(ref.context).showSnackBar(
        const SnackBar(
          content: Text('Event marked as completed'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  /// Eliminar evento
  static Future<void> deleteEvent(WidgetRef ref, int eventId) async {
    if (!ref.context.mounted) return;
    
    final confirm = await showDialog<bool>(
      context: ref.context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Event', style: AppTextStyles.h3),
        content: const Text(
          'Are you sure you want to delete this event?',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final notificationService = NotificationService();
      await notificationService.cancelEventReminder(eventId);
      
      final success = await ref.read(eventsProvider.notifier).deleteEvent(eventId);
      
      if (success && ref.context.mounted) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          const SnackBar(
            content: Text('Event deleted'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

// =============================================================================
// DIÁLOGO DE CREAR EVENTO
// =============================================================================

class _CreateEventDialog extends ConsumerStatefulWidget {
  final DateTime initialDate;
  
  const _CreateEventDialog({
    required this.initialDate,
  });
  
  @override
  ConsumerState<_CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends ConsumerState<_CreateEventDialog> {
  late DateTime selectedDate;
  late TextEditingController titleController;
  bool _isCreating = false;
  
  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    titleController = TextEditingController();
  }
  
  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Create Event', style: AppTextStyles.h3),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              enabled: !_isCreating,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                labelText: 'Event Title',
                hintText: 'Enter event title',
                filled: true,
                fillColor: AppColors.cardLightBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Event Date & Time', style: AppTextStyles.bodySecondary),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: _isCreating ? null : () => _selectDateTime(context),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.textSecondary),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      DateFormat('MMM dd, yyyy HH:mm').format(selectedDate),
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: _isCreating ? null : () => _createEvent(context),
          child: _isCreating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
  
  Future<void> _selectDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDate),
      );
      
      if (time != null) {
        setState(() {
          selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }
  
  Future<void> _createEvent(BuildContext context) async {
    if (titleController.text.trim().isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an event title'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    final title = titleController.text.trim();
    final eventDate = selectedDate;
    
    setState(() {
      _isCreating = true;
    });
    
    try {
      final newEvent = await ref.read(eventsProvider.notifier).createEvent(
        title,
        eventDate,
      );
      
      if (!context.mounted) return;
      
      if (newEvent != null) {
        logger.info('[EventDialogs] Event created with ID: ${newEvent.id}');
        
        final notificationService = NotificationService();
        await notificationService.scheduleEventReminder(
          eventId: newEvent.id,
          title: newEvent.title,
          eventDate: newEvent.eventDate,
          minutesBefore: 5,
        );
        
        await ref.read(eventsProvider.notifier).loadEvents();
        await ref.read(eventsProvider.notifier).loadUpcomingEvents();
        
        if (!context.mounted) return;
        
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event created successfully'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _isCreating = false;
        });
        
        if (!context.mounted) return;
        
        final errorMessage = ref.read(eventsProvider).error ?? 'Failed to create event';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      logger.error('[EventDialogs] Error creating event', e, stackTrace);
      
      setState(() {
        _isCreating = false;
      });
      
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

// =============================================================================
// DIÁLOGO DE EDITAR EVENTO
// =============================================================================

class _EditEventDialog extends ConsumerStatefulWidget {
  final Event event;
  
  const _EditEventDialog({
    required this.event,
  });
  
  @override
  ConsumerState<_EditEventDialog> createState() => _EditEventDialogState();
}

class _EditEventDialogState extends ConsumerState<_EditEventDialog> {
  late DateTime selectedDate;
  late TextEditingController titleController;
  bool _isUpdating = false;
  
  @override
  void initState() {
    super.initState();
    selectedDate = widget.event.eventDate;
    titleController = TextEditingController(text: widget.event.title);
  }
  
  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Edit Event', style: AppTextStyles.h3),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              enabled: !_isUpdating,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                labelText: 'Event Title',
                hintText: 'Enter event title',
                filled: true,
                fillColor: AppColors.cardLightBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Event Date & Time', style: AppTextStyles.bodySecondary),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: _isUpdating ? null : () => _selectDateTime(context),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.textSecondary),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      DateFormat('MMM dd, yyyy HH:mm').format(selectedDate),
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUpdating ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: _isUpdating ? null : () => _updateEvent(context),
          child: _isUpdating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
  
  Future<void> _selectDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDate),
      );
      
      if (time != null) {
        setState(() {
          selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }
  
  Future<void> _updateEvent(BuildContext context) async {
    if (titleController.text.trim().isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an event title'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    final title = titleController.text.trim();
    final eventDate = selectedDate;
    
    setState(() {
      _isUpdating = true;
    });
    
    try {
      final success = await ref.read(eventsProvider.notifier).updateEvent(
        widget.event.id,
        title,
        eventDate,
      );
      
      if (!context.mounted) return;
      
      if (success) {
        logger.info('[EventDialogs] Event updated: ${widget.event.id}');
        
        // Cancelar notificaciones antiguas
        final notificationService = NotificationService();
        await notificationService.cancelEventReminder(widget.event.id);
        
        // Programar nuevas notificaciones
        await notificationService.scheduleEventReminder(
          eventId: widget.event.id,
          title: title,
          eventDate: eventDate,
          minutesBefore: 5,
        );
        
        await ref.read(eventsProvider.notifier).loadEvents();
        await ref.read(eventsProvider.notifier).loadUpcomingEvents();
        
        if (!context.mounted) return;
        
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event updated successfully'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _isUpdating = false;
        });
        
        if (!context.mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update event'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      logger.error('[EventDialogs] Error updating event', e, stackTrace);
      
      setState(() {
        _isUpdating = false;
      });
      
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

// =============================================================================
// DIÁLOGO DE DETALLES DEL EVENTO
// =============================================================================

class _EventDetailsDialog extends StatelessWidget {
  final Event event;
  final WidgetRef ref;
  
  const _EventDetailsDialog({
    required this.event,
    required this.ref,
  });
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(event.title, style: AppTextStyles.h3),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            Icons.calendar_today,
            'Date',
            DateFormat('MMM dd, yyyy').format(event.eventDate),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildDetailRow(
            Icons.access_time,
            'Time',
            DateFormat('HH:mm').format(event.eventDate),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildDetailRow(
            Icons.info_outline,
            'Status',
            event.status.name.toUpperCase(),
          ),
        ],
      ),
      actions: [
        // BOTÓN DE EDITAR
        TextButton.icon(
          onPressed: () {
            Navigator.pop(context);
            EventDialogs.showEditEventDialog(context, ref, event);
          },
          icon: const Icon(Icons.edit, color: AppColors.primary),
          label: const Text('Edit', style: TextStyle(color: AppColors.primary)),
        ),
        if (event.status == ReminderStatus.pending) ...[
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              EventDialogs.completeEvent(ref, event.id);
            },
            icon: const Icon(Icons.check_circle, color: AppColors.success),
            label: const Text('Complete', style: TextStyle(color: AppColors.success)),
          ),
        ],
        TextButton.icon(
          onPressed: () {
            Navigator.pop(context);
            EventDialogs.deleteEvent(ref, event.id);
          },
          icon: const Icon(Icons.delete, color: AppColors.error),
          label: const Text('Delete', style: TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }
  
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text('$label: ', style: AppTextStyles.bodySecondary),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}