import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/configuration/app_config.dart';
import '../../domain/models.dart';
import '../providers.dart';
import '../widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  
  @override
  void initState() {
    super.initState();
    // Load events when screen is initialized
    Future.microtask(() {
      ref.read(eventsProvider.notifier).loadEvents();
      ref.read(eventsProvider.notifier).loadUpcomingEvents();
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
            _buildProfileScreen(authState),
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
              CircleAvatar(
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
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Main Balance Card
          CustomCard(
            color: AppColors.cardLightBackground,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Events', style: AppTextStyles.bodySecondary),
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
              StatCard(
                title: 'Pending',
                value: pendingCount.toString(),
                percentage: '${((pendingCount / (eventsState.events.isNotEmpty ? eventsState.events.length : 1)) * 100).toStringAsFixed(0)}%',
                icon: Icons.pending_actions,
              ),
              StatCard(
                title: 'Completed',
                value: completedCount.toString(),
                percentage: '${((completedCount / (eventsState.events.isNotEmpty ? eventsState.events.length : 1)) * 100).toStringAsFixed(0)}%',
                icon: Icons.check_circle_outline,
              ),
              StatCard(
                title: 'Upcoming',
                value: eventsState.upcomingEvents.length.toString(),
                icon: Icons.upcoming,
              ),
              StatCard(
                title: 'This Month',
                value: _getThisMonthCount(eventsState.events).toString(),
                icon: Icons.calendar_month,
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
                onPressed: () => setState(() => _selectedIndex = 1),
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
                child: Text(
                  'No upcoming events',
                  style: AppTextStyles.bodySecondary,
                ),
              ),
            )
          else
            ...eventsState.upcomingEvents.take(3).map((event) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: EventCard(
                title: event.title,
                date: event.eventDate,
                status: event.status.name,
                onComplete: () => _completeEvent(event.id),
                onDelete: () => _deleteEvent(event.id),
              ),
            )),
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
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 32),
                onPressed: () => _showAddEventDialog(),
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
                            Icons.event_busy,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'No events yet',
                            style: AppTextStyles.bodySecondary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          CustomButton(
                            text: 'Create Event',
                            onPressed: () => _showAddEventDialog(),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref.read(eventsProvider.notifier).loadEvents();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: eventsState.events.length,
                        itemBuilder: (context, index) {
                          final event = eventsState.events[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: EventCard(
                              title: event.title,
                              date: event.eventDate,
                              status: event.status.name,
                              onComplete: event.status == ReminderStatus.pending
                                  ? () => _completeEvent(event.id)
                                  : null,
                              onDelete: () => _deleteEvent(event.id),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
  
  Widget _buildProfileScreen(AuthState authState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary,
            child: Text(
              authState.user?.username.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          Text(
            authState.user?.fullName ?? authState.user?.username ?? 'User',
            style: AppTextStyles.h2,
          ),
          
          Text(
            authState.user?.email ?? '',
            style: AppTextStyles.bodySecondary,
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          CustomCard(
            child: Column(
              children: [
                _buildProfileItem(Icons.person, 'Username', authState.user?.username ?? ''),
                const Divider(height: 32),
                _buildProfileItem(Icons.email, 'Email', authState.user?.email ?? ''),
                const Divider(height: 32),
                _buildProfileItem(
                  Icons.calendar_today,
                  'Member Since',
                  DateFormat('MMM dd, yyyy').format(authState.user?.createdAt ?? DateTime.now()),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          CustomButton(
            text: 'Sign Out',
            onPressed: () => ref.read(authProvider.notifier).signOut(),
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.body),
          ],
        ),
      ],
    );
  }
  
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
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
  
  // ============================================================================
  // DIALOGS & ACTIONS - VERSIÓN MEJORADA
  // ============================================================================
  
  void _showAddEventDialog() {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1)); // Por defecto 1 hora en el futuro
    
    showDialog(
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
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Event Title',
                  hintText: 'Enter event name',
                  labelStyle: AppTextStyles.bodySecondary,
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
                // Validar que el título no esté vacío
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
                
                // Mostrar loading
                if (!context.mounted) return;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
                
                try {
                  // Crear evento
                  final success = await ref.read(eventsProvider.notifier).createEvent(
                    titleController.text.trim(),
                    selectedDate,
                  );
                  
                  // Cerrar loading
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  
                  if (success) {
                    // Cerrar diálogo de crear evento
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                    
                    // Mostrar mensaje de éxito
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Event created successfully'),
                          backgroundColor: AppColors.success,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                    
                    // Recargar eventos explícitamente
                    await ref.read(eventsProvider.notifier).loadEvents();
                    await ref.read(eventsProvider.notifier).loadUpcomingEvents();
                  } else {
                    // Mostrar error
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
                } catch (e) {
                  // Cerrar loading si hay error
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  
                  // Mostrar error
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