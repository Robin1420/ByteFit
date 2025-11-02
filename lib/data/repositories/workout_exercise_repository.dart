import '../../domain/entities/workout_exercise.dart';
import '../datasources/local_datasource.dart';

class WorkoutExerciseRepository {
  final LocalDataSource _dataSource;

  WorkoutExerciseRepository(this._dataSource);

  Future<void> saveExercise(WorkoutExercise exercise) async {
    await _dataSource.saveWorkoutExercise(exercise);
  }

  Future<List<WorkoutExercise>> getExercises() async {
    return await _dataSource.getWorkoutExercises();
  }

  Future<List<WorkoutExercise>> getExercisesByDayId(int dayId) async {
    final allExercises = await _dataSource.getWorkoutExercises();
    return allExercises.where((exercise) => exercise.dayId == dayId).toList();
  }

  Future<List<WorkoutExercise>> getExercisesByDay(int dayId) async {
    final exercises = await getExercises();
    return exercises.where((exercise) => exercise.dayId == dayId).toList();
  }

  Future<WorkoutExercise?> getExerciseById(int id) async {
    return await _dataSource.getWorkoutExerciseById(id);
  }

  Future<void> updateExercise(int key, WorkoutExercise exercise) async {
    await _dataSource.updateWorkoutExercise(key, exercise);
  }

  Future<void> deleteExercise(int key) async {
    await _dataSource.deleteWorkoutExercise(key);
  }

  Future<void> deleteExercisesByDay(int dayId) async {
    final exercises = await getExercisesByDay(dayId);
    for (final exercise in exercises) {
      await deleteExercise(exercise.id);
    }
  }

  Future<void> deleteExercisesByRoutine(int routineId) async {
    final exercises = await getExercises();
    for (final exercise in exercises) {
      // Necesitaríamos obtener el dayId para verificar si pertenece a la rutina
      // Por ahora, eliminamos todos los ejercicios
      await deleteExercise(exercise.id);
    }
  }
}
