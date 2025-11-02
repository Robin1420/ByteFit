import '../../domain/entities/workout_routine.dart';
import '../datasources/local_datasource.dart';

class WorkoutRoutineRepository {
  final LocalDataSource _dataSource;

  WorkoutRoutineRepository(this._dataSource);

  Future<void> saveRoutine(WorkoutRoutine routine) async {
    await _dataSource.saveWorkoutRoutine(routine);
  }

  Future<List<WorkoutRoutine>> getRoutines() async {
    return await _dataSource.getWorkoutRoutines();
  }

  Future<WorkoutRoutine?> getRoutineById(int id) async {
    return await _dataSource.getWorkoutRoutineById(id);
  }

  Future<void> updateRoutine(int key, WorkoutRoutine routine) async {
    await _dataSource.updateWorkoutRoutine(key, routine);
  }

  Future<void> deleteRoutine(int key) async {
    await _dataSource.deleteWorkoutRoutine(key);
  }

  Future<List<WorkoutRoutine>> getActiveRoutines() async {
    final routines = await getRoutines();
    return routines.where((routine) => routine.isActive).toList();
  }

  Future<void> setActiveRoutine(int routineId) async {
    // Desactivar todas las rutinas
    final routines = await getRoutines();
    for (final routine in routines) {
      if (routine.id != routineId) {
        await updateRoutine(routine.id, routine.copyWith(isActive: false));
      }
    }
    
    // Activar la rutina seleccionada
    final routine = await getRoutineById(routineId);
    if (routine != null) {
      await updateRoutine(routineId, routine.copyWith(isActive: true));
    }
  }
}
