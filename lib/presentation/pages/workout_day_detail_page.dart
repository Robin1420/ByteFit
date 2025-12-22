import 'package:flutter/material.dart';
import '../../data/repositories/workout_day_repository.dart';
import '../../data/repositories/workout_exercise_repository.dart';
import '../../data/datasources/local_datasource.dart';
import '../../domain/entities/workout_routine.dart';
import '../../domain/entities/workout_day.dart';
import '../../domain/entities/workout_exercise.dart';
import 'create_workout_day_page.dart';
import 'workout_exercise_detail_page.dart';

class WorkoutDayDetailPage extends StatefulWidget {
  final WorkoutRoutine routine;

  const WorkoutDayDetailPage({
    super.key,
    required this.routine,
  });

  @override
  State<WorkoutDayDetailPage> createState() => _WorkoutDayDetailPageState();
}

class _WorkoutDayDetailPageState extends State<WorkoutDayDetailPage> {
  late final WorkoutDayRepository _dayRepository;
  late final WorkoutExerciseRepository _exerciseRepository;
  List<WorkoutDay> _days = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dayRepository = WorkoutDayRepository(LocalDataSource());
    _exerciseRepository = WorkoutExerciseRepository(LocalDataSource());
    _loadDays();
  }

  Future<void> _loadDays() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final days = await _dayRepository.getDaysByRoutineId(widget.routine.id);
      // Ordenar por order
      days.sort((a, b) => a.order.compareTo(b.order));

      setState(() {
        _days = days;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading days: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routine.name),
        backgroundColor: const Color(0xFF0080F5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDays,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _days.isEmpty
              ? _buildEmptyState()
              : _buildDaysList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateWorkoutDayPage(
                routineId: widget.routine.id,
                routineName: widget.routine.name,
              ),
            ),
          );
          if (result == true) {
            _loadDays();
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
            Icons.calendar_today,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'No hay dÃƒÆ’Ã‚Â­as configurados',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Agrega dÃƒÆ’Ã‚Â­as de entrenamiento a tu rutina',
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
                  builder: (context) => CreateWorkoutDayPage(
                    routineId: widget.routine.id,
                    routineName: widget.routine.name,
                  ),
                ),
              );
              if (result == true) {
                _loadDays();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Agregar Primer DÃƒÆ’Ã‚Â­a'),
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

  Widget _buildDaysList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _days.length,
      itemBuilder: (context, index) {
        final day = _days[index];
        return _buildDayCard(day);
      },
    );
  }

  Widget _buildDayCard(WorkoutDay day) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showDayExercises(day),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0080F5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF0080F5),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'DÃƒÆ’Ã‚Â­a ${day.order} de la rutina',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
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

  Future<void> _showDayExercises(WorkoutDay day) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutExerciseDetailPage(day: day),
      ),
    );
    if (result == true) {
      _loadDays();
    }
  }
}
