import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/configuration/app_config.dart';
import '../../domain/models.dart';
import '../providers.dart';
import '../widgets.dart';
import 'event_dialogs.dart';

class EventsTab extends ConsumerStatefulWidget {
  final String initialFilter;
  
  const EventsTab({super.key, this.initialFilter = 'all'});
  
  @override
  ConsumerState<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends ConsumerState<EventsTab> {
  late String _selectedFilter;
  
  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
  }
  
  @override
  void didUpdateWidget(EventsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilter != oldWidget.initialFilter) {
      setState(() {
        _selectedFilter = widget.initialFilter;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventsProvider);
    
    if (eventsState.isLoading) {
      return const LoadingWidget();
    }
    
    final filteredEvents = _filterEvents(eventsState.events);
    
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(eventsProvider.notifier).loadEvents();
      },
      child: Column(
        children: [
          _buildHeader(),
          _buildFilterChips(),
          Expanded(
            child: filteredEvents.isEmpty
                ? _buildEmptyState()
                : _buildEventsList(filteredEvents),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('All Events', style: AppTextStyles.h2),
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 32),
            onPressed: () async {
              await EventDialogs.showCreateEventDialog(context);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChips() {
    return SizedBox(
      height: 50,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('all', 'All', Icons.list),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip('pending', 'Pending', Icons.pending_actions),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip('completed', 'Completed', Icons.check_circle),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String filter, String label, IconData icon) {
    final isSelected = _selectedFilter == filter;
    
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() => _selectedFilter = filter);
      },
      backgroundColor: AppColors.cardBackground,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
    );
  }
  
  Widget _buildEventsList(List<Event> events) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: events.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final event = events[index];
        return EventCard(
          title: event.title,
          date: event.eventDate,
          status: event.status.name,
          onTap: () => EventDialogs.showEventDetailsDialog(context, ref, event),
          onComplete: event.status == ReminderStatus.pending
              ? () async {
                  await EventDialogs.completeEvent(ref, event.id);
                  await ref.read(eventsProvider.notifier).loadEvents();
                }
              : null,
          onDelete: () async {
            await EventDialogs.deleteEvent(ref, event.id);
            await ref.read(eventsProvider.notifier).loadEvents();
          },
        );
      },
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy, size: 80, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.md),
          Text(
            _getEmptyMessage(),
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Tap + to create your first event',
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
  
  String _getEmptyMessage() {
    switch (_selectedFilter) {
      case 'pending':
        return 'No pending events';
      case 'completed':
        return 'No completed events';
      default:
        return 'No events yet';
    }
  }
  
  List<Event> _filterEvents(List<Event> events) {
    switch (_selectedFilter) {
      case 'pending':
        return events.where((e) => e.status == ReminderStatus.pending).toList();
      case 'completed':
        return events.where((e) => e.status == ReminderStatus.completed).toList();
      default:
        return events;
    }
  }
}