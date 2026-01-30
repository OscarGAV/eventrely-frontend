import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/configuration/app_config.dart';
import '../../../core/configuration/app_logger.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/voice_command_controller.dart';
import '../../domain/models.dart';
import '../providers.dart';
import '../widgets.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _permissionsRequested = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Load events when screen is initialized
    Future.microtask(() {
      ref.read(eventsProvider.notifier).loadEvents();
      ref.read(eventsProvider.notifier).loadUpcomingEvents();
      
      // Solicitar permisos al iniciar la app
      _requestPermissionsOnFirstLaunch();
      
      // Limpiar eventos antiguos automáticamente
      _cleanOldEvents();
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Prevenir que la app se cierre por inactividad
    if (state == AppLifecycleState.resumed) {
      logger.info('[HomeScreen] App resumed from background');
      // Recargar eventos al volver
      ref.read(eventsProvider.notifier).loadEvents();
      ref.read(eventsProvider.notifier).loadUpcomingEvents();
      // Limpiar eventos antiguos
      _cleanOldEvents();
    } else if (state == AppLifecycleState.paused) {
      logger.info('[HomeScreen] App paused to background');
    }
  }
  
  /// Limpiar eventos que finalizaron hace más de 7 días
  Future<void> _cleanOldEvents() async {
    try {
      final events = ref.read(eventsProvider).events;
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      
      // Filtrar eventos que finalizaron hace más de 7 días
      final oldEvents = events.where((event) {
        // Solo eliminar eventos completados o cancelados
        if (event.status != ReminderStatus.completed && 
            event.status != ReminderStatus.cancelled) {
          return false;
        }
        
        // Verificar si el evento terminó hace más de 7 días
        return event.eventDate.isBefore(sevenDaysAgo);
      }).toList();
      
      if (oldEvents.isNotEmpty) {
        logger.info('[HomeScreen] Cleaning ${oldEvents.length} old events');
        
        // Eliminar eventos antiguos
        for (var event in oldEvents) {
          await ref.read(eventsProvider.notifier).deleteEvent(event.id);
        }
        
        // Recargar eventos
        await ref.read(eventsProvider.notifier).loadEvents();
        await ref.read(eventsProvider.notifier).loadUpcomingEvents();
        
        logger.info('[HomeScreen] Old events cleaned successfully');
      }
    } catch (e, stackTrace) {
      logger.error('[HomeScreen] Error cleaning old events', e, stackTrace);
    }
  }
  
  /// Solicitar permisos la primera vez que se abre la app
  Future<void> _requestPermissionsOnFirstLaunch() async {
    if (_permissionsRequested) return;
    _permissionsRequested = true;
    
    try {
      logger.info('[HomeScreen] Requesting permissions on first launch...');
      
      // Inicializar servicios
      final notificationService = NotificationService();
      await notificationService.initialize();
      
      // Solicitar permisos de notificaciones
      final notificationGranted = await notificationService.requestPermissions();
      logger.info('[HomeScreen] Notification permission: $notificationGranted');
      
      // Inicializar voice controller
      final voiceController = ref.read(voiceCommandControllerProvider.notifier);
      await voiceController.initialize();
      
      // Solicitar permisos de micrófono
      if (mounted) {
        final shouldAskMic = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.mic, color: AppColors.primary),
                SizedBox(width: 12),
                Text('Voice Commands', style: AppTextStyles.h3),
              ],
            ),
            content: const Text(
              'Allow microphone access to create events using voice commands?\n\n'
              'You can say things like:\n'
              '• "Evento reunión mañana a las 3pm"\n'
              '• "Recordatorio llamar a Juan en 2 horas"',
              style: AppTextStyles.body,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not now'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Allow'),
              ),
            ],
          ),
        );
        
        if (shouldAskMic == true) {
          await voiceController.startVoiceService();
        }
      }
      
      logger.info('[HomeScreen] Permissions requested successfully');
    } catch (e, stackTrace) {
      logger.error('[HomeScreen] Error requesting permissions', e, stackTrace);
    }
  }
  
  // Método para cambiar de pestaña programáticamente
  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final eventsState = ref.watch(eventsProvider);
    final pendingCount = ref.watch(pendingEventsCountProvider);
    final completedCount = ref.watch(completedEventsCountProvider);
    
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildDashboard(authState, eventsState, pendingCount, completedCount),
            _buildEventsScreen(eventsState),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
  
  Widget _buildDashboard(
    AuthState authState,
    EventsState eventsState,
    int pendingCount,
    int completedCount,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi ${authState.user?.username ?? "User"}',
                    style: AppTextStyles.h2,
                  ),
                  const Text(
                    'Welcome Back',
                    style: AppTextStyles.bodySecondary,
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _navigateToTab(2),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    authState.user?.username.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Main Total Events Card
          CustomCard(
            color: AppColors.cardLightBackground,
            onTap: () => _navigateToTab(1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Events', style: AppTextStyles.bodySecondary),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      eventsState.events.length.toString(),
                      style: AppTextStyles.h1,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_upward,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${((completedCount / (eventsState.events.isNotEmpty ? eventsState.events.length : 1)) * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Statistics Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.5,
            children: [
              GestureDetector(
                onTap: () => _navigateToTab(1),
                child: StatCard(
                  title: 'Pending',
                  value: pendingCount.toString(),
                  percentage: '${((pendingCount / (eventsState.events.isNotEmpty ? eventsState.events.length : 1)) * 100).toStringAsFixed(0)}%',
                  icon: Icons.pending_actions,
                ),
              ),
              GestureDetector(
                onTap: () => _navigateToTab(1),
                child: StatCard(
                  title: 'Completed',
                  value: completedCount.toString(),
                  percentage: '${((completedCount / (eventsState.events.isNotEmpty ? eventsState.events.length : 1)) * 100).toStringAsFixed(0)}%',
                  icon: Icons.check_circle_outline,
                ),
              ),
              GestureDetector(
                onTap: () => _navigateToTab(1),
                child: StatCard(
                  title: 'Upcoming',
                  value: eventsState.upcomingEvents.length.toString(),
                  icon: Icons.upcoming,
                ),
              ),
              GestureDetector(
                onTap: () => _navigateToTab(1),
                child: StatCard(
                  title: 'This Month',
                  value: _getThisMonthCount(eventsState.events).toString(),
                  icon: Icons.calendar_month,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Upcoming Events Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Upcoming Events', style: AppTextStyles.h3),
              TextButton(
                onPressed: () => _navigateToTab(1),
                child: const Text('See All'),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          if (eventsState.isLoading)
            const LoadingWidget()
          else if (eventsState.upcomingEvents.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'No upcoming events',
                      style: AppTextStyles.bodySecondary,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: eventsState.upcomingEvents.length > 5 
                ? 5 
                : eventsState.upcomingEvents.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final event = eventsState.upcomingEvents[index];
                return EventCard(
                  title: event.title,
                  date: event.eventDate,
                  status: event.status.name,
                  onTap: () => _showEditEventDialog(event),
                  onComplete: () => _completeEvent(event.id),
                  onDelete: () => _deleteEvent(event.id),
                );
              },
            ),
        ],
      ),
    );
  }
  
  Widget _buildEventsScreen(EventsState eventsState) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('All Events', style: AppTextStyles.h2),
              ElevatedButton.icon(
                onPressed: _showCreateEventDialog,
                icon: const Icon(Icons.add),
                label: const Text('New'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: eventsState.isLoading
              ? const LoadingWidget()
              : eventsState.events.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.event_available,
                            size: 80,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'No events yet',
                            style: AppTextStyles.h3,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const Text(
                            'Create your first event to get started',
                            style: AppTextStyles.bodySecondary,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ElevatedButton.icon(
                            onPressed: _showCreateEventDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Create Event'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: eventsState.events.length,
                      separatorBuilder: (context, index) => 
                        const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final event = eventsState.events[index];
                        return EventCard(
                          title: event.title,
                          date: event.eventDate,
                          status: event.status.name,
                          onTap: () => _showEditEventDialog(event),
                          onComplete: () => _completeEvent(event.id),
                          onDelete: () => _deleteEvent(event.id),
                        );
                      },
                    ),
        ),
      ],
    );
  }
  
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      backgroundColor: AppColors.cardBackground,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event_note),
          label: 'Events',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
  
  /// Mostrar diálogo para EDITAR evento
  void _showEditEventDialog(Event event) async {
    final titleController = TextEditingController(text: event.title);
    DateTime selectedDate = event.eventDate;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit, color: AppColors.primary),
              SizedBox(width: 12),
              Text('Edit Event', style: AppTextStyles.h3),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  labelText: 'Event Title',
                  hintText: 'Enter event title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              InkWell(
                onTap: () async {
                  if (!context.mounted) return;
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
                      setDialogState(() {
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
                },
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
              const SizedBox(height: AppSpacing.md),
              // Estado del evento
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.cardLightBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Status: ${event.status.name.toUpperCase()}',
                      style: AppTextStyles.bodySecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
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
                
                if (!context.mounted) return;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
                
                try {
                  final success = await ref.read(eventsProvider.notifier).updateEvent(
                    event.id,
                    titleController.text.trim(),
                    selectedDate,
                  );
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  
                  if (success) {
                    // Cancelar notificación anterior
                    final notificationService = NotificationService();
                    await notificationService.cancelEventReminder(event.id);
                    
                    // Programar nueva notificación
                    await notificationService.scheduleEventReminder(
                      eventId: event.id,
                      title: titleController.text.trim(),
                      eventDate: selectedDate,
                    );
                    logger.info('[HomeScreen] Notification rescheduled for event ${event.id}');
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Event updated successfully'),
                          backgroundColor: AppColors.success,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                    
                    await ref.read(eventsProvider.notifier).loadEvents();
                    await ref.read(eventsProvider.notifier).loadUpcomingEvents();
                  } else {
                    if (context.mounted) {
                      final errorMessage = ref.read(eventsProvider).error ?? 'Failed to update event';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ $errorMessage'),
                          backgroundColor: AppColors.error,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                } catch (e, stackTrace) {
                  logger.error('[HomeScreen] Error updating event', e, stackTrace);
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Error: $e'),
                        backgroundColor: AppColors.error,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Mostrar diálogo para CREAR evento
  void _showCreateEventDialog() async {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Create Event', style: AppTextStyles.h3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  labelText: 'Event Title',
                  hintText: 'Enter event title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              InkWell(
                onTap: () async {
                  if (!context.mounted) return;
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
                      setDialogState(() {
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
                },
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
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
                
                if (!context.mounted) return;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
                
                try {
                  final success = await ref.read(eventsProvider.notifier).createEvent(
                    titleController.text.trim(),
                    selectedDate,
                  );
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  
                  if (success) {
                    // Programar notificación para el evento
                    final notificationService = NotificationService();
                    final events = ref.read(eventsProvider).events;
                    if (events.isNotEmpty) {
                      final newEvent = events.last;
                      await notificationService.scheduleEventReminder(
                        eventId: newEvent.id,
                        title: newEvent.title,
                        eventDate: newEvent.eventDate,
                      );
                      logger.info('[HomeScreen] Notification scheduled for event ${newEvent.id}');
                    }
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Event created successfully'),
                          backgroundColor: AppColors.success,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                    
                    await ref.read(eventsProvider.notifier).loadEvents();
                    await ref.read(eventsProvider.notifier).loadUpcomingEvents();
                  } else {
                    if (context.mounted) {
                      final errorMessage = ref.read(eventsProvider).error ?? 'Failed to create event';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ $errorMessage'),
                          backgroundColor: AppColors.error,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                } catch (e, stackTrace) {
                  logger.error('[HomeScreen] Error creating event', e, stackTrace);
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Error: $e'),
                        backgroundColor: AppColors.error,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _completeEvent(int id) async {
    final success = await ref.read(eventsProvider.notifier).completeEvent(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Event marked as completed'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
  
  void _deleteEvent(int id) async {
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Event', style: AppTextStyles.h3),
        content: const Text('Are you sure you want to delete this event?'),
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
      // Cancelar notificación programada
      final notificationService = NotificationService();
      await notificationService.cancelEventReminder(id);
      
      final success = await ref.read(eventsProvider.notifier).deleteEvent(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Event deleted'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  int _getThisMonthCount(List<Event> events) {
    final now = DateTime.now();
    return events.where((e) =>
      e.eventDate.year == now.year &&
      e.eventDate.month == now.month
    ).length;
  }
}