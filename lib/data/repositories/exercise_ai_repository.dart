import '../../domain/entities/exercise_ai_info.dart';
import '../datasources/local_datasource.dart';

class ExerciseAiRepository {
  final LocalDataSource _dataSource;

  ExerciseAiRepository(this._dataSource);

  Future<void> saveAiInfo(ExerciseAiInfo aiInfo) async {
    await _dataSource.saveExerciseAiInfo(aiInfo);
  }

  Future<ExerciseAiInfo?> getAiInfoByExerciseId(int exerciseId) async {
    return await _dataSource.getExerciseAiInfoByExerciseId(exerciseId);
  }

  Future<List<ExerciseAiInfo>> getAllAiInfo() async {
    return await _dataSource.getAllExerciseAiInfo();
  }

  Future<void> updateAiInfo(int key, ExerciseAiInfo aiInfo) async {
    await _dataSource.updateExerciseAiInfo(key, aiInfo);
  }

  Future<void> deleteAiInfo(int key) async {
    await _dataSource.deleteExerciseAiInfo(key);
  }

  Future<bool> hasOfflineInfo(int exerciseId) async {
    final aiInfo = await getAiInfoByExerciseId(exerciseId);
    return aiInfo != null && aiInfo.isOfflineAvailable;
  }
}
