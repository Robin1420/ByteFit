import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../../data/datasources/local_datasource.dart';
import '../../data/repositories/workout_day_repository.dart';
import '../../data/repositories/workout_exercise_repository.dart';
import '../../data/repositories/workout_routine_repository.dart';
import '../../domain/entities/workout_day.dart';
import '../../domain/entities/workout_exercise.dart';
import '../../domain/entities/workout_routine.dart';

class CreateWorkoutRoutinePage extends StatefulWidget {
  const CreateWorkoutRoutinePage({super.key});

  @override
  State<CreateWorkoutRoutinePage> createState() =>
      _CreateWorkoutRoutinePageState();
}

class _CreateWorkoutRoutinePageState extends State<CreateWorkoutRoutinePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  final _exerciseNameController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '8-12');
  final _weightController = TextEditingController(text: '0');
  final _restTimeController = TextEditingController(text: '60');

  late final WorkoutRoutineRepository _routineRepository;
  late final WorkoutDayRepository _dayRepository;
  late final WorkoutExerciseRepository _exerciseRepository;

  bool _isLoading = false;

  final Set<String> _selectedDays = {};
  final Map<String, List<Map<String, dynamic>>> _dayExercises = {};
  String? _activeDay;
  List<String> _translatedExerciseNames = [];
  bool _loadingExercises = false;

  static const List<String> _daysOrder = [
    'Lunes',
    'Martes',
    'Miercoles',
    'Jueves',
    'Viernes',
    'Sabado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _routineRepository = WorkoutRoutineRepository(LocalDataSource());
    _dayRepository = WorkoutDayRepository(LocalDataSource());
    _exerciseRepository = WorkoutExerciseRepository(LocalDataSource());
    _loadTranslatedExercises();
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

  Future<void> _loadTranslatedExercises() async {
    if (_loadingExercises || _translatedExerciseNames.isNotEmpty) return;
    setState(() => _loadingExercises = true);
    try {
      final raw =
          await rootBundle.loadString('assets/data/exercises_es_traducido.json');
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final list = (decoded['exercises'] as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>)['name']?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
      setState(() => _translatedExerciseNames = list);
    } catch (_) {
      // silenciar fallo, seguimos con diálogo manual
    } finally {
      if (mounted) setState(() => _loadingExercises = false);
    }
  }

  Future<void> _createRoutine() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona al menos un dia de la semana'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final routineId = now.microsecondsSinceEpoch % 1000000; // 6 digitos

      final routine = WorkoutRoutine(
        id: routineId,
        name: _nameController.text.trim(),
        description: '',
        isActive: true,
      );
      await _routineRepository.saveRoutine(routine);

      int dayOrder = 1;
      for (final dayName in _daysOrder.where((d) => _selectedDays.contains(d))) {
        final dayId = (routineId * 100) + dayOrder;
        final day = WorkoutDay(
          id: dayId,
          routineId: routineId,
          name: dayName,
          order: dayOrder,
        );
        await _dayRepository.saveDay(day);

        final exercisesForDay = _dayExercises[dayName] ?? [];
        int exerciseOrder = 1;
        for (final exerciseData in exercisesForDay) {
          final exerciseId = (dayId * 100) + exerciseOrder;
          final exercise = WorkoutExercise(
            id: exerciseId,
            dayId: dayId,
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
        dayOrder++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rutina creada exitosamente!'),
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
        setState(() => _isLoading = false);
      }
    }
  }

  void _addExercise() {
    if (_activeDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un dia activo para agregar ejercicios'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
      final exercises = _dayExercises[_activeDay!] ?? [];
      exercises.add({
        'name': _exerciseNameController.text.trim(),
        'sets': int.tryParse(_setsController.text) ?? 3,
        'reps': _repsController.text.trim(),
        'weight': double.tryParse(_weightController.text) ?? 0.0,
        'restTime': int.tryParse(_restTimeController.text) ?? 60,
      });
      _dayExercises[_activeDay!] = exercises;

      _exerciseNameController.clear();
      _setsController.text = '3';
      _repsController.text = '8-12';
      _weightController.text = '0';
      _restTimeController.text = '60';
    });
  }

  void _removeExercise(int index) {
    if (_activeDay == null) return;
    setState(() {
      final exercises = _dayExercises[_activeDay!] ?? [];
      if (index >= 0 && index < exercises.length) {
        exercises.removeAt(index);
        _dayExercises[_activeDay!] = exercises;
      }
    });
  }

  void _showAddExerciseDialog() {
    if (_activeDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero selecciona un dia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setStateDialog) {
              final query = _exerciseNameController.text.toLowerCase();
              final suggestions = _translatedExerciseNames
                  .where((e) => e.toLowerCase().contains(query))
                  .take(12)
                  .toList();

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Text(
                      'Agregar Ejercicio',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _exerciseNameController,
                      decoration: const InputDecoration(
                        labelText: 'Buscar ejercicio (español)',
                        hintText: 'Ej: Press de banca',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => setStateDialog(() {}),
                    ),
                    if (suggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: suggestions.length,
                          itemBuilder: (_, i) {
                            final name = suggestions[i];
                            return ListTile(
                              dense: true,
                              title: Text(name),
                              trailing: const Icon(Icons.add_circle_outline),
                              onTap: () {
                                _exerciseNameController.text = name;
                                setStateDialog(() {});
                              },
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _setsController,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Series'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _repsController,
                            decoration: const InputDecoration(
                              labelText: 'Repeticiones',
                              hintText: '8-12',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Peso (kg)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _restTimeController,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Descanso (s)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _addExercise();
                              setStateDialog(() {
                                _exerciseNameController.clear();
                                _setsController.text = '3';
                                _repsController.text = '8-12';
                                _weightController.text = '0';
                                _restTimeController.text = '60';
                              });
                            },
                            child: const Text('Agregar'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
  void _openTranslatedPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      isScrollControlled: true,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          builder: (_, controller) {
            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ejercicios traducidos',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: _translatedExerciseNames.length,
                    itemBuilder: (_, i) {
                      final name = _translatedExerciseNames[i];
                      return ListTile(
                        title: Text(name),
                        trailing: Icon(Icons.add_circle, color: scheme.primary),
                        onTap: () {
                          _exerciseNameController.text = name;
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
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
              _buildNameField(),
              const SizedBox(height: 24),
              _buildDaysSelector(),
              const SizedBox(height: 24),
              _buildExercisesSection(),
              const SizedBox(height: 30),
              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
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
    );
  }

  Widget _buildDaysSelector() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dias de entrenamiento',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: _daysOrder.map((day) {
            final isSelected = _selectedDays.contains(day);
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? scheme.primary.withOpacity(0.12)
                    : scheme.surfaceVariant.withOpacity(0.22),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? scheme.primary : scheme.outlineVariant,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: isSelected
                      ? scheme.primary
                      : scheme.surface.withOpacity(0.6),
                  foregroundColor: isSelected ? Colors.white : scheme.onSurface,
                  child: const Icon(Icons.event_available, size: 18),
                ),
                title: Text(
                  day,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? scheme.primary : scheme.onSurface,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: scheme.primary)
                    : Icon(Icons.chevron_right,
                        color: scheme.onSurface.withOpacity(0.5)),
                onTap: () {
                  final wasSelected = isSelected;
                  setState(() {
                    if (wasSelected) {
                      _selectedDays.remove(day);
                      _dayExercises.remove(day);
                      if (_activeDay == day) {
                        _activeDay = _selectedDays.isEmpty
                            ? null
                            : _daysOrder
                                .firstWhere((d) => _selectedDays.contains(d));
                      }
                    } else {
                      _selectedDays.add(day);
                      _dayExercises.putIfAbsent(day, () => []);
                      _activeDay = day;
                    }
                  });
                  if (!wasSelected) {
                    _showAddExerciseDialog();
                  }
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExercisesSection() {
    final selectedOrdered =
        _daysOrder.where((d) => _selectedDays.contains(d)).toList();

    if (selectedOrdered.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Ejercicios',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          _EmptyHint(message: 'Selecciona dias para asignar ejercicios.'),
        ],
      );
    }

    _activeDay ??= selectedOrdered.first;
    final activeDayExercises = _dayExercises[_activeDay] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ejercicios',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: selectedOrdered.map((day) {
            final isActive = _activeDay == day;
            return ChoiceChip(
              label: Text(day),
              selected: isActive,
              onSelected: (_) {
                setState(() {
                  _activeDay = day;
                });
              },
              selectedColor: const Color(0xFF0080F5).withOpacity(0.2),
              labelStyle: TextStyle(
                color: isActive ? const Color(0xFF0080F5) : Colors.black,
              ),
              side: BorderSide(
                color: isActive ? const Color(0xFF0080F5) : Colors.grey,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Text(
          'Ejercicios para $_activeDay',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showAddExerciseDialog,
            icon: const Icon(Icons.add),
            label: const Text('Agregar ejercicio'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0080F5),
              side: const BorderSide(color: Color(0xFF0080F5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (activeDayExercises.isEmpty)
          const _EmptyHint(
            message: 'Aun no hay ejercicios para este dia.',
          )
        else
          ...activeDayExercises.asMap().entries.map((entry) {
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
                  '${exercise['sets']} series · ${exercise['reps']} reps · ${exercise['weight']} kg · ${exercise['restTime']}s descanso',
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

  Widget _buildCreateButton() {
    return ElevatedButton.icon(
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
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
      ),
    );
  }
}





