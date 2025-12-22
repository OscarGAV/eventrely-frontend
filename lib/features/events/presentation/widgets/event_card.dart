import 'package:flutter/material.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/event_entity.dart';

class EventCard extends StatelessWidget {
  final EventEntity event;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;
  
  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onComplete,
    this.onDelete,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con título y estado
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(),
                ],
              ),
              
              if (event.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  event.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Fecha y hora
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    DateTimeUtils.formatDisplayDate(event.eventDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (event.isPending) _buildTimeUntil(),
                ],
              ),
              
              // Botones de acción
              if (event.isPending) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onComplete != null)
                      TextButton.icon(
                        onPressed: onComplete,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Completar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                      ),
                    if (onDelete != null)
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Eliminar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusChip() {
    Color color;
    IconData icon;
    String label;
    
    if (event.isPending) {
      color = Colors.orange;
      icon = Icons.schedule;
      label = 'Pendiente';
    } else if (event.isCompleted) {
      color = Colors.green;
      icon = Icons.check_circle;
      label = 'Completado';
    } else if (event.isCancelled) {
      color = Colors.grey;
      icon = Icons.cancel;
      label = 'Cancelado';
    } else {
      color = Colors.red;
      icon = Icons.event_busy;
      label = 'Expirado';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeUntil() {
    final timeUntil = DateTimeUtils.timeUntilEvent(event.eventDate);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 14, color: Colors.blue[700]),
          const SizedBox(width: 4),
          Text(
            timeUntil,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}