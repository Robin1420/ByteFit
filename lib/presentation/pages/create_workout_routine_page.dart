import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/datasources/local_datasource.dart';
import '../../data/repositories/workout_day_repository.dart';
import '../../data/repositories/workout_exercise_repository.dart';
import '../../data/repositories/workout_routine_repository.dart';
import '../../domain/entities/exercise_db_entity.dart';
import '../../domain/entities/workout_day.dart';
import '../../domain/entities/workout_exercise.dart';
import '../../domain/entities/workout_routine.dart';
import '../../services/exercise_cache_service.dart';
import '../../services/offline_exercise_service.dart';

class CreateWorkoutRoutinePage extends StatefulWidget {
  const CreateWorkoutRoutinePage({super.key, this.routine});

  final WorkoutRoutine? routine;

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
  final ExerciseCacheService _cacheService = ExerciseCacheService();
  final OfflineExerciseService _offlineService = OfflineExerciseService();

  bool _isLoading = false;

  final Set<String> _selectedDays = {};
  final Map<String, List<Map<String, Object?>>> _dayExercises = {};
  String? _activeDay;
  List<String> _translatedExerciseNames = [];
  bool _loadingExercises = false;
  List<ExerciseDbEntity> _dbExercises = [];

  static const List<String> _daysOrder = [
    'Lunes',
    'Martes',
    'Miercoles',
    'Jueves',
    'Viernes',
    'Sabado',
    'Domingo',
  ];

  bool get _isEditing => widget.routine != null;

  @override
  void initState() {
    super.initState();
    _routineRepository = WorkoutRoutineRepository(LocalDataSource());
    _dayRepository = WorkoutDayRepository(LocalDataSource());
    _exerciseRepository = WorkoutExerciseRepository(LocalDataSource());
    _ensureCache();
    _loadTranslatedExercises();
    if (_isEditing) {
      _prefillExistingRoutine();
    }
  }

  void _openExerciseConfig(String name) {
    _exerciseNameController.text = name;
    _setsController.text = '3';
    _repsController.text = '8-12';
    _weightController.text = '0';
    _restTimeController.text = '60';

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
              Text(
                name,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _setsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Series'),
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
                      decoration: const InputDecoration(labelText: 'Peso (kg)'),
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
                        Navigator.pop(context);
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
    );
  }

  void _showExerciseInfo(String name) {
    ExerciseDbEntity? match;
    if (_dbExercises.isNotEmpty) {
      match = _dbExercises.firstWhere(
        (e) => e.name.toLowerCase() == name.toLowerCase(),
        orElse: () => _dbExercises.firstWhere(
          (e) => e.name.toLowerCase().contains(name.toLowerCase()),
          orElse: () => ExerciseDbEntity(
            exerciseId: '',
            name: name,
            gifUrl: '',
            targetMuscles: const [],
            bodyParts: const [],
            equipments: const [],
            secondaryMuscles: const [],
            instructions: const [],
          ),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final maxHeight = MediaQuery.of(context).size.height * 0.75;
        return SafeArea(
          child: SizedBox(
            height: maxHeight,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(match?.name ?? name,
                      style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 18)),
                  const SizedBox(height: 12),
                  if (match != null && match.gifUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: match.gifUrl.startsWith('assets/')
                            ? Image.asset(match.gifUrl, fit: BoxFit.cover)
                            : Image.network(match.gifUrl, fit: BoxFit.cover),
                      ),
                    ),
                  if (match != null && match.gifUrl.isNotEmpty)
                    const SizedBox(height: 14),
                  if (match != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _badge(
                            scheme,
                            Icons.bolt,
                            match.targetMuscles.isNotEmpty
                                ? match.targetMuscles.first
                                : 'Sin objetivo'),
                        const SizedBox(width: 8),
                        if (match.equipments.isNotEmpty)
                          _badge(scheme, Icons.build, match.equipments.first,
                              subtle: true),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceVariant.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Instrucciones',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 8),
                        if (match != null && match.instructions.isNotEmpty)
                          ...match.instructions.map((step) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  '- $step',
                                  style: TextStyle(
                                      color:
                                          scheme.onSurface.withOpacity(0.8)),
                                ),
                              ))
                        else
                          Text('No hay instrucciones disponibles.',
                              style: TextStyle(
                                  color: scheme.onSurface.withOpacity(0.6))),
                      ],
                    ),
                  ),
                  if (match != null) ...[
                    _chipsRow(scheme, 'Musculos objetivo', match.targetMuscles),
                    _chipsRow(
                        scheme, 'Musculos secundarios', match.secondaryMuscles),
                    _chipsRow(scheme, 'Grupo muscular', match.bodyParts),
                    _chipsRow(scheme, 'Equipo', match.equipments),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
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
      // silenciar fallo, seguimos con diÃ¡logo manual
    } finally {
      if (mounted) setState(() => _loadingExercises = false);
    }
  }

  Future<void> _prefillExistingRoutine() async {
    final routine = widget.routine;
    if (routine == null) return;
    setState(() => _isLoading = true);
    try {
      _nameController.text = routine.name;
      final days = await _dayRepository.getDaysByRoutineId(routine.id);
      final exercises = await _exerciseRepository.getExercises();

      _selectedDays
        ..clear()
        ..addAll(days.map((d) => d.name));
      for (final day in days) {
        final dayExercises = exercises
            .where((e) => e.dayId == day.id)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
        _dayExercises[day.name] = dayExercises
            .map<Map<String, Object?>>((e) => {
                  'name': e.name,
                  'sets': e.sets,
                  'reps': e.reps,
                  'weight': e.weight,
                  'restTime': e.restTimeSeconds,
                })
            .toList();
      }
      _activeDay = _selectedDays.isNotEmpty ? _selectedDays.first : null;
    } catch (_) {
      // ignore load failure
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _ensureCache() async {
    await _cacheService.init();
    if (await _cacheService.hasExercises()) {
      _dbExercises = _cacheService.getAllExercisesSync();
      return;
    }
    try {
      await _offlineService.initializeFromAssets();
      await _cacheService.init();
      _dbExercises = _cacheService.getAllExercisesSync();
    } catch (_) {
      _dbExercises = [];
    }
  }

  Future<void> _saveRoutine() async {
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
      if (_isEditing) {
        await _updateRoutine();
      } else {
        await _createRoutine();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEditing ? 'Error al actualizar rutina: $e' : 'Error al crear rutina: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createRoutine() async {
    final now = DateTime.now();
    final routineId = now.microsecondsSinceEpoch % 1000000; // 6 dÃ­gitos

    final routine = WorkoutRoutine(
      id: routineId,
      name: _nameController.text.trim(),
      description: '',
      isActive: true,
    );
    await _routineRepository.saveRoutine(routine);
    await _persistDaysAndExercises(routineId);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _updateRoutine() async {
    final routine = widget.routine;
    if (routine == null) return;
    final updated = routine.copyWith(name: _nameController.text.trim());
    await _routineRepository.updateRoutine(routine.id, updated);
    // limpiar dÃ­as y ejercicios previos
    final days = await _dayRepository.getDaysByRoutineId(routine.id);
    for (final day in days) {
      await _exerciseRepository.deleteExercisesByDay(day.id);
    }
    await _dayRepository.deleteDaysByRoutine(routine.id);
    await _persistDaysAndExercises(routine.id);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _persistDaysAndExercises(int routineId) async {
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
          name: (exerciseData['name'] as String?) ?? '',
          sets: (exerciseData['sets'] as int?) ?? 0,
          reps: (exerciseData['reps'] as String?) ?? '',
          weight: ((exerciseData['weight'] ?? 0) as num).toDouble(),
          restTimeSeconds: (exerciseData['restTime'] as int?) ?? 0,
          order: exerciseOrder,
        );
        await _exerciseRepository.saveExercise(exercise);
        exerciseOrder++;
      }
      dayOrder++;
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
                        labelText: 'Buscar ejercicio (espaÃ±ol)',
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
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.help_outline),
                                    onPressed: () => _showExerciseInfo(name),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () {
                                      _exerciseNameController.text = name;
                                      Navigator.pop(context);
                                      _openExerciseConfig(name);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Rutina' : 'Crear Rutina'),
        backgroundColor: const Color(0xFF0080F5),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
        SizedBox(
          height: 90,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _daysOrder.map((day) {
                final isSelected = _selectedDays.contains(day);
                final count = (_dayExercises[day]?.length ?? 0);
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (!isSelected) {
                          _selectedDays.add(day);
                          _dayExercises.putIfAbsent(
                              day, () => <Map<String, Object?>>[]);
                        }
                        _activeDay = day;
                      });
                      _showAddExerciseDialog();
                    },
                    child: Container(
                      width: 60,
                      height: 82,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? scheme.primary.withOpacity(0.16)
                            : scheme.surfaceVariant.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isSelected
                                ? scheme.primary
                                : scheme.outlineVariant,
                            width: 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: isSelected
                                ? scheme.primary
                                : scheme.surface.withOpacity(0.6),
                            foregroundColor:
                                isSelected ? Colors.white : scheme.onSurface,
                            child: Text(
                              day.characters.first.toUpperCase(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (count > 0)
                            Text(
                              '$count',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? scheme.primary
                                      : scheme.onSurface),
                            ),
                          if (isSelected) ...[
                            const SizedBox(height: 4),
                            InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                setState(() {
                                  _selectedDays.remove(day);
                                  _dayExercises.remove(day);
                                  if (_activeDay == day) {
                                    _activeDay = _selectedDays.isEmpty
                                        ? null
                                        : _daysOrder.firstWhere(
                                            (d) => _selectedDays.contains(d));
                                  }
                                });
                              },
                              child: const Icon(Icons.remove_circle_outline,
                                  size: 18, color: Colors.redAccent),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
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
    final activeDayExercises =
        _activeDay != null ? _dayExercises[_activeDay] ?? [] : <Map<String, Object?>>[];

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
        const SizedBox(height: 16),
        if (activeDayExercises.isEmpty)
          const _EmptyHint(
            message: 'Aun no hay ejercicios para este dia.',
          )
        else
                    ...activeDayExercises.asMap().entries.map((entry) {
            final index = entry.key;
            final exercise = entry.value as Map<String, Object?>;
            final name = exercise['name'] as String? ?? '';
            final sets = exercise['sets'] as int? ?? 0;
            final reps = exercise['reps'] as String? ?? '';
            final weight = exercise['weight'];
            final rest = exercise['restTime'] as int? ?? 0;
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
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '$sets series · $reps reps · $weight kg · ${rest}s descanso',
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
      onPressed: _isLoading ? null : _saveRoutine,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Icon(_isEditing ? Icons.save : Icons.add),
      label: Text(_isLoading
          ? (_isEditing ? 'Guardando...' : 'Creando...')
          : (_isEditing ? 'Guardar cambios' : 'Crear Rutina')),
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

  Widget _badge(ColorScheme scheme, IconData icon, String text,
      {bool subtle = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: subtle
            ? scheme.surfaceVariant.withOpacity(0.4)
            : scheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
                color: scheme.onSurface.withOpacity(0.85),
                fontWeight: subtle ? FontWeight.w500 : FontWeight.w700,
                fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _chipsRow(ColorScheme scheme, String title, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: items
                .map((e) => Chip(
                      label: Text(e),
                      backgroundColor: scheme.primary.withOpacity(0.12),
                      labelStyle: TextStyle(color: scheme.onSurface),
                    ))
                .toList(),
          ),
        ],
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

