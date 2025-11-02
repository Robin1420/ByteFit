import 'package:flutter/material.dart';
import 'dart:io';
import '../../data/repositories/workout_routine_repository.dart';
import '../../data/repositories/workout_day_repository.dart';
import '../../data/repositories/workout_exercise_repository.dart';
import '../../data/datasources/local_datasource.dart';
import '../../domain/entities/workout_routine.dart';
import '../../domain/entities/workout_day.dart';
import '../../domain/entities/workout_exercise.dart';
import '../../domain/entities/exercise_db_entity.dart';
import '../../services/exercise_cache_service.dart';
import '../../i18n/i18n.dart';
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
  List<WorkoutExercise> _todayExercises = [];
  List<WorkoutRoutine> _routines = [];
  List<WorkoutDay> _allDays = [];
  List<WorkoutExercise> _allExercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _routineRepository = WorkoutRoutineRepository(LocalDataSource());
    _dayRepository = WorkoutDayRepository(LocalDataSource());
    _exerciseRepository = WorkoutExerciseRepository(LocalDataSource());
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Cargar rutinas
      final routines = await _routineRepository.getRoutines();
      
      // Cargar todos los días
      final allDays = await _dayRepository.getDays();
      
      // Cargar todos los ejercicios
      final allExercises = await _exerciseRepository.getExercises();
      
      // Cargar ejercicios de hoy
      final today = DateTime.now();
      final todayName = _getDayName(today.weekday);
      final todayDays = allDays.where((day) => day.name == todayName).toList();
      
      // Obtener ejercicios de los días de hoy
      List<WorkoutExercise> todayExercises = [];
      for (final day in todayDays) {
        final exercises = await _exerciseRepository.getExercisesByDayId(day.id);
        todayExercises.addAll(exercises);
      }
      
      setState(() {
        _routines = routines;
        _allDays = allDays;
        _allExercises = allExercises;
        _todayExercises = todayExercises;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getDayName(int weekday) {
    const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return days[weekday - 1];
  }

  void _handleAiInfo(WorkoutExercise exercise) async {
    // Mostrar información del ejercicio desde Hive
    _showExerciseDetails(exercise);
  }

  void _showExerciseDetails(WorkoutExercise exercise) async {
    // Buscar el ejercicio en Hive por nombre
    final exerciseCacheService = ExerciseCacheService();
    await exerciseCacheService.init();
    
    final allExercises = await exerciseCacheService.getAllExercises();
    
    if (allExercises.isEmpty) {
      // Si no hay ejercicios en Hive, mostrar información básica
      _showBasicExerciseInfo(exercise);
      return;
    }
    
    // Buscar el ejercicio por nombre exacto o traducido
    ExerciseDbEntity? exerciseDb;
    try {
      exerciseDb = allExercises.firstWhere(
        (e) => e.name.toLowerCase() == exercise.name.toLowerCase(),
      );
    } catch (e) {
      try {
        exerciseDb = allExercises.firstWhere(
          (e) => I18n.translateExercise(e.name).toLowerCase() == exercise.name.toLowerCase(),
        );
      } catch (e) {
        // Si no se encuentra, usar el primer ejercicio como fallback
        exerciseDb = allExercises.first;
      }
    }
    
    // Mostrar modal con información completa del ejercicio
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    I18n.translateExercise(exerciseDb?.name ?? exercise.name),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // GIF del ejercicio
                    if (exerciseDb?.gifUrl.isNotEmpty == true)
                      FutureBuilder<String?>(
                        future: exerciseCacheService.getLocalGifPath(exerciseDb!.exerciseId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done && 
                              snapshot.hasData && 
                              snapshot.data != null) {
                            return Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(snapshot.data!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => 
                                    const Center(child: Icon(Icons.broken_image, size: 50)),
                                ),
                              ),
                            );
                          } else {
                            return Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                        },
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Músculos principales
                    if (exerciseDb?.targetMuscles.isNotEmpty == true) ...[
                      Text(
                        'Músculos Principales:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: exerciseDb!.targetMuscles.map((muscle) => Chip(
                          label: Text(I18n.translateMuscle(muscle)),
                          backgroundColor: Colors.blue[100],
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Músculos secundarios
                    if (exerciseDb?.secondaryMuscles.isNotEmpty == true) ...[
                      Text(
                        'Músculos Secundarios:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: exerciseDb!.secondaryMuscles.map((muscle) => Chip(
                          label: Text(I18n.translateMuscle(muscle)),
                          backgroundColor: Colors.grey[200],
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Partes del cuerpo
                    if (exerciseDb?.bodyParts.isNotEmpty == true) ...[
                      Text(
                        'Partes del Cuerpo:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: exerciseDb!.bodyParts.map((part) => Chip(
                          label: Text(I18n.translateBodyPart(part)),
                          backgroundColor: Colors.green[100],
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Equipamiento
                    if (exerciseDb?.equipments.isNotEmpty == true) ...[
                      Text(
                        'Equipamiento:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: exerciseDb!.equipments.map((equipment) => Chip(
                          label: Text(I18n.translateEquipment(equipment)),
                          backgroundColor: Colors.orange[100],
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Instrucciones
                    if (exerciseDb?.instructions.isNotEmpty == true) ...[
                      Text(
                        'Instrucciones:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...exerciseDb!.instructions.map((instruction) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('• $instruction'),
                      )),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBasicExerciseInfo(WorkoutExercise exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(exercise.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ejercicio: ${exercise.name}'),
            const SizedBox(height: 8),
            Text('Series: ${exercise.sets}'),
            Text('Repeticiones: ${exercise.reps}'),
            if (exercise.weight > 0) Text('Peso: ${exercise.weight} kg'),
            Text('Descanso: ${exercise.restTimeSeconds} seg'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayName = _getDayName(today.weekday);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Rutinas'),
        backgroundColor: const Color(0xFF0080F5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildTodayContent(todayName),
    );
  }

  Widget _buildTodayContent(String todayName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con día actual
          _buildTodayHeader(todayName),
          const SizedBox(height: 20),
          
          // Ejercicios de hoy
          _buildTodayExercises(),
          const SizedBox(height: 20),
          
          // Sección de rutinas creadas
          _buildRoutinesSection(),
        ],
      ),
    );
  }

  Widget _buildTodayHeader(String todayName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0080F5),
            const Color(0xFF0080F5).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ejercicios Programados',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Para $todayName',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _todayExercises.isEmpty 
                    ? 'No hay ejercicios programados'
                    : '${_todayExercises.length} ejercicios programados',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayExercises() {
    if (_todayExercises.isEmpty) {
      final today = DateTime.now();
      final todayName = _getDayName(today.weekday);
      
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.fitness_center_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                'No hay ejercicios programados para $todayName',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Ve a la sección de Ejercicios para crear rutinas y asignarlas a días específicos',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entrenamiento de Hoy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._todayExercises.map((exercise) => _buildExerciseItem(exercise)),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseItem(WorkoutExercise exercise) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0080F5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Color(0xFF0080F5),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${exercise.sets} series × ${exercise.reps} reps',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (exercise.weight > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0080F5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${exercise.weight} kg',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0080F5),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              // Botón de información del ejercicio
              GestureDetector(
                onTap: () => _handleAiInfo(exercise),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0080F5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF0080F5),
                    ),
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    color: Color(0xFF0080F5),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildRoutinesSection() {
    if (_routines.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.fitness_center,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              const Text(
                'No tienes rutinas creadas',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Crea tu primera rutina para comenzar',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _addRoutine,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar Primera Rutina'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0080F5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Rutinas Creadas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addRoutine,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar Rutina'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0080F5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._routines.map((routine) => _buildRoutineCard(routine)),
      ],
    );
  }

  Widget _buildRoutineCard(WorkoutRoutine routine) {
    // Obtener días asignados a esta rutina
    final routineDays = _allDays.where((day) => day.routineId == routine.id).toList();
    final dayNames = routineDays.map((day) => day.name).toList();
    final exerciseCount = _getExerciseCountForRoutine(routine.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _editRoutine(routine),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con nombre y botones
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0080F5), Color(0xFF0066CC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0080F5).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            routine.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            routine.description.isNotEmpty 
                                ? routine.description 
                                : 'Rutina de entrenamiento',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontStyle: routine.description.isEmpty ? FontStyle.italic : FontStyle.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Botones de acción
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editRoutine(routine);
                        } else if (value == 'delete') {
                          _deleteRoutine(routine);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18, color: Color(0xFF0080F5)),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Eliminar', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.more_vert,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Información de días y ejercicios
                Row(
                  children: [
                    // Días asignados
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Días',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (dayNames.isNotEmpty)
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: dayNames.map((day) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF0080F5).withOpacity(0.1),
                                      const Color(0xFF0080F5).withOpacity(0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF0080F5).withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  day,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF0080F5),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )).toList(),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.orange[200]!,
                                ),
                              ),
                              child: const Text(
                                'Sin días asignados',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Cantidad de ejercicios
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 4),
                            Text(
                              'Ejercicios',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.withOpacity(0.1),
                                Colors.green.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '$exerciseCount',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getExerciseCountForRoutine(int routineId) {
    final routineDays = _allDays.where((day) => day.routineId == routineId).toList();
    int totalExercises = 0;
    
    for (final day in routineDays) {
      final dayExercises = _allExercises.where((exercise) => exercise.dayId == day.id).toList();
      totalExercises += dayExercises.length;
    }
    
    return totalExercises;
  }

  void _addRoutine() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateWorkoutRoutinePage(),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _editRoutine(WorkoutRoutine routine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditRoutineModal(
        routine: routine,
        allDays: _allDays,
        allExercises: _allExercises,
        dayRepository: _dayRepository,
        exerciseRepository: _exerciseRepository,
        routineRepository: _routineRepository,
        onRoutineUpdated: () {
          _loadData();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _deleteRoutine(WorkoutRoutine routine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Rutina'),
        content: Text('¿Estás seguro de que quieres eliminar la rutina "${routine.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _routineRepository.deleteRoutine(routine.id);
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rutina eliminada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar rutina: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _EditRoutineModal extends StatefulWidget {
  final WorkoutRoutine routine;
  final List<WorkoutDay> allDays;
  final List<WorkoutExercise> allExercises;
  final WorkoutDayRepository dayRepository;
  final WorkoutExerciseRepository exerciseRepository;
  final WorkoutRoutineRepository routineRepository;
  final VoidCallback onRoutineUpdated;

  const _EditRoutineModal({
    required this.routine,
    required this.allDays,
    required this.allExercises,
    required this.dayRepository,
    required this.exerciseRepository,
    required this.routineRepository,
    required this.onRoutineUpdated,
  });

  @override
  State<_EditRoutineModal> createState() => _EditRoutineModalState();
}

class _EditRoutineModalState extends State<_EditRoutineModal> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  List<String> _selectedDays = [];
  List<WorkoutExercise> _routineExercises = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine.name);
    _descriptionController = TextEditingController(text: widget.routine.description);
    _loadRoutineData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadRoutineData() {
    // Obtener días asignados a esta rutina
    final routineDays = widget.allDays.where((day) => day.routineId == widget.routine.id).toList();
    _selectedDays = routineDays.map((day) => day.name).toList();
    
    // Obtener ejercicios de esta rutina
    _routineExercises = widget.allExercises.where((exercise) {
      return routineDays.any((day) => day.id == exercise.dayId);
    }).toList();
  }

  Future<void> _refreshRoutineData() async {
    try {
      // Recargar días y ejercicios desde la base de datos
      final updatedDays = await widget.dayRepository.getDays();
      final updatedExercises = await widget.exerciseRepository.getExercises();
      
      // Actualizar los datos locales
      widget.allDays.clear();
      widget.allDays.addAll(updatedDays);
      
      // Actualizar ejercicios locales
      widget.allExercises.clear();
      widget.allExercises.addAll(updatedExercises);
      
      // Recargar datos de la rutina
      _loadRoutineData();
      
      setState(() {});
    } catch (e) {
      print('Error refreshing routine data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Editar Rutina',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre de la rutina
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la Rutina',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Descripción
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  
                  // Días de la semana
                  const Text(
                    'Días de la Semana',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo']
                        .map((day) => FilterChip(
                              label: Text(day),
                              selected: _selectedDays.contains(day),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedDays.add(day);
                                  } else {
                                    _selectedDays.remove(day);
                                  }
                                });
                              },
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  
                  // Ejercicios
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ejercicios',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addExercise,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Lista de ejercicios
                  ..._routineExercises.map((exercise) => _buildExerciseItem(exercise)),
                  
                  if (_routineExercises.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'No hay ejercicios agregados',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Botones de acción
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveRoutine,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0080F5),
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseItem(WorkoutExercise exercise) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.fitness_center, color: Color(0xFF0080F5)),
        title: Text(exercise.name),
        subtitle: Text('${exercise.sets} series × ${exercise.reps} reps'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _editExercise(exercise),
              icon: const Icon(Icons.edit, size: 18),
              color: const Color(0xFF0080F5),
            ),
            IconButton(
              onPressed: () => _deleteExercise(exercise),
              icon: const Icon(Icons.delete, size: 18),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  void _addExercise() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddExerciseModal(
        routineId: widget.routine.id,
        allDays: widget.allDays,
        exerciseRepository: widget.exerciseRepository,
        dayRepository: widget.dayRepository,
        onExerciseAdded: (exercise) {
          setState(() {
            _routineExercises.add(exercise);
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _editExercise(WorkoutExercise exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditExerciseModal(
        exercise: exercise,
        allDays: widget.allDays,
        routineId: widget.routine.id,
        exerciseRepository: widget.exerciseRepository,
        onExerciseUpdated: (updatedExercise) {
          setState(() {
            final index = _routineExercises.indexWhere((e) => e.id == exercise.id);
            if (index != -1) {
              _routineExercises[index] = updatedExercise;
            }
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _deleteExercise(WorkoutExercise exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Ejercicio'),
        content: Text('¿Estás seguro de que quieres eliminar "${exercise.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.exerciseRepository.deleteExercise(exercise.id);
        setState(() {
          _routineExercises.remove(exercise);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ejercicio eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar ejercicio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveRoutine() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un nombre para la rutina'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona al menos un día'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Actualizar rutina
      final updatedRoutine = widget.routine.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      await widget.routineRepository.updateRoutine(widget.routine.id, updatedRoutine);

      // Obtener días actuales de la rutina
      final currentDays = widget.allDays.where((day) => day.routineId == widget.routine.id).toList();
      final currentDayNames = currentDays.map((day) => day.name).toList();
      
      // Encontrar días a eliminar (estaban antes pero no están ahora)
      final daysToRemove = currentDayNames.where((dayName) => !_selectedDays.contains(dayName)).toList();
      
      // Encontrar días a agregar (están ahora pero no estaban antes)
      final daysToAdd = _selectedDays.where((dayName) => !currentDayNames.contains(dayName)).toList();
      
      // Eliminar días que ya no están seleccionados
      for (final dayName in daysToRemove) {
        final dayToRemove = currentDays.firstWhere((day) => day.name == dayName);
        // Primero eliminar todos los ejercicios de este día
        final dayExercises = await widget.exerciseRepository.getExercisesByDayId(dayToRemove.id);
        for (final exercise in dayExercises) {
          await widget.exerciseRepository.deleteExercise(exercise.id);
        }
        // Luego eliminar el día
        await widget.dayRepository.deleteDay(dayToRemove.id);
      }
      
      // Agregar nuevos días
      for (final dayName in daysToAdd) {
        // Obtener el siguiente orden para el día
        final existingDays = await widget.dayRepository.getDaysByRoutineId(widget.routine.id);
        final nextOrder = existingDays.length + 1;
        
        final newDay = WorkoutDay(
          id: DateTime.now().microsecondsSinceEpoch % 1000000,
          routineId: widget.routine.id,
          name: dayName,
          order: nextOrder,
        );
        
        await widget.dayRepository.saveDay(newDay);
      }

      // Refrescar datos locales
      await _refreshRoutineData();
      
      widget.onRoutineUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rutina actualizada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar rutina: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

class _AddExerciseModal extends StatefulWidget {
  final int routineId;
  final List<WorkoutDay> allDays;
  final WorkoutExerciseRepository exerciseRepository;
  final WorkoutDayRepository dayRepository;
  final Function(WorkoutExercise) onExerciseAdded;

  const _AddExerciseModal({
    required this.routineId,
    required this.allDays,
    required this.exerciseRepository,
    required this.dayRepository,
    required this.onExerciseAdded,
  });

  @override
  State<_AddExerciseModal> createState() => _AddExerciseModalState();
}

class _AddExerciseModalState extends State<_AddExerciseModal> {
  late TextEditingController _nameController;
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _restTimeController;
  String _selectedDay = '';
  bool _isLoading = false;
  
  // Variables para autocompletado de ejercicios
  late final ExerciseCacheService _exerciseCacheService;
  List<ExerciseDbEntity> _allExercises = [];
  ExerciseDbEntity? _selectedExercise;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _setsController = TextEditingController(text: '3');
    _repsController = TextEditingController(text: '8-12');
    _weightController = TextEditingController(text: '0');
    _restTimeController = TextEditingController(text: '60');
    
    // Inicializar servicio de caché de ejercicios
    _exerciseCacheService = ExerciseCacheService();
    _loadExercises();
    
    // Seleccionar el primer día disponible por defecto
    final routineDays = widget.allDays.where((day) => day.routineId == widget.routineId).toList();
    if (routineDays.isNotEmpty) {
      _selectedDay = routineDays.first.name;
    }
  }

  Future<void> _loadExercises() async {
    try {
      await _exerciseCacheService.init();
      final exercises = await _exerciseCacheService.getAllExercises();
      setState(() {
        _allExercises = exercises;
      });
    } catch (e) {
      print('Error cargando ejercicios: $e');
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _restTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routineDays = widget.allDays.where((day) => day.routineId == widget.routineId).toList();
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Agregar Ejercicio',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Día de la semana
                  const Text(
                    'Día de la Semana',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (routineDays.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: routineDays.map((day) => FilterChip(
                        label: Text(day.name),
                        selected: _selectedDay == day.name,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedDay = day.name;
                            });
                          }
                        },
                      )).toList(),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No hay días asignados a esta rutina. Primero asigna días a la rutina.',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  
                  // Nombre del ejercicio
                  DropdownButtonFormField<ExerciseDbEntity>(
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar Ejercicio',
                      hintText: 'Selecciona un ejercicio...',
                      prefixIcon: Icon(Icons.fitness_center),
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedExercise,
                    items: _allExercises.map((exercise) {
                      final translatedName = I18n.translateExercise(exercise.name);
                      return DropdownMenuItem<ExerciseDbEntity>(
                        value: exercise,
                        child: Text(translatedName),
                      );
                    }).toList(),
                    onChanged: (ExerciseDbEntity? exercise) {
                      setState(() {
                        _selectedExercise = exercise;
                        if (exercise != null) {
                          _nameController.text = I18n.translateExercise(exercise.name);
                        } else {
                          _nameController.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Series y Repeticiones
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _setsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Series',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.repeat),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _repsController,
                          decoration: const InputDecoration(
                            labelText: 'Repeticiones',
                            border: OutlineInputBorder(),
                            hintText: '8-12, AMRAP, etc.',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Peso y Tiempo de descanso
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Peso (kg)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.monitor_weight),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _restTimeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Descanso (seg)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.timer),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Botones de acción
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: routineDays.isEmpty ? null : (_isLoading ? null : _saveExercise),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0080F5),
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Agregar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _saveExercise() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el nombre del ejercicio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDay.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un día'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener el día seleccionado
      final selectedDay = widget.allDays.firstWhere(
        (day) => day.routineId == widget.routineId && day.name == _selectedDay,
      );

      // Obtener el siguiente orden para el ejercicio
      final existingExercises = await widget.exerciseRepository.getExercisesByDayId(selectedDay.id);
      final nextOrder = existingExercises.length + 1;

      // Crear el ejercicio
      final exercise = WorkoutExercise(
        id: DateTime.now().microsecondsSinceEpoch % 1000000,
        dayId: selectedDay.id,
        name: _nameController.text.trim(),
        sets: int.tryParse(_setsController.text) ?? 3,
        reps: _repsController.text.trim(),
        weight: double.tryParse(_weightController.text) ?? 0.0,
        restTimeSeconds: int.tryParse(_restTimeController.text) ?? 60,
        order: nextOrder,
      );

      // Guardar el ejercicio
      await widget.exerciseRepository.saveExercise(exercise);

      // Notificar que se agregó el ejercicio
      widget.onExerciseAdded(exercise);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ejercicio agregado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar ejercicio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

class _EditExerciseModal extends StatefulWidget {
  final WorkoutExercise exercise;
  final List<WorkoutDay> allDays;
  final int routineId;
  final WorkoutExerciseRepository exerciseRepository;
  final Function(WorkoutExercise) onExerciseUpdated;

  const _EditExerciseModal({
    required this.exercise,
    required this.allDays,
    required this.routineId,
    required this.exerciseRepository,
    required this.onExerciseUpdated,
  });

  @override
  State<_EditExerciseModal> createState() => _EditExerciseModalState();
}

class _EditExerciseModalState extends State<_EditExerciseModal> {
  late TextEditingController _nameController;
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _restTimeController;
  String _selectedDay = '';
  bool _isLoading = false;
  
  // Variables para el dropdown de ejercicios
  late final ExerciseCacheService _exerciseCacheService;
  List<ExerciseDbEntity> _allExercises = [];
  ExerciseDbEntity? _selectedExercise;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exercise.name);
    _setsController = TextEditingController(text: widget.exercise.sets.toString());
    _repsController = TextEditingController(text: widget.exercise.reps);
    _weightController = TextEditingController(text: widget.exercise.weight.toString());
    _restTimeController = TextEditingController(text: widget.exercise.restTimeSeconds.toString());
    
    // Inicializar servicio de caché de ejercicios
    _exerciseCacheService = ExerciseCacheService();
    _loadExercises();
    
    // Obtener el día actual del ejercicio
    final currentDay = widget.allDays.firstWhere(
      (day) => day.id == widget.exercise.dayId,
      orElse: () => widget.allDays.first,
    );
    _selectedDay = currentDay.name;
  }

  Future<void> _loadExercises() async {
    try {
      await _exerciseCacheService.init();
      final exercises = await _exerciseCacheService.getAllExercises();
      setState(() {
        _allExercises = exercises;
      });
    } catch (e) {
      print('Error cargando ejercicios: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _restTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routineDays = widget.allDays.where((day) => day.routineId == widget.routineId).toList();
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Editar Ejercicio',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Día de la semana
                  const Text(
                    'Día de la Semana',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (routineDays.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: routineDays.map((day) => FilterChip(
                        label: Text(day.name),
                        selected: _selectedDay == day.name,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedDay = day.name;
                            });
                          }
                        },
                      )).toList(),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No hay días asignados a esta rutina.',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  
                  // Nombre del ejercicio
                  DropdownButtonFormField<ExerciseDbEntity>(
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar Ejercicio',
                      hintText: 'Selecciona un ejercicio...',
                      prefixIcon: Icon(Icons.fitness_center),
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedExercise,
                    items: _allExercises.map((exercise) {
                      final translatedName = I18n.translateExercise(exercise.name);
                      return DropdownMenuItem<ExerciseDbEntity>(
                        value: exercise,
                        child: Text(translatedName),
                      );
                    }).toList(),
                    onChanged: (ExerciseDbEntity? exercise) {
                      setState(() {
                        _selectedExercise = exercise;
                        if (exercise != null) {
                          _nameController.text = I18n.translateExercise(exercise.name);
                        } else {
                          _nameController.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Series y Repeticiones
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _setsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Series',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.repeat),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _repsController,
                          decoration: const InputDecoration(
                            labelText: 'Repeticiones',
                            border: OutlineInputBorder(),
                            hintText: '8-12, AMRAP, etc.',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Peso y Tiempo de descanso
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Peso (kg)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.monitor_weight),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _restTimeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Descanso (seg)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.timer),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Botones de acción
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: routineDays.isEmpty ? null : (_isLoading ? null : _updateExercise),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0080F5),
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Actualizar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateExercise() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el nombre del ejercicio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDay.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un día'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener el día seleccionado
      final selectedDay = widget.allDays.firstWhere(
        (day) => day.routineId == widget.routineId && day.name == _selectedDay,
      );

      // Crear el ejercicio actualizado
      final updatedExercise = widget.exercise.copyWith(
        dayId: selectedDay.id,
        name: _nameController.text.trim(),
        sets: int.tryParse(_setsController.text) ?? widget.exercise.sets,
        reps: _repsController.text.trim(),
        weight: double.tryParse(_weightController.text) ?? widget.exercise.weight,
        restTimeSeconds: int.tryParse(_restTimeController.text) ?? widget.exercise.restTimeSeconds,
      );

      // Actualizar el ejercicio
      await widget.exerciseRepository.updateExercise(updatedExercise.id, updatedExercise);

      // Notificar que se actualizó el ejercicio
      widget.onExerciseUpdated(updatedExercise);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ejercicio actualizado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar ejercicio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}