import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/meal.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/daily_summary.dart';
import '../../domain/entities/workout_routine.dart';
import '../../domain/entities/workout_day.dart';
import '../../domain/entities/workout_exercise.dart';
import '../../domain/entities/exercise_ai_info.dart';

class LocalDataSource {
  static const String _userBox = 'user_box';
  static const String _mealsBox = 'meals_box';
  static const String _exercisesBox = 'exercises_box';
  static const String _dailySummaryBox = 'daily_summary_box';
  static const String _workoutRoutinesBox = 'workout_routines_box';
  static const String _workoutDaysBox = 'workout_days_box';
  static const String _workoutExercisesBox = 'workout_exercises_box';
  static const String _exerciseAiInfoBox = 'exercise_ai_info_box';

  static Future<void> init() async {
    try {
      // Inicializar Hive Flutter
      await Hive.initFlutter();
      
      // Registrar adapters solo si no están registrados
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(UserAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(MealAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(ExerciseAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(WorkoutRoutineAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(WorkoutDayAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(WorkoutExerciseAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(DailySummaryAdapter());
      }
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(ExerciseAiInfoAdapter());
      }
      
      // Abrir boxes
      await Hive.openBox<User>(_userBox);
      await Hive.openBox<Meal>(_mealsBox);
      await Hive.openBox<Exercise>(_exercisesBox);
      await Hive.openBox<DailySummary>(_dailySummaryBox);
      await Hive.openBox<WorkoutRoutine>(_workoutRoutinesBox);
      await Hive.openBox<WorkoutDay>(_workoutDaysBox);
      await Hive.openBox<WorkoutExercise>(_workoutExercisesBox);
      await Hive.openBox<ExerciseAiInfo>(_exerciseAiInfoBox);
      
      print('Hive initialized successfully with all boxes opened');
    } catch (e) {
      print('Error initializing Hive: $e');
      rethrow;
    }
  }

  // User operations
  Future<void> saveUser(User user) async {
    try {
      if (!Hive.isBoxOpen(_userBox)) {
        await Hive.openBox<User>(_userBox);
      }
      final box = Hive.box<User>(_userBox);
      await box.put('current_user', user);
      print('User saved successfully');
    } catch (e) {
      print('Error saving user: $e');
      rethrow;
    }
  }

  Future<User?> getUser() async {
    final box = Hive.box<User>(_userBox);
    return box.get('current_user');
  }

  Future<void> deleteUser() async {
    final box = Hive.box<User>(_userBox);
    await box.delete('current_user');
  }

  // Meal operations
  Future<void> saveMeal(Meal meal) async {
    final box = Hive.box<Meal>(_mealsBox);
    await box.add(meal);
  }

  Future<List<Meal>> getMeals() async {
    final box = Hive.box<Meal>(_mealsBox);
    return box.values.toList();
  }

  Future<List<Meal>> getMealsByDate(DateTime date) async {
    try {
      if (!Hive.isBoxOpen(_mealsBox)) {
        await Hive.openBox<Meal>(_mealsBox);
      }
      final box = Hive.box<Meal>(_mealsBox);
      return box.values
          .where((meal) => meal.fecha.year == date.year && 
                          meal.fecha.month == date.month && 
                          meal.fecha.day == date.day)
          .toList();
    } catch (e) {
      print('Error getting meals by date: $e');
      return [];
    }
  }

  Future<void> updateMeal(int key, Meal meal) async {
    final box = Hive.box<Meal>(_mealsBox);
    await box.put(key, meal);
  }

  Future<void> deleteMeal(int key) async {
    final box = Hive.box<Meal>(_mealsBox);
    await box.delete(key);
  }

  // Exercise operations
  Future<void> saveExercise(Exercise exercise) async {
    final box = Hive.box<Exercise>(_exercisesBox);
    await box.add(exercise);
  }

  Future<List<Exercise>> getExercises() async {
    final box = Hive.box<Exercise>(_exercisesBox);
    return box.values.toList();
  }

  Future<List<Exercise>> getExercisesByDate(DateTime date) async {
    try {
      if (!Hive.isBoxOpen(_exercisesBox)) {
        await Hive.openBox<Exercise>(_exercisesBox);
      }
      final box = Hive.box<Exercise>(_exercisesBox);
      return box.values
          .where((exercise) => exercise.fecha.year == date.year && 
                              exercise.fecha.month == date.month && 
                              exercise.fecha.day == date.day)
          .toList();
    } catch (e) {
      print('Error getting exercises by date: $e');
      return [];
    }
  }

  Future<void> updateExercise(int key, Exercise exercise) async {
    final box = Hive.box<Exercise>(_exercisesBox);
    await box.put(key, exercise);
  }

  Future<void> deleteExercise(int key) async {
    final box = Hive.box<Exercise>(_exercisesBox);
    await box.delete(key);
  }

  // DailySummary operations
  Future<void> saveDailySummary(DailySummary summary) async {
    final box = Hive.box<DailySummary>(_dailySummaryBox);
    await box.add(summary);
  }

  Future<List<DailySummary>> getDailySummaries() async {
    final box = Hive.box<DailySummary>(_dailySummaryBox);
    return box.values.toList();
  }

  Future<DailySummary?> getDailySummaryByDate(DateTime date) async {
    final box = Hive.box<DailySummary>(_dailySummaryBox);
    try {
      return box.values.firstWhere(
        (summary) => summary.fecha.year == date.year && 
                    summary.fecha.month == date.month && 
                    summary.fecha.day == date.day,
      );
    } catch (e) {
      return null;
    }
  }

  // Workout Routine operations
  Future<void> saveWorkoutRoutine(WorkoutRoutine routine) async {
    try {
      if (!Hive.isBoxOpen(_workoutRoutinesBox)) {
        await Hive.openBox<WorkoutRoutine>(_workoutRoutinesBox);
      }
      final box = Hive.box<WorkoutRoutine>(_workoutRoutinesBox);
      await box.put(routine.id, routine);
      print('Workout routine saved successfully');
    } catch (e) {
      print('Error saving workout routine: $e');
      rethrow;
    }
  }

  Future<List<WorkoutRoutine>> getWorkoutRoutines() async {
    try {
      if (!Hive.isBoxOpen(_workoutRoutinesBox)) {
        await Hive.openBox<WorkoutRoutine>(_workoutRoutinesBox);
      }
      final box = Hive.box<WorkoutRoutine>(_workoutRoutinesBox);
      return box.values.toList();
    } catch (e) {
      print('Error getting workout routines: $e');
      return [];
    }
  }

  Future<WorkoutRoutine?> getWorkoutRoutineById(int id) async {
    try {
      if (!Hive.isBoxOpen(_workoutRoutinesBox)) {
        await Hive.openBox<WorkoutRoutine>(_workoutRoutinesBox);
      }
      final box = Hive.box<WorkoutRoutine>(_workoutRoutinesBox);
      return box.get(id);
    } catch (e) {
      print('Error getting workout routine by id: $e');
      return null;
    }
  }

  Future<void> updateWorkoutRoutine(int key, WorkoutRoutine routine) async {
    try {
      if (!Hive.isBoxOpen(_workoutRoutinesBox)) {
        await Hive.openBox<WorkoutRoutine>(_workoutRoutinesBox);
      }
      final box = Hive.box<WorkoutRoutine>(_workoutRoutinesBox);
      await box.put(key, routine);
    } catch (e) {
      print('Error updating workout routine: $e');
      rethrow;
    }
  }

  Future<void> deleteWorkoutRoutine(int key) async {
    try {
      if (!Hive.isBoxOpen(_workoutRoutinesBox)) {
        await Hive.openBox<WorkoutRoutine>(_workoutRoutinesBox);
      }
      final box = Hive.box<WorkoutRoutine>(_workoutRoutinesBox);
      await box.delete(key);
    } catch (e) {
      print('Error deleting workout routine: $e');
      rethrow;
    }
  }

  // Workout Day operations
  Future<void> saveWorkoutDay(WorkoutDay day) async {
    try {
      if (!Hive.isBoxOpen(_workoutDaysBox)) {
        await Hive.openBox<WorkoutDay>(_workoutDaysBox);
      }
      final box = Hive.box<WorkoutDay>(_workoutDaysBox);
      await box.put(day.id, day);
      print('Workout day saved successfully');
    } catch (e) {
      print('Error saving workout day: $e');
      rethrow;
    }
  }

  Future<List<WorkoutDay>> getWorkoutDays() async {
    try {
      if (!Hive.isBoxOpen(_workoutDaysBox)) {
        await Hive.openBox<WorkoutDay>(_workoutDaysBox);
      }
      final box = Hive.box<WorkoutDay>(_workoutDaysBox);
      return box.values.toList();
    } catch (e) {
      print('Error getting workout days: $e');
      return [];
    }
  }

  Future<WorkoutDay?> getWorkoutDayById(int id) async {
    try {
      if (!Hive.isBoxOpen(_workoutDaysBox)) {
        await Hive.openBox<WorkoutDay>(_workoutDaysBox);
      }
      final box = Hive.box<WorkoutDay>(_workoutDaysBox);
      return box.get(id);
    } catch (e) {
      print('Error getting workout day by id: $e');
      return null;
    }
  }

  Future<void> updateWorkoutDay(int key, WorkoutDay day) async {
    try {
      if (!Hive.isBoxOpen(_workoutDaysBox)) {
        await Hive.openBox<WorkoutDay>(_workoutDaysBox);
      }
      final box = Hive.box<WorkoutDay>(_workoutDaysBox);
      await box.put(key, day);
    } catch (e) {
      print('Error updating workout day: $e');
      rethrow;
    }
  }

  Future<void> deleteWorkoutDay(int key) async {
    try {
      if (!Hive.isBoxOpen(_workoutDaysBox)) {
        await Hive.openBox<WorkoutDay>(_workoutDaysBox);
      }
      final box = Hive.box<WorkoutDay>(_workoutDaysBox);
      await box.delete(key);
    } catch (e) {
      print('Error deleting workout day: $e');
      rethrow;
    }
  }

  // Workout Exercise operations
  Future<void> saveWorkoutExercise(WorkoutExercise exercise) async {
    try {
      if (!Hive.isBoxOpen(_workoutExercisesBox)) {
        await Hive.openBox<WorkoutExercise>(_workoutExercisesBox);
      }
      final box = Hive.box<WorkoutExercise>(_workoutExercisesBox);
      await box.put(exercise.id, exercise);
      print('Workout exercise saved successfully');
    } catch (e) {
      print('Error saving workout exercise: $e');
      rethrow;
    }
  }

  Future<List<WorkoutExercise>> getWorkoutExercises() async {
    try {
      if (!Hive.isBoxOpen(_workoutExercisesBox)) {
        await Hive.openBox<WorkoutExercise>(_workoutExercisesBox);
      }
      final box = Hive.box<WorkoutExercise>(_workoutExercisesBox);
      return box.values.toList();
    } catch (e) {
      print('Error getting workout exercises: $e');
      return [];
    }
  }

  Future<WorkoutExercise?> getWorkoutExerciseById(int id) async {
    try {
      if (!Hive.isBoxOpen(_workoutExercisesBox)) {
        await Hive.openBox<WorkoutExercise>(_workoutExercisesBox);
      }
      final box = Hive.box<WorkoutExercise>(_workoutExercisesBox);
      return box.get(id);
    } catch (e) {
      print('Error getting workout exercise by id: $e');
      return null;
    }
  }

  Future<void> updateWorkoutExercise(int key, WorkoutExercise exercise) async {
    try {
      if (!Hive.isBoxOpen(_workoutExercisesBox)) {
        await Hive.openBox<WorkoutExercise>(_workoutExercisesBox);
      }
      final box = Hive.box<WorkoutExercise>(_workoutExercisesBox);
      await box.put(key, exercise);
    } catch (e) {
      print('Error updating workout exercise: $e');
      rethrow;
    }
  }

  Future<void> deleteWorkoutExercise(int key) async {
    try {
      if (!Hive.isBoxOpen(_workoutExercisesBox)) {
        await Hive.openBox<WorkoutExercise>(_workoutExercisesBox);
      }
      final box = Hive.box<WorkoutExercise>(_workoutExercisesBox);
      await box.delete(key);
    } catch (e) {
      print('Error deleting workout exercise: $e');
      rethrow;
    }
  }

  // Exercise AI Info operations
  Future<void> saveExerciseAiInfo(ExerciseAiInfo aiInfo) async {
    try {
      if (!Hive.isBoxOpen(_exerciseAiInfoBox)) {
        await Hive.openBox<ExerciseAiInfo>(_exerciseAiInfoBox);
      }
      final box = Hive.box<ExerciseAiInfo>(_exerciseAiInfoBox);
      await box.put(aiInfo.id, aiInfo);
      print('Exercise AI info saved successfully');
    } catch (e) {
      print('Error saving exercise AI info: $e');
      // Si hay error, limpiar la caja y reintentar
      try {
        if (Hive.isBoxOpen(_exerciseAiInfoBox)) {
          await Hive.box<ExerciseAiInfo>(_exerciseAiInfoBox).clear();
        }
        await Hive.deleteBoxFromDisk(_exerciseAiInfoBox);
        await Hive.openBox<ExerciseAiInfo>(_exerciseAiInfoBox);
        final box = Hive.box<ExerciseAiInfo>(_exerciseAiInfoBox);
        await box.put(aiInfo.id, aiInfo);
        print('Exercise AI info saved successfully after cleanup');
      } catch (e2) {
        print('Error after cleanup: $e2');
        rethrow;
      }
    }
  }

  Future<List<ExerciseAiInfo>> getAllExerciseAiInfo() async {
    try {
      if (!Hive.isBoxOpen(_exerciseAiInfoBox)) {
        await Hive.openBox<ExerciseAiInfo>(_exerciseAiInfoBox);
      }
      final box = Hive.box<ExerciseAiInfo>(_exerciseAiInfoBox);
      return box.values.toList();
    } catch (e) {
      print('Error getting all exercise AI info: $e');
      return [];
    }
  }

  Future<ExerciseAiInfo?> getExerciseAiInfoByExerciseId(int exerciseId) async {
    try {
      if (!Hive.isBoxOpen(_exerciseAiInfoBox)) {
        await Hive.openBox<ExerciseAiInfo>(_exerciseAiInfoBox);
      }
      final box = Hive.box<ExerciseAiInfo>(_exerciseAiInfoBox);
      try {
        return box.values.firstWhere(
          (aiInfo) => aiInfo.exerciseId == exerciseId,
        );
      } catch (e) {
        return null;
      }
    } catch (e) {
      print('Error getting exercise AI info by exercise id: $e');
      return null;
    }
  }

  Future<void> updateExerciseAiInfo(int key, ExerciseAiInfo aiInfo) async {
    try {
      if (!Hive.isBoxOpen(_exerciseAiInfoBox)) {
        await Hive.openBox<ExerciseAiInfo>(_exerciseAiInfoBox);
      }
      final box = Hive.box<ExerciseAiInfo>(_exerciseAiInfoBox);
      await box.put(key, aiInfo);
    } catch (e) {
      print('Error updating exercise AI info: $e');
      rethrow;
    }
  }

  Future<void> deleteExerciseAiInfo(int key) async {
    try {
      if (!Hive.isBoxOpen(_exerciseAiInfoBox)) {
        await Hive.openBox<ExerciseAiInfo>(_exerciseAiInfoBox);
      }
      final box = Hive.box<ExerciseAiInfo>(_exerciseAiInfoBox);
      await box.delete(key);
    } catch (e) {
      print('Error deleting exercise AI info: $e');
      rethrow;
    }
  }

  // Clear all data
  Future<void> clearAllData() async {
    await Hive.box<User>(_userBox).clear();
    await Hive.box<Meal>(_mealsBox).clear();
    await Hive.box<Exercise>(_exercisesBox).clear();
    await Hive.box<DailySummary>(_dailySummaryBox).clear();
    await Hive.box<WorkoutRoutine>(_workoutRoutinesBox).clear();
    await Hive.box<WorkoutDay>(_workoutDaysBox).clear();
    await Hive.box<WorkoutExercise>(_workoutExercisesBox).clear();
    await Hive.box<ExerciseAiInfo>(_exerciseAiInfoBox).clear();
  }
}