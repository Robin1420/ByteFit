import '../../domain/entities/workout_day.dart';
import '../datasources/local_datasource.dart';

class WorkoutDayRepository {
  final LocalDataSource _dataSource;

  WorkoutDayRepository(this._dataSource);

  Future<void> saveDay(WorkoutDay day) async {
    await _dataSource.saveWorkoutDay(day);
  }

  Future<List<WorkoutDay>> getDays() async {
    return await _dataSource.getWorkoutDays();
  }

  Future<List<WorkoutDay>> getDaysByRoutineId(int routineId) async {
    final allDays = await _dataSource.getWorkoutDays();
    return allDays.where((day) => day.routineId == routineId).toList();
  }

  Future<List<WorkoutDay>> getDaysByRoutine(int routineId) async {
    final days = await getDays();
    return days.where((day) => day.routineId == routineId).toList();
  }

  Future<WorkoutDay?> getDayById(int id) async {
    return await _dataSource.getWorkoutDayById(id);
  }

  Future<void> updateDay(int key, WorkoutDay day) async {
    await _dataSource.updateWorkoutDay(key, day);
  }

  Future<void> deleteDay(int key) async {
    await _dataSource.deleteWorkoutDay(key);
  }

  Future<void> deleteDaysByRoutine(int routineId) async {
    final days = await getDaysByRoutine(routineId);
    for (final day in days) {
      await deleteDay(day.id);
    }
  }
}
