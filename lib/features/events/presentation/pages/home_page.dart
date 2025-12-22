import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/config/themes/app_theme.dart';
import '../../../../core/config/ui_helpers.dart';
import '../bloc/event_bloc.dart';
import '../bloc/event_event.dart';
import '../bloc/event_state.dart';
import '../widgets/event_card.dart';
import 'create_event_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _loadEvents();
  }
  
  void _loadEvents() {
    context.read<EventBloc>().add(
      LoadUpcomingEvents(AppConstants.userId),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27), // Fondo oscuro sólido
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.event_note_rounded, size: 24),
            ),
            UIHelpers.horizontalSpaceSmall,
            const Text(
              'EventRELY',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A0E27),
        elevation: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.refresh_rounded, size: 20),
            ),
            onPressed: _loadEvents,
            tooltip: 'Actualizar',
          ),
          UIHelpers.horizontalSpaceSmall,
        ],
      ),
      body: BlocConsumer<EventBloc, EventState>(
        listener: (context, state) {
          if (state is EventOperationSuccess) {
            UIHelpers.showSnackBar(
              context,
              state.message,
              isSuccess: true,
            );
            _loadEvents();
          } else if (state is EventError) {
            UIHelpers.showSnackBar(
              context,
              state.message,
              isError: true,
            );
          }
        },
        builder: (context, state) {
          if (state is EventLoading) {
            return UIHelpers.buildLoadingIndicator(
              message: 'Cargando eventos...',
            );
          }
          
          if (state is EventsLoaded) {
            if (state.events.isEmpty) {
              return _buildEmptyState();
            }
            
            return RefreshIndicator(
              onRefresh: () async => _loadEvents(),
              color: AppTheme.primaryColor,
              backgroundColor: AppTheme.cardColor,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 16, bottom: 100),
                itemCount: state.events.length,
                itemBuilder: (context, index) {
                  final event = state.events[index];
                  return EventCard(
                    event: event,
                    onComplete: () => _showCompleteDialog(event.id),
                    onDelete: () => _showDeleteDialog(event.id),
                  );
                },
              ),
            );
          }
          
          return _buildEmptyState();
        },
      ),
      floatingActionButton: _buildModernFAB(),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: UIHelpers.paddingAll,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono con gradiente
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.2),
                    AppTheme.secondaryColor.withValues(alpha: 0.2),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                size: 80,
                color: AppTheme.primaryColor,
              ),
            ),
            
            UIHelpers.verticalSpaceLarge,
            
            const Text(
              'No hay eventos próximos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            UIHelpers.verticalSpaceSmall,
            
            Text(
              'Crea tu primer recordatorio para\nno olvidar nada importante',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            
            UIHelpers.verticalSpaceLarge,
            
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateEvent(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear Primer Evento'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildModernFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateEvent(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nuevo Evento',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
  
  void _navigateToCreateEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<EventBloc>(),
          child: const CreateEventPage(),
        ),
      ),
    );
    
    if (result == true) {
      _loadEvents();
    }
  }
  
  void _showCompleteDialog(int eventId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.successColor,
              ),
            ),
            UIHelpers.horizontalSpaceMedium,
            const Text(
              'Completar Evento',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          '¿Marcar este evento como completado?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.read<EventBloc>().add(CompleteEventRequested(eventId));
            },
            icon: const Icon(Icons.check_rounded),
            label: const Text('Completar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteDialog(int eventId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_rounded,
                color: AppTheme.errorColor,
              ),
            ),
            UIHelpers.horizontalSpaceMedium,
            const Text(
              'Eliminar Evento',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar este evento?\nEsta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.read<EventBloc>().add(DeleteEventRequested(eventId));
            },
            icon: const Icon(Icons.delete_rounded),
            label: const Text('Eliminar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }
}