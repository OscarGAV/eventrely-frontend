import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/configuration/app_config.dart';
import '../../domain/models.dart';
import '../providers.dart';
import '../widgets.dart';
import 'event_dialogs.dart';

class DashboardTab extends ConsumerWidget {
  final void Function(String filter)? onNavigateToEvents;
  
  const DashboardTab({super.key, this.onNavigateToEvents});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final eventsState = ref.watch(eventsProvider);
    final pendingCount = ref.watch(pendingEventsCountProvider);
    final completedCount = ref.watch(completedEventsCountProvider);
    
    if (eventsState.isLoading) {
      return const LoadingWidget();
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(eventsProvider.notifier).loadEvents();
        await ref.read(eventsProvider.notifier).loadUpcomingEvents();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(authState),
            const SizedBox(height: AppSpacing.xl),
            _buildStatsCards(pendingCount, completedCount, eventsState.events),
            const SizedBox(height: AppSpacing.xl),
            _buildChart(eventsState.events),
            const SizedBox(height: AppSpacing.xl),
            _buildUpcomingEvents(ref, eventsState.upcomingEvents),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(AuthState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hi ${authState.user?.username ?? "User"}', style: AppTextStyles.h2),
        const SizedBox(height: 4),
        const Text('Here\'s your event overview', style: AppTextStyles.bodySecondary),
      ],
    );
  }
  
  Widget _buildStatsCards(int pendingCount, int completedCount, List<Event> events) {
    final thisMonthCount = _getThisMonthCount(events);
    
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => onNavigateToEvents?.call('pending'),
            borderRadius: BorderRadius.circular(20),
            child: StatCard(
              title: 'Pending',
              value: pendingCount.toString(),
              icon: Icons.pending_actions,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: InkWell(
            onTap: () => onNavigateToEvents?.call('completed'),
            borderRadius: BorderRadius.circular(20),
            child: StatCard(
              title: 'Completed',
              value: completedCount.toString(),
              icon: Icons.check_circle_outline,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: InkWell(
            onTap: () => onNavigateToEvents?.call('all'),
            borderRadius: BorderRadius.circular(20),
            child: StatCard(
              title: 'This Month',
              value: thisMonthCount.toString(),
              icon: Icons.calendar_month,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildChart(List<Event> events) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Events This Week', style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
            child: events.isEmpty
                ? const Center(
                    child: Text(
                      'No events to display',
                      style: AppTextStyles.bodySecondary,
                    ),
                  )
                : _EventsBarChart(events: events),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUpcomingEvents(WidgetRef ref, List<Event> upcomingEvents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Upcoming Events', style: AppTextStyles.h3),
            Builder(
              builder: (context) => TextButton.icon(
                onPressed: () async {
                  await EventDialogs.showCreateEventDialog(context);
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (upcomingEvents.isEmpty)
          const CustomCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    Icon(Icons.event_available, size: 64, color: AppColors.textSecondary),
                    SizedBox(height: AppSpacing.md),
                    Text('No upcoming events', style: AppTextStyles.bodySecondary),
                  ],
                ),
              ),
            ),
          )
        else
          ...upcomingEvents.take(5).map((event) => Builder(
                builder: (context) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: EventCard(
                    title: event.title,
                    date: event.eventDate,
                    status: event.status.name,
                    onTap: () => EventDialogs.showEventDetailsDialog(context, ref, event),
                    onComplete: event.status == ReminderStatus.pending
                        ? () async {
                            await EventDialogs.completeEvent(ref, event.id);
                            await ref.read(eventsProvider.notifier).loadEvents();
                            await ref.read(eventsProvider.notifier).loadUpcomingEvents();
                          }
                        : null,
                    onDelete: () async {
                      await EventDialogs.deleteEvent(ref, event.id);
                      await ref.read(eventsProvider.notifier).loadEvents();
                      await ref.read(eventsProvider.notifier).loadUpcomingEvents();
                    },
                  ),
                ),
              )),
      ],
    );
  }
  
  int _getThisMonthCount(List<Event> events) {
    final now = DateTime.now();
    return events.where((e) => 
      e.eventDate.year == now.year && e.eventDate.month == now.month
    ).length;
  }
}

class _EventsBarChart extends StatelessWidget {
  final List<Event> events;
  
  const _EventsBarChart({required this.events});
  
  @override
  Widget build(BuildContext context) {
    final weekData = _getWeekData();
    final maxValue = weekData.values.isEmpty ? 5.0 : weekData.values.reduce((a, b) => a > b ? a : b).toDouble();
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue < 5 ? 5 : maxValue + 2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    days[value.toInt() % 7],
                    style: AppTextStyles.caption,
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: weekData.entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: AppColors.primary,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
  
  Map<int, int> _getWeekData() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    final data = <int, int>{
      for (var i = 0; i < 7; i++) i: 0,
    };
    
    for (var event in events) {
      final daysDiff = event.eventDate.difference(weekStart).inDays;
      if (daysDiff >= 0 && daysDiff < 7) {
        data[daysDiff] = (data[daysDiff] ?? 0) + 1;
      }
    }
    
    return data;
  }
}