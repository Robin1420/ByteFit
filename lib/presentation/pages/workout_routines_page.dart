import 'dart:convert';
import 'package:flutter/material.dart';

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
import 'add_exercise_page.dart';
import 'create_workout_routine_page.dart';

class WorkoutRoutinesPage extends StatefulWidget {
  const WorkoutRoutinesPage({super.key});

  @override
  State<WorkoutRoutinesPage> createState() => _WorkoutRoutinesPageState();
}

class _WorkoutRoutinesPageState extends State<WorkoutRoutinesPage> {
  late final WorkoutRoutineRepository _routineRepository;
  late final WorkoutDayRepository _dayRepository;
  late final WorkoutExerciseRepository _exerciseRepository;
  final ExerciseCacheService _cacheService = ExerciseCacheService();
  final OfflineExerciseService _offlineService = OfflineExerciseService();

  bool _isLoading = true;
  List<WorkoutRoutine> _routines = [];
  List<WorkoutDay> _allDays = [];
  List<WorkoutExercise> _allExercises = [];
  List<WorkoutExercise> _todayExercises = [];
  List<ExerciseDbEntity> _dbExercises = [];

  @override
  void initState() {
    super.initState();
    _routineRepository = WorkoutRoutineRepository(LocalDataSource());
    _dayRepository = WorkoutDayRepository(LocalDataSource());
    _exerciseRepository = WorkoutExerciseRepository(LocalDataSource());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final routines = await _routineRepository.getRoutines();
      final days = await _dayRepository.getDays();
      final exercises = await _exerciseRepository.getExercises();
      await _ensureCache();
      final dbExercises = _cacheService.getAllExercisesSync();

      final activeRoutineIds =
          routines.where((r) => r.isActive).map((r) => r.id).toSet();
      final daysInUse = activeRoutineIds.isNotEmpty
          ? days.where((d) => activeRoutineIds.contains(d.routineId)).toList()
          : days;

      final todayName = _getDayName(DateTime.now().weekday);
      final todayDays = daysInUse.where((d) => d.name == todayName).toList();
      final List<WorkoutExercise> todayExercises = [];
      for (final day in todayDays) {
        final ex = await _exerciseRepository.getExercisesByDayId(day.id);
        todayExercises.addAll(ex);
      }

      if (!mounted) return;
      setState(() {
        _routines = routines;
        _allDays = days; // mantener todos los días para ver ejercicios aunque la rutina no esté activa
        _allExercises = exercises; // todos los ejercicios guardados
        _todayExercises = todayExercises;
        _dbExercises = dbExercises;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al cargar rutinas: $e')));
    }
  }

  Future<void> _ensureCache() async {
    await _cacheService.init();
    if (await _cacheService.hasExercises()) return;
    try {
      await _offlineService.initializeFromAssets();
    } catch (_) {}
    await _cacheService.init();
  }

  String _getDayName(int weekday) {
    const days = [
      'Lunes',
      'Martes',
      'Miercoles',
      'Jueves',
      'Viernes',
      'Sabado',
      'Domingo'
    ];
    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        top: true,
        bottom: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: scheme.primary,
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    Text('Entrenamiento',
                        style: TextStyle(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    const SizedBox(height: 8),
                    _headerCard(scheme),
                    const SizedBox(height: 12),
                    Text('Resumen de ejercicios',
                        style: TextStyle(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    const SizedBox(height: 8),
                    _exerciseSummaryCard(scheme),
                    const SizedBox(height: 16),
                    _todayCard(scheme),
                    const SizedBox(height: 16),
                    // Lista de rutinas se abre desde el chip de resumen "Rutinas"
                  ],
                ),
              ),
      ),
    );
  }

  Widget _headerCard(ColorScheme scheme) {
    final todayName = _getDayName(DateTime.now().weekday);
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/Imagenes/card_ejercicios.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const [0.0, 0.45, 0.8, 1],
                    colors: [
                      scheme.primary.withOpacity(0.92),
                      scheme.primary.withOpacity(0.7),
                      scheme.primary.withOpacity(0.32),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Tu entrenamiento',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Hoy es $todayName',
                      style: TextStyle(color: Colors.white.withOpacity(0.9))),
                  const SizedBox(height: 6),
                  Text(
                    _todayExercises.isEmpty
                        ? 'No tienes ejercicios programados'
                        : '${_todayExercises.length} ejercicios hoy',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exerciseSummaryCard(ColorScheme scheme) {
    final activeRoutine = _routines.firstWhere(
      (r) => r.isActive,
      orElse: () => _routines.isNotEmpty
          ? _routines.first
          : WorkoutRoutine(id: -1, name: '', description: '', isActive: false),
    );
    final bool hasActive = _routines.any((r) => r.isActive);
    final exercisesCount = hasActive && activeRoutine.id != -1
        ? _countExercisesForRoutine(activeRoutine.id)
        : _allExercises.length;
    final todayCount = _todayExercises.length;

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _summaryChip(
            scheme,
            icon: Icons.playlist_add_check,
            label: 'Rutinas',
            value: '${_routines.length}',
            onTap: _openRoutinesSheet,
            iconColor: const Color(0xFF1C9AF5),
            bgColor: const Color(0xFFE5F4FF),
          ),
          const SizedBox(width: 8),
          _summaryChip(
            scheme,
            icon: Icons.fitness_center,
            label: 'Ejercicios',
            value: '$exercisesCount',
            onTap: null,
            iconColor: const Color(0xFF2DBE6B),
            bgColor: const Color(0xFFE8F8EF),
          ),
          const SizedBox(width: 8),
          _summaryChip(
            scheme,
            icon: Icons.today,
            label: 'Hoy',
            value: '$todayCount',
            onTap: null,
            iconColor: const Color(0xFFF7941E),
            bgColor: const Color(0xFFFFF2E4),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(
    ColorScheme scheme, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback? onTap,
    required Color iconColor,
    required Color bgColor,
  }) {
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: iconColor.withOpacity(0.2),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: scheme.onSurface.withOpacity(0.7),
                        fontSize: 11)),
                Text(value,
                    style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );

    return Expanded(
      child: onTap != null
          ? InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: card,
            )
          : card,
    );
  }

  Widget _todayCard(ColorScheme scheme) {
    if (_todayExercises.isEmpty) {
      final todayName = _getDayName(DateTime.now().weekday);
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outline.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy, color: scheme.onSurface.withOpacity(0.6)),
            const SizedBox(height: 8),
            Text('No hay ejercicios para $todayName',
                style: TextStyle(color: scheme.onSurface)),
            Text('Crea una rutina o asigna ejercicios a este dia.',
                style: TextStyle(
                    color: scheme.onSurface.withOpacity(0.6), fontSize: 12)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Entrenamiento de hoy',
                  style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              const Spacer(),
              Icon(Icons.playlist_add_check, color: scheme.primary),
            ],
          ),
          const SizedBox(height: 12),
          ..._todayExercises.map((e) => _exerciseTile(e, scheme)),
        ],
      ),
    );
  }

  void _openRoutinesSheet() {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            builder: (context, controller) {
              if (_routines.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.list_alt,
                          color: scheme.onSurface.withOpacity(0.6)),
                      const SizedBox(height: 8),
                      Text('Sin rutinas creadas',
                          style: TextStyle(color: scheme.onSurface)),
                      Text('Crea una rutina para empezar.',
                          style: TextStyle(
                              color: scheme.onSurface.withOpacity(0.6),
                              fontSize: 12)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            final res = await Navigator.push(
                              this.context,
                              MaterialPageRoute(
                                  builder: (_) => const CreateWorkoutRoutinePage()),
                            );
                            if (res == true) _loadData();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Nueva rutina'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: scheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: ListView(
                  controller: controller,
                  children: [
                    ..._routines.map((r) => _routineCard(r, scheme)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          final res = await Navigator.push(
                            this.context,
                            MaterialPageRoute(
                                builder: (_) => const CreateWorkoutRoutinePage()),
                          );
                          if (res == true) _loadData();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Nueva rutina'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _routineCard(WorkoutRoutine routine, ColorScheme scheme) {
    final count = _countExercisesForRoutine(routine.id);
    final days = _allDays
        .where((d) => d.routineId == routine.id)
        .map((d) => d.name)
        .join(', ');
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showRoutineActions(routine),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outline.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: scheme.primary.withOpacity(0.12),
              child: Icon(Icons.timeline, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(routine.name,
                      style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  if (routine.isActive) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: scheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.radio_button_checked,
                              size: 14, color: scheme.primary),
                          const SizedBox(width: 6),
                          Text('En uso',
                              style: TextStyle(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    days.isEmpty ? 'Sin dias asignados' : days,
                    style: TextStyle(
                        color: scheme.onSurface.withOpacity(0.6),
                        fontSize: 12),
                  ),
                  Text(
                    '${_countExercisesForRoutine(routine.id)} ejercicios',
                    style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showRoutineActions(routine),
              icon: Icon(Icons.more_vert,
                  color: routine.isActive ? scheme.primary : scheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoutineActions(WorkoutRoutine routine) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scheme.outline.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: scheme.primary.withOpacity(0.12),
                        child: Icon(Icons.show_chart, color: scheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(routine.name,
                                style: TextStyle(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(
                              _allDays
                                      .where((d) => d.routineId == routine.id)
                                      .map((d) => d.name)
                                      .join(', ')
                                      .isEmpty
                                  ? 'Sin dias asignados'
                                  : _allDays
                                      .where((d) => d.routineId == routine.id)
                                      .map((d) => d.name)
                                      .join(', '),
                              style: TextStyle(
                                  color: scheme.onSurface.withOpacity(0.6),
                                  fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_countExercisesForRoutine(routine.id)} ejercicios',
                              style: TextStyle(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (routine.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.radio_button_checked,
                                  size: 14, color: scheme.primary),
                              const SizedBox(width: 6),
                              Text('En uso',
                                  style: TextStyle(
                                      color: scheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: Icon(Icons.playlist_add_check, color: scheme.primary),
                  title: const Text('Usar esta rutina'),
                  onTap: () {
                    Navigator.pop(context);
                    _selectRoutine(routine);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.visibility, color: scheme.primary),
                  title: const Text('Ver detalles'),
                  onTap: () {
                    Navigator.pop(context);
                    _showRoutineDetails(routine);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.edit, color: scheme.primary),
                  title: const Text('Editar rutina'),
                  onTap: () async {
                    Navigator.pop(context);
                    final res = await Navigator.push(
                      this.context,
                      MaterialPageRoute(
                          builder: (_) =>
                              CreateWorkoutRoutinePage(routine: routine)),
                    );
                    if (res == true) _loadData();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Eliminar'),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteRoutine(routine);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _renameRoutine(WorkoutRoutine routine) async {
    final controller = TextEditingController(text: routine.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Renombrar rutina'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nuevo nombre',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
    if (newName != null && newName.isNotEmpty) {
      final updated = WorkoutRoutine(
        id: routine.id,
        name: newName,
        description: routine.description,
        isActive: routine.isActive,
      );
      await _routineRepository.saveRoutine(updated);
    }
  }

  Future<void> _selectRoutine(WorkoutRoutine routine) async {
    await _routineRepository.setActiveRoutine(routine.id);
    await _loadData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rutina "${routine.name}" activada')),
    );
  }

  Future<void> _deleteRoutine(WorkoutRoutine routine) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar rutina'),
          content: Text(
              'Se eliminarán los días y ejercicios asociados. ¿Continuar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final days = await _dayRepository.getDaysByRoutineId(routine.id);
    for (final day in days) {
      await _exerciseRepository.deleteExercisesByDay(day.id);
      await _dayRepository.deleteDay(day.id);
    }
    await _routineRepository.deleteRoutine(routine.id);
    await _loadData();
  }

  int _countExercisesForRoutine(int routineId) {
    final dayIds = _allDays
        .where((d) => d.routineId == routineId)
        .map((d) => d.id)
        .toSet();
    return _allExercises.where((e) => dayIds.contains(e.dayId)).length;
  }

  Widget _exerciseTile(WorkoutExercise exercise, ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: scheme.primary.withOpacity(0.15),
            child: Icon(Icons.fitness_center, color: scheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name,
                    style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                Text(
                  '${exercise.sets} series x ${exercise.reps} reps${exercise.weight > 0 ? ' x ${exercise.weight} kg' : ''}',
                  style: TextStyle(
                      color: scheme.onSurface.withOpacity(0.65), fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Detalles del ejercicio',
            onPressed: () => _showExerciseInfo(exercise),
            icon: Icon(Icons.help_outline, color: scheme.primary),
          ),
        ],
      ),
    );
  }

  void _showExerciseInfo(WorkoutExercise exercise) {
    ExerciseDbEntity? match;
    if (_dbExercises.isNotEmpty) {
      match = _dbExercises.firstWhere(
        (e) => e.name.toLowerCase() == exercise.name.toLowerCase(),
        orElse: () => _dbExercises.firstWhere(
          (e) => e.name.toLowerCase().contains(exercise.name.toLowerCase()),
          orElse: () => ExerciseDbEntity(
            exerciseId: '',
            name: exercise.name,
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
    final safeName = _fixEncoding(match?.name ?? exercise.name);
    final safeInstructions = match?.instructions
            .map((s) => _fixEncoding(s))
            .toList(growable: false) ??
        const <String>[];

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
                  Text(safeName,
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double itemWidth =
                            (constraints.maxWidth - 12) / 2; // 2 cols + gap
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: itemWidth,
                              child: _infoStat(scheme, Icons.repeat, 'Series',
                                  '${exercise.sets}'),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _infoStat(
                                  scheme,
                                  Icons.fiber_manual_record,
                                  'Repeticiones',
                                  exercise.reps),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _infoStat(
                                  scheme,
                                  Icons.fitness_center,
                                  'Peso',
                                  exercise.weight > 0
                                      ? '${exercise.weight} kg'
                                      : 'Sin peso'),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _infoStat(scheme, Icons.timer, 'Descanso',
                                  '${exercise.restTimeSeconds} seg'),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  if (match != null) ...[
                    _chipsRow(scheme, 'Musculos objetivo', match.targetMuscles),
                    _chipsRow(
                        scheme, 'Musculos secundarios', match.secondaryMuscles),
                    _chipsRow(scheme, 'Grupo muscular', match.bodyParts),
                    _chipsRow(scheme, 'Equipo', match.equipments),
                  ],
                  if (safeInstructions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.surfaceVariant.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Instrucciones',
                              style: TextStyle(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          const SizedBox(height: 8),
                          ...safeInstructions.map((step) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  '- $step',
                                  style: TextStyle(
                                      color: scheme.onSurface.withOpacity(0.8),
                                      fontSize: 12),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _fixEncoding(String value) {
    if (value.contains('Ã') || value.contains('Â')) {
      try {
        return utf8.decode(latin1.encode(value));
      } catch (_) {
        return value;
      }
    }
    return value;
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
                      label: Text(e,
                          style:
                              TextStyle(color: scheme.onSurface, fontSize: 12)),
                      backgroundColor: scheme.surfaceVariant.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(ColorScheme scheme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(color: scheme.onSurface.withOpacity(0.7))),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  color: scheme.onSurface, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _showRoutineDetails(WorkoutRoutine routine) {
    final routineDays =
        _allDays.where((d) => d.routineId == routine.id).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, controller) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ListView(
                controller: controller,
                children: [
                  Row(
                    children: [
                      Text(routine.name,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          )),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              this.context,
                              MaterialPageRoute(
                                  builder: (_) => const AddExercisePage()),
                            ).then((_) => _loadData());
                          },
                          icon: const Icon(Icons.playlist_add),
                          label: const Text('Agregar ejercicios'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              this.context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      CreateWorkoutRoutinePage(routine: routine)),
                            ).then((_) => _loadData());
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar rutina'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (routineDays.isEmpty)
                    Text('No hay dias configurados en esta rutina.',
                        style:
                            TextStyle(color: scheme.onSurface.withOpacity(0.7)))
                  else
                    ...routineDays.map((day) {
                      final dayExercises = _allExercises
                          .where((e) => e.dayId == day.id)
                          .toList()
                        ..sort((a, b) => a.order.compareTo(b.order));
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(day.name,
                                style: TextStyle(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            const SizedBox(height: 8),
                            if (dayExercises.isEmpty)
                              Text('Sin ejercicios',
                                  style: TextStyle(
                                      color: scheme.onSurface.withOpacity(0.6)))
                            else
                              ...dayExercises
                                  .map((e) => _exerciseTile(e, scheme)),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

Widget _infoStat(
    ColorScheme scheme, IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: scheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: scheme.onSurface.withOpacity(0.7), fontSize: 12)),
              Text(value,
                  style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ],
          ),
        ),
      ],
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



