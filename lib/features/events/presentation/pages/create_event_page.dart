import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/config/themes/app_theme.dart';
import '../../../../core/config/ui_helpers.dart';
import '../../domain/entities/event_entity.dart';
import '../bloc/event_bloc.dart';
import '../bloc/event_event.dart';
import '../bloc/event_state.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});
  
  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Nuevo Evento',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.backgroundColor.withBlue(30),
            ],
          ),
        ),
        child: BlocConsumer<EventBloc, EventState>(
          listener: (context, state) {
            if (state is EventOperationSuccess) {
              Navigator.pop(context, true);
            } else if (state is EventError) {
              UIHelpers.showSnackBar(
                context,
                state.message,
                isError: true,
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is EventLoading;
            
            return SingleChildScrollView(
              padding: const EdgeInsets.only(
                top: 100,
                left: 16,
                right: 16,
                bottom: 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Título
                    _buildModernTextField(
                      controller: _titleController,
                      label: 'Título',
                      hint: 'Ej: Pagar alquiler',
                      icon: Icons.title_rounded,
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El título es requerido';
                        }
                        return null;
                      },
                    ),

                    UIHelpers.verticalSpaceLarge,
                    
                    // Sección de Fecha y Hora
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.glassCardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.schedule_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              UIHelpers.horizontalSpaceSmall,
                              const Text(
                                'Fecha y Hora',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          
                          UIHelpers.verticalSpaceMedium,
                          
                          // Fecha
                          _buildDateTimeTile(
                            icon: Icons.calendar_today_rounded,
                            label: 'Fecha',
                            value: DateTimeUtils.formatShortDate(_selectedDate),
                            color: AppTheme.primaryColor,
                            onTap: isLoading ? null : _selectDate,
                          ),
                          
                          UIHelpers.verticalSpaceSmall,
                          
                          // Hora
                          _buildDateTimeTile(
                            icon: Icons.access_time_rounded,
                            label: 'Hora',
                            value: _selectedTime.format(context),
                            color: AppTheme.secondaryColor,
                            onTap: isLoading ? null : _selectTime,
                          ),
                        ],
                      ),
                    ),
                    
                    UIHelpers.verticalSpaceLarge,
                    
                    // Info de recordatorios
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.infoColor.withValues(alpha: 0.1),
                            AppTheme.infoColor.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.infoColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.infoColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.notifications_active_rounded,
                                  color: AppTheme.infoColor,
                                  size: 20,
                                ),
                              ),
                              UIHelpers.horizontalSpaceSmall,
                              const Text(
                                'Recordatorios Automáticos',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.infoColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          UIHelpers.verticalSpaceSmall,
                          const Text(
                            'Se programarán notificaciones:',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          UIHelpers.verticalSpaceSmall,
                          _buildReminderItem('6 horas antes'),
                          _buildReminderItem('3 horas antes'),
                          _buildReminderItem('1 hora antes'),
                          _buildReminderItem('15 minutos antes'),
                        ],
                      ),
                    ),
                    
                    UIHelpers.verticalSpaceExtraLarge,
                    
                    // Botón crear
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: isLoading ? null : AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isLoading
                            ? null
                            : [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                      ),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _createEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryColor,
                                  ),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded),
                                  SizedBox(width: 8),
                                  Text(
                                    'Crear Evento',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
      textCapitalization: TextCapitalization.sentences,
      maxLines: maxLines,
      enabled: enabled,
      validator: validator,
      style: const TextStyle(color: AppTheme.textPrimary),
    );
  }
  
  Widget _buildDateTimeTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            UIHelpers.horizontalSpaceMedium,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReminderItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.infoColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('es'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              surface: AppTheme.cardColor,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }
  
  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              surface: AppTheme.cardColor,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }
  
  void _createEvent() {
    if (!_formKey.currentState!.validate()) return;
    
    // Combinar fecha y hora en Lima timezone
    final limaDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    
    // Convertir a UTC para enviar al backend
    final utcDateTime = DateTimeUtils.limaToUtc(limaDateTime);
    
    final event = EventEntity(
      id: 0,
      userId: AppConstants.userId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      eventDate: utcDateTime,
      status: 'pending',
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
    
    context.read<EventBloc>().add(CreateEventRequested(event));
  }
}