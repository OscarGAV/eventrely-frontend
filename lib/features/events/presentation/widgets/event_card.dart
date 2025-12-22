import 'package:flutter/material.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/event_entity.dart';
import '../../../../core/config/ui_helpers.dart';

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E), // Fondo oscuro sólido
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Título y Badge de estado
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    UIHelpers.horizontalSpaceSmall,
                    _buildStatusBadge(),
                  ],
                ),
                
                // Descripción (si existe)
                if (event.description != null && event.description!.isNotEmpty) ...[
                  UIHelpers.verticalSpaceSmall,
                  Text(
                    event.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                UIHelpers.verticalSpaceMedium,
                
                // Fecha y Hora
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateTimeUtils.formatDisplayDate(event.eventDate),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                
                // Tiempo restante
                if (event.isPending) ...[
                  UIHelpers.verticalSpaceSmall,
                  _buildTimeRemaining(),
                ],
                
                // Botones de acción
                if (event.isPending && (onComplete != null || onDelete != null)) ...[
                  UIHelpers.verticalSpaceMedium,
                  Row(
                    children: [
                      // Botón Completar
                      if (onComplete != null)
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.check_rounded,
                            label: 'Completar',
                            color: const Color(0xFF4CAF50),
                            onTap: onComplete!,
                          ),
                        ),
                      
                      if (onComplete != null && onDelete != null)
                        UIHelpers.horizontalSpaceSmall,
                      
                      // Botón Eliminar
                      if (onDelete != null)
                        _buildDeleteButton(),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusBadge() {
    String label;
    Color color;
    
    if (event.isPending) {
      label = 'Pendiente';
      color = const Color(0xFF6C63FF);
    } else if (event.isCompleted) {
      label = 'Completado';
      color = const Color(0xFF4CAF50);
    } else if (event.isCancelled) {
      label = 'Cancelado';
      color = const Color(0xFFFF5252);
    } else {
      label = 'Expirado';
      color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeRemaining() {
    final timeUntil = DateTimeUtils.timeUntilEvent(event.eventDate);
    final now = DateTime.now();
    final difference = event.eventDate.difference(now);
    
    Color color;
    IconData icon;
    
    if (difference.isNegative) {
      return const SizedBox.shrink();
    } else if (difference.inDays > 0) {
      color = const Color(0xFF00B0FF);
      icon = Icons.schedule_rounded;
    } else if (difference.inHours > 1) {
      color = const Color(0xFFFFD600);
      icon = Icons.schedule_rounded;
    } else {
      color = const Color(0xFFFF5252);
      icon = Icons.alarm_rounded;
    }
    
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          'en $timeUntil',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDeleteButton() {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onDelete,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFF5252).withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFF5252).withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            size: 20,
            color: Color(0xFFFF5252),
          ),
        ),
      ),
    );
  }
}