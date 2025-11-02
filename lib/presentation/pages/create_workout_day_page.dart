import 'package:flutter/material.dart';
import '../../data/repositories/workout_day_repository.dart';
import '../../data/datasources/local_datasource.dart';
import '../../domain/entities/workout_day.dart';

class CreateWorkoutDayPage extends StatefulWidget {
  final int routineId;
  final String routineName;

  const CreateWorkoutDayPage({
    super.key,
    required this.routineId,
    required this.routineName,
  });

  @override
  State<CreateWorkoutDayPage> createState() => _CreateWorkoutDayPageState();
}

class _CreateWorkoutDayPageState extends State<CreateWorkoutDayPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late final WorkoutDayRepository _dayRepository;
  bool _isLoading = false;

  // Días de la semana predefinidos
  final List<String> _weekDays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  String _selectedDay = 'Lunes';

  @override
  void initState() {
    super.initState();
    _dayRepository = WorkoutDayRepository(LocalDataSource());
    _nameController.text = 'Lunes'; // Valor por defecto
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createDay() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Generar ID único más pequeño
      final now = DateTime.now();
      final dayId = now.microsecondsSinceEpoch % 1000000; // ID de 6 dígitos
      
      final day = WorkoutDay(
        id: dayId,
        routineId: widget.routineId,
        name: _nameController.text.trim(),
        order: _weekDays.indexOf(_selectedDay) + 1,
      );

      await _dayRepository.saveDay(day);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Día agregado exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear día: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Día'),
        backgroundColor: const Color(0xFF0080F5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0080F5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 48,
                      color: const Color(0xFF0080F5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Agregar Día de Entrenamiento',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rutina: ${widget.routineName}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Día de la semana
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Día de la Semana',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDay,
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedDay = newValue!;
                        _nameController.text = newValue;
                      });
                    },
                    items: _weekDays.map<DropdownMenuItem<String>>((String day) {
                      return DropdownMenuItem<String>(
                        value: day,
                        child: Text(day),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Nombre personalizado del día
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Día',
                  hintText: 'Ej: Día de Pecho',
                  prefixIcon: Icon(Icons.edit),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa el nombre del día';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Información sobre ejercicios
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Después de crear el día, podrás agregar ejercicios específicos con series, repeticiones y peso.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Botón de crear
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _createDay,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(_isLoading ? 'Creando...' : 'Agregar Día'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0080F5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}