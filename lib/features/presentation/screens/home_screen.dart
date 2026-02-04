import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/configuration/app_config.dart';
import '../../../core/configuration/app_logger.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/voice_command_controller.dart';
import '../../domain/models.dart';
import '../providers.dart';
import 'profile_screen.dart';
import 'dashboard_tab.dart';
import 'events_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _permissionsRequested = false;
  
  // ✅ Filtro para pasar a EventsTab
  String _eventsFilter = 'all';
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    Future.microtask(() {
      ref.read(eventsProvider.notifier).loadEvents();
      ref.read(eventsProvider.notifier).loadUpcomingEvents();
      _requestPermissionsOnFirstLaunch();
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
    
    if (state == AppLifecycleState.resumed) {
      logger.info('[HomeScreen] App resumed from background');
      ref.read(eventsProvider.notifier).loadEvents();
      ref.read(eventsProvider.notifier).loadUpcomingEvents();
      _cleanOldEvents();
    }
  }
  
  Future<void> _cleanOldEvents() async {
    try {
      final events = ref.read(eventsProvider).events;
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      final oldEvents = events.where((event) {
        return (event.status == ReminderStatus.completed || 
                event.status == ReminderStatus.cancelled) &&
               event.eventDate.isBefore(sevenDaysAgo);
      }).toList();
      
      if (oldEvents.isNotEmpty) {
        logger.info('[HomeScreen] Cleaning ${oldEvents.length} old events');
        for (var event in oldEvents) {
          await ref.read(eventsProvider.notifier).deleteEvent(event.id);
        }
        await ref.read(eventsProvider.notifier).loadEvents();
        await ref.read(eventsProvider.notifier).loadUpcomingEvents();
      }
    } catch (e, stackTrace) {
      logger.error('[HomeScreen] Error cleaning old events', e, stackTrace);
    }
  }
  
  Future<void> _requestPermissionsOnFirstLaunch() async {
    if (_permissionsRequested) return;
    _permissionsRequested = true;
    
    try {
      logger.info('[HomeScreen] Requesting permissions...');
      
      final notificationService = NotificationService();
      await notificationService.initialize();
      await notificationService.requestPermissions();
      
      final voiceController = ref.read(voiceCommandControllerProvider.notifier);
      await voiceController.initialize();
      
      if (!mounted) return;
      
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
    } catch (e, stackTrace) {
      logger.error('[HomeScreen] Error requesting permissions', e, stackTrace);
    }
  }
  
  // ✅ Método para navegar a Events tab con filtro
  void _navigateToEvents(String filter) {
    setState(() {
      _selectedIndex = 1;
      _eventsFilter = filter;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            DashboardTab(onNavigateToEvents: _navigateToEvents),
            EventsTab(initialFilter: _eventsFilter),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: AppColors.background,
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
      ),
    );
  }
}