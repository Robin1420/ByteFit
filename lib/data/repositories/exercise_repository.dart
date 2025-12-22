import '../../domain/entities/exercise.dart';
import '../datasources/local_datasource.dart';

class ExerciseRepository {
  final LocalDataSource _dataSource;

  ExerciseRepository(this._dataSource);

  Future<void> saveExercise(Exercise exercise) async {
    await _dataSource.saveExercise(exercise);
  }

  Future<List<Exercise>> getExercises() async {
    return await _dataSource.getExercises();
  }

  Future<List<Exercise>> getExercisesByDate(DateTime date) async {
    return await _dataSource.getExercisesByDate(date);
  }

  Future<void> updateExercise(int key, Exercise exercise) async {
    await _dataSource.updateExercise(key, exercise);
  }

  Future<void> deleteExercise(int key) async {
    await _dataSource.deleteExercise(key);
  }

  // Obtener ejercicios de la última semana
  Future<List<Exercise>> getExercisesLastWeek() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final allExercises = await getExercises();
    return allExercises
        .where((exercise) => exercise.fecha.isAfter(weekAgo))
        .toList();
  }

  // Obtener calorías quemadas totales de un día
  Future<double> getTotalBurnedCaloriesByDate(DateTime date) async {
    final exercises = await getExercisesByDate(date);
    return exercises.fold<double>(
        0, (sum, exercise) => sum + exercise.caloriasQuemadas);
  }

  // Obtener todos los ejercicios
  Future<List<Exercise>> getAllExercises() async {
    return await getExercises();
  }

  // Eliminar todos los ejercicios
  Future<void> deleteAllExercises() async {
    final exercises = await getExercises();
    for (final exercise in exercises) {
      await deleteExercise(exercise.id);
    }
  }
}
