import 'package:flutter/material.dart';
import '../../data/repositories/workout_routine_repository.dart';
import '../../data/repositories/workout_day_repository.dart';
import '../../data/repositories/workout_exercise_repository.dart';
import '../../data/datasources/local_datasource.dart';
import '../../domain/entities/workout_routine.dart';
import '../../domain/entities/workout_day.dart';
import '../../domain/entities/workout_exercise.dart';
import 'create_workout_routine_page.dart';
import 'create_workout_exercise_page.dart';

class AddExercisePage extends StatefulWidget {
  const AddExercisePage({super.key});

  @override
  State<AddExercisePage> createState() => _AddExercisePageState();
}

class _AddExercisePageState extends State<AddExercisePage> {
  late final WorkoutRoutineRepository _routineRepository;
  late final WorkoutDayRepository _dayRepository;
  late final WorkoutExerciseRepository _exerciseRepository;
  List<WorkoutRoutine> _routines = [];
  List<WorkoutDay> _allDays = [];
  List<WorkoutExercise> _selectedDayExercises = [];
  bool _isLoading = true;
  String _selectedDay = '';
  WorkoutRoutine? _selectedRoutine;

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
      
      final routines = await _routineRepository.getRoutines();
      final allDays = await _dayRepository.getDays();
      
      // Inicializar con el día actual si no hay día seleccionado
      if (_selectedDay.isEmpty) {
        final today = DateTime.now();
        _selectedDay = _getDayName(today.weekday);
      }
      
      // Cargar ejercicios del día seleccionado
      await _loadExercisesForDay(_selectedDay);
      
      setState(() {
        _routines = routines;
        _allDays = allDays;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadExercisesForDay(String dayName) async {
    final dayDays = _allDays.where((day) => day.name == dayName).toList();
    List<WorkoutExercise> exercises = [];
    
    for (final day in dayDays) {
      final dayExercises = await _exerciseRepository.getExercisesByDayId(day.id);
      exercises.addAll(dayExercises);
    }
    
    setState(() {
      _selectedDayExercises = exercises;
    });
  }

  String _getDayName(int weekday) {
    const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejercicios'),
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
          : _routines.isEmpty
              ? _buildEmptyState()
              : _buildMainContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateWorkoutRoutinePage(),
            ),
          );
          if (result == true) {
            _loadData();
          }
        },
        backgroundColor: const Color(0xFF0080F5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con selector de día
          _buildDaySelector(),
          const SizedBox(height: 20),
          
          // Ejercicios del día seleccionado
          _buildDayExercises(),
          const SizedBox(height: 20),
          
          // Botones de acción
          _buildActionButtons(),
          const SizedBox(height: 20),
          
          // Lista de rutinas
          _buildRoutinesSection(),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
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
                  'Entrenamiento',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedDay,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_selectedDayExercises.length} ejercicios programados',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showDaySelector,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_today,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDaySelector() {
    final days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Seleccionar Día',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...days.map((day) => ListTile(
              title: Text(day),
              selected: day == _selectedDay,
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedDay = day;
                });
                _loadExercisesForDay(day);
              },
              trailing: day == _selectedDay ? const Icon(Icons.check, color: Color(0xFF0080F5)) : null,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDayExercises() {
    if (_selectedDayExercises.isEmpty) {
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
                'No hay ejercicios programados para $_selectedDay',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Agrega ejercicios a tus rutinas para verlos aquí',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
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
            Row(
              children: [
                const Text(
                  'Ejercicios de ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _selectedDay,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0080F5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._selectedDayExercises.map((exercise) => _buildExerciseItem(exercise)),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseItem(WorkoutExercise exercise) {
    return Container(
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
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _addExercise,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Ejercicio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0080F5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _manageRoutines,
            icon: const Icon(Icons.settings),
            label: const Text('Gestionar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0080F5),
              side: const BorderSide(color: Color(0xFF0080F5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoutinesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mis Rutinas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._routines.map((routine) => _buildRoutineCard(routine)),
      ],
    );
  }

  Widget _buildRoutineCard(WorkoutRoutine routine) {
    final isSelected = _selectedRoutine?.id == routine.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected ? const BorderSide(color: Color(0xFF0080F5), width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _selectRoutine(routine),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF0080F5) 
                          : const Color(0xFF0080F5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: isSelected ? Colors.white : const Color(0xFF0080F5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      routine.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? const Color(0xFF0080F5) : null,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF0080F5),
                      size: 20,
                    )
                  else
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleRoutineAction(value, routine),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 16),
                              SizedBox(width: 8),
                              Text('Eliminar', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: const Icon(Icons.more_vert, color: Colors.grey),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: routine.isActive ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      routine.isActive ? 'Activa' : 'Inactiva',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Text(
                      'Mostrando ejercicios',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    TextButton(
                      onPressed: () => _selectRoutine(routine),
                      child: const Text('Ver Ejercicios'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'No tienes rutinas creadas',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Crea tu primera rutina para comenzar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateWorkoutRoutinePage(),
                ),
              );
              if (result == true) {
                _loadData();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Crear Primera Rutina'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0080F5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectRoutine(WorkoutRoutine routine) async {
    setState(() {
      _selectedRoutine = routine;
    });
    
    // Cargar ejercicios de esta rutina para el día seleccionado
    final routineDays = _allDays.where((day) => 
        day.routineId == routine.id && day.name == _selectedDay).toList();
    
    List<WorkoutExercise> routineExercises = [];
    for (final day in routineDays) {
      final exercises = await _exerciseRepository.getExercisesByDayId(day.id);
      routineExercises.addAll(exercises);
    }
    
    setState(() {
      _selectedDayExercises = routineExercises;
    });
  }

  void _addExercise() {
    final dayDays = _allDays.where((day) => day.name == _selectedDay).toList();
    
    if (dayDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay días de entrenamiento programados para $_selectedDay'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Usar el primer día del día seleccionado
    final firstDay = dayDays.first;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateWorkoutExercisePage(
          dayId: firstDay.id,
          dayName: firstDay.name,
        ),
      ),
    ).then((_) => _loadExercisesForDay(_selectedDay));
  }

  void _manageRoutines() {
    // Mostrar opciones de gestión
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Nueva Rutina'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateWorkoutRoutinePage(),
                  ),
                ).then((_) => _loadData());
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurar Rutinas'),
              onTap: () {
                Navigator.pop(context);
                // Aquí podrías navegar a una página de configuración
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleRoutineAction(String action, WorkoutRoutine routine) {
    switch (action) {
      case 'edit':
        // Implementar edición de rutina
        break;
      case 'delete':
        _deleteRoutine(routine);
        break;
    }
  }

  Future<void> _deleteRoutine(WorkoutRoutine routine) async {
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