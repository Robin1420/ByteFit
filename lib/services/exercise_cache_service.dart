import 'package:hive/hive.dart';
import '../domain/entities/exercise_db_entity.dart';

/// Cache local para ejercicios precargados desde assets/Hive.
/// No realiza descargas ni llamadas de red.
class ExerciseCacheService {
  static const String _boxName = 'exercises';
  late Box<ExerciseDbEntity> _exerciseBox;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _exerciseBox = await Hive.openBox<ExerciseDbEntity>(_boxName);
    _isInitialized = true;
  }

  Future<bool> hasExercises() async {
    await init();
    return _exerciseBox.isNotEmpty;
  }

  /// Versión síncrona para lecturas rápidas tras init.
  List<ExerciseDbEntity> getAllExercisesSync() {
    if (!_isInitialized) {
      throw StateError('ExerciseCacheService no inicializado');
    }
    return _exerciseBox.values.toList();
  }

  Future<List<ExerciseDbEntity>> getAllExercises() async {
    await init();
    return _exerciseBox.values.toList();
  }

  Future<List<ExerciseDbEntity>> searchExercises(String query) async {
    await init();
    final all = _exerciseBox.values.toList();
    if (query.isEmpty) return all;
    final q = query.toLowerCase();
    return all.where((exercise) {
      return exercise.name.toLowerCase().contains(q) ||
          exercise.targetMuscles.any((m) => m.toLowerCase().contains(q)) ||
          exercise.bodyParts.any((p) => p.toLowerCase().contains(q)) ||
          exercise.equipments.any((e) => e.toLowerCase().contains(q));
    }).toList();
  }

  Future<ExerciseDbEntity?> getExerciseById(String exerciseId) async {
    await init();
    return _exerciseBox.get(exerciseId);
  }

  Future<List<ExerciseDbEntity>> getExercisesByMuscle(String muscle) async {
    await init();
    return _exerciseBox.values.where((exercise) {
      return exercise.targetMuscles.contains(muscle) ||
          exercise.secondaryMuscles.contains(muscle);
    }).toList();
  }

  Future<List<ExerciseDbEntity>> getExercisesByBodyPart(String bodyPart) async {
    await init();
    return _exerciseBox.values.where((exercise) {
      return exercise.bodyParts.contains(bodyPart);
    }).toList();
  }

  Future<List<ExerciseDbEntity>> getExercisesByEquipment(
      String equipment) async {
    await init();
    return _exerciseBox.values.where((exercise) {
      return exercise.equipments.contains(equipment);
    }).toList();
  }
}
