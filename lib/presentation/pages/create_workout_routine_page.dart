import 'package:flutter/material.dart';
import '../../data/repositories/workout_routine_repository.dart';
import '../../data/repositories/workout_day_repository.dart';
import '../../data/repositories/workout_exercise_repository.dart';
import '../../data/datasources/local_datasource.dart';
import '../../domain/entities/workout_routine.dart';
import '../../domain/entities/workout_day.dart';
import '../../domain/entities/workout_exercise.dart';

class CreateWorkoutRoutinePage extends StatefulWidget {
  const CreateWorkoutRoutinePage({super.key});

  @override
  State<CreateWorkoutRoutinePage> createState() => _CreateWorkoutRoutinePageState();
}

class _CreateWorkoutRoutinePageState extends State<CreateWorkoutRoutinePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late final WorkoutRoutineRepository _routineRepository;
  late final WorkoutDayRepository _dayRepository;
  late final WorkoutExerciseRepository _exerciseRepository;
  bool _isLoading = false;
  
  // Días de la semana seleccionados
  final Set<String> _selectedDays = {};
  
  // Lista de ejercicios para agregar
  final List<Map<String, dynamic>> _exercises = [];
  
  // Controladores para agregar ejercicios
  final _exerciseNameController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '8-12');
  final _weightController = TextEditingController(text: '0');
  final _restTimeController = TextEditingController(text: '60');

  @override
  void initState() {
    super.initState();
    _routineRepository = WorkoutRoutineRepository(LocalDataSource());
    _dayRepository = WorkoutDayRepository(LocalDataSource());
    _exerciseRepository = WorkoutExerciseRepository(LocalDataSource());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _exerciseNameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _restTimeController.dispose();
    super.dispose();
  }

  Future<void> _createRoutine() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona al menos un día de la semana'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Generar IDs únicos más pequeños
      final now = DateTime.now();
      final routineId = now.microsecondsSinceEpoch % 1000000; // ID de 6 dígitos
      
      // Crear la rutina
      final routine = WorkoutRoutine(
        id: routineId,
        name: _nameController.text.trim(),
        description: '', // Sin descripción
        isActive: true,
      );

      await _routineRepository.saveRoutine(routine);

      // Crear los días de la semana seleccionados
      int dayOrder = 1;
      final List<int> createdDayIds = [];
      
      for (final dayName in _selectedDays) {
        final dayId = (routineId * 100) + dayOrder; // ID único basado en routineId
        final day = WorkoutDay(
          id: dayId,
          routineId: routineId,
          name: dayName,
          order: dayOrder,
        );
        await _dayRepository.saveDay(day);
        createdDayIds.add(dayId);
        dayOrder++;
      }

      // Agregar ejercicios si hay alguno
      if (_exercises.isNotEmpty && createdDayIds.isNotEmpty) {
        int exerciseOrder = 1;
        final firstDayId = createdDayIds.first; // Usar el primer día creado
        
        for (final exerciseData in _exercises) {
          final exerciseId = (firstDayId * 100) + exerciseOrder; // ID único basado en dayId
          final exercise = WorkoutExercise(
            id: exerciseId,
            dayId: firstDayId,
            name: exerciseData['name'],
            sets: exerciseData['sets'],
            reps: exerciseData['reps'],
            weight: exerciseData['weight'],
            restTimeSeconds: exerciseData['restTime'],
            order: exerciseOrder,
          );
          await _exerciseRepository.saveExercise(exercise);
          exerciseOrder++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Rutina creada exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear rutina: $e'),
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

  void _addExercise() {
    if (_exerciseNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el nombre del ejercicio'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _exercises.add({
        'name': _exerciseNameController.text.trim(),
        'sets': int.tryParse(_setsController.text) ?? 3,
        'reps': _repsController.text.trim(),
        'weight': double.tryParse(_weightController.text) ?? 0.0,
        'restTime': int.tryParse(_restTimeController.text) ?? 60,
      });
      
      // Limpiar campos
      _exerciseNameController.clear();
      _setsController.text = '3';
      _repsController.text = '8-12';
      _weightController.text = '0';
      _restTimeController.text = '60';
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  void _showAddExerciseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Ejercicio'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _exerciseNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Ejercicio',
                  hintText: 'Ej: Press de banca',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _setsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Series',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _repsController,
                      decoration: const InputDecoration(
                        labelText: 'Repeticiones',
                        hintText: '8-12',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Peso (kg)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _restTimeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Descanso (seg)',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addExercise();
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Rutina'),
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
                      Icons.fitness_center,
                      size: 48,
                      color: const Color(0xFF0080F5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Crear Nueva Rutina',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Selecciona los días de entrenamiento y agrega ejercicios',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Nombre de la rutina
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Rutina',
                  hintText: 'Ej: Rutina de Fuerza',
                  prefixIcon: Icon(Icons.fitness_center),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa el nombre de la rutina';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Selección de días de la semana
              const Text(
                'Días de Entrenamiento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildDaysSelector(),
              const SizedBox(height: 24),

              // Sección de ejercicios
              const Text(
                'Ejercicios',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildExercisesSection(),
              const SizedBox(height: 30),

              // Botón de crear
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _createRoutine,
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
                label: Text(_isLoading ? 'Creando...' : 'Crear Rutina'),
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

  Widget _buildDaysSelector() {
    final daysOfWeek = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: daysOfWeek.map((day) {
        final isSelected = _selectedDays.contains(day);
        return FilterChip(
          label: Text(day),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(day);
              } else {
                _selectedDays.remove(day);
              }
            });
          },
          selectedColor: const Color(0xFF0080F5).withOpacity(0.2),
          checkmarkColor: const Color(0xFF0080F5),
          side: BorderSide(
            color: isSelected ? const Color(0xFF0080F5) : Colors.grey,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExercisesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botón para agregar ejercicio
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showAddExerciseDialog,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Ejercicio'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0080F5),
              side: const BorderSide(color: Color(0xFF0080F5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Lista de ejercicios
        if (_exercises.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: const Center(
              child: Text(
                'No hay ejercicios agregados.\nToca "Agregar Ejercicio" para comenzar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ..._exercises.asMap().entries.map((entry) {
            final index = entry.key;
            final exercise = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF0080F5).withOpacity(0.1),
                  child: const Icon(
                    Icons.fitness_center,
                    color: Color(0xFF0080F5),
                    size: 20,
                  ),
                ),
                title: Text(
                  exercise['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${exercise['sets']} series × ${exercise['reps']} reps • ${exercise['weight']} kg • ${exercise['restTime']}s descanso',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeExercise(index),
                ),
              ),
            );
          }).toList(),
      ],
    );
  }
}
