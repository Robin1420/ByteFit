import 'package:flutter/material.dart';
import '../../data/repositories/workout_exercise_repository.dart';
import '../../data/datasources/local_datasource.dart';
import '../../domain/entities/workout_day.dart';
import '../../domain/entities/workout_exercise.dart';
import 'create_workout_exercise_page.dart';

class WorkoutExerciseDetailPage extends StatefulWidget {
  final WorkoutDay day;

  const WorkoutExerciseDetailPage({
    super.key,
    required this.day,
  });

  @override
  State<WorkoutExerciseDetailPage> createState() => _WorkoutExerciseDetailPageState();
}

class _WorkoutExerciseDetailPageState extends State<WorkoutExerciseDetailPage> {
  late final WorkoutExerciseRepository _exerciseRepository;
  List<WorkoutExercise> _exercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _exerciseRepository = WorkoutExerciseRepository(LocalDataSource());
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final exercises = await _exerciseRepository.getExercisesByDayId(widget.day.id);
      // Ordenar por order
      exercises.sort((a, b) => a.order.compareTo(b.order));
      
      setState(() {
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading exercises: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.day.name),
        backgroundColor: const Color(0xFF0080F5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExercises,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _exercises.isEmpty
              ? _buildEmptyState()
              : _buildExercisesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateWorkoutExercisePage(
                dayId: widget.day.id,
                dayName: widget.day.name,
              ),
            ),
          );
          if (result == true) {
            _loadExercises();
          }
        },
        backgroundColor: const Color(0xFF0080F5),
        child: const Icon(Icons.add, color: Colors.white),
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
            'No hay ejercicios agregados',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Agrega ejercicios a este día de entrenamiento',
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
                  builder: (context) => CreateWorkoutExercisePage(
                    dayId: widget.day.id,
                    dayName: widget.day.name,
                  ),
                ),
              );
              if (result == true) {
                _loadExercises();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Agregar Primer Ejercicio'),
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

  Widget _buildExercisesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _exercises.length,
      itemBuilder: (context, index) {
        final exercise = _exercises[index];
        return _buildExerciseCard(exercise);
      },
    );
  }

  Widget _buildExerciseCard(WorkoutExercise exercise) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _showExerciseDetails(exercise),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono del ejercicio
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0080F5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getExerciseIcon(exercise.name),
                  color: const Color(0xFF0080F5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Información del ejercicio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildInfoChip('${exercise.sets} sets'),
                        const SizedBox(width: 8),
                        _buildInfoChip(exercise.reps),
                        const SizedBox(width: 8),
                        if (exercise.weight > 0)
                          _buildInfoChip('${exercise.weight}kg'),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Flecha de navegación
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  IconData _getExerciseIcon(String exerciseName) {
    final name = exerciseName.toLowerCase();
    
    if (name.contains('curl') || name.contains('bíceps')) {
      return Icons.fitness_center;
    } else if (name.contains('dominada') || name.contains('pull')) {
      return Icons.sports_gymnastics;
    } else if (name.contains('elevación') || name.contains('lateral')) {
      return Icons.sports;
    } else if (name.contains('pantorrilla') || name.contains('calf')) {
      return Icons.directions_run;
    } else if (name.contains('press') || name.contains('empuje')) {
      return Icons.sports_handball;
    } else if (name.contains('sentadilla') || name.contains('squat')) {
      return Icons.sports_tennis;
    } else {
      return Icons.fitness_center;
    }
  }

  Future<void> _showExerciseDetails(WorkoutExercise exercise) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(exercise.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Series', '${exercise.sets}'),
            _buildDetailRow('Repeticiones', exercise.reps),
            if (exercise.weight > 0)
              _buildDetailRow('Peso', '${exercise.weight} kg'),
            _buildDetailRow('Descanso', '${exercise.restTimeSeconds} segundos'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteExercise(exercise);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _deleteExercise(WorkoutExercise exercise) async {
    try {
      await _exerciseRepository.deleteExercise(exercise.id);
      _loadExercises();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ejercicio eliminado'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
