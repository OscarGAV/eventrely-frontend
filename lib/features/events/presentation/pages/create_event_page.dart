import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_utils.dart';
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
      appBar: AppBar(
        title: const Text('Nuevo Evento'),
        centerTitle: true,
      ),
      body: BlocConsumer<EventBloc, EventState>(
        listener: (context, state) {
          if (state is EventOperationSuccess) {
            Navigator.pop(context, true);
          } else if (state is EventError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is EventLoading;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Título
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      hintText: 'Ej: Pagar alquiler',
                      prefixIcon: Icon(Icons.title),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El título es requerido';
                      }
                      return null;
                    },
                    enabled: !isLoading,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Descripción
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                      hintText: 'Detalles adicionales...',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    enabled: !isLoading,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Fecha
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Fecha'),
                      subtitle: Text(DateTimeUtils.formatShortDate(_selectedDate)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: isLoading ? null : _selectDate,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Hora
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Hora'),
                      subtitle: Text(_selectedTime.format(context)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: isLoading ? null : _selectTime,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Info de recordatorios
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.notifications_active, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Recordatorios',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('Se programarán notificaciones:'),
                          const SizedBox(height: 4),
                          const Text('• 6 horas antes'),
                          const Text('• 3 horas antes'),
                          const Text('• 1 hora antes'),
                          const Text('• 15 minutos antes'),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Botón crear
                  ElevatedButton(
                    onPressed: isLoading ? null : _createEvent,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Crear Evento',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
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
    );
    
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }
  
  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
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