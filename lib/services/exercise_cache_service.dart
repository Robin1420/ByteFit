import 'package:hive/hive.dart';
import '../domain/entities/exercise_db_entity.dart';
import 'exercise_db_service.dart';
import 'image_cache_service.dart';

class ExerciseCacheService {
  static const String _boxName = 'exercises';
  static const String _lastUpdateKey = 'last_update';
  static const String _totalExercisesKey = 'total_exercises';
  
  late Box<ExerciseDbEntity> _exerciseBox;
  late Box<int> _metadataBox;
  final ExerciseDbService _exerciseDbService = ExerciseDbService();
  final ImageCacheService _imageCacheService = ImageCacheService();
  
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    _exerciseBox = await Hive.openBox<ExerciseDbEntity>(_boxName);
    _metadataBox = await Hive.openBox<int>('metadata');
    await _imageCacheService.init();
    _isInitialized = true;
  }

  Future<bool> hasExercises() async {
    await init();
    return _exerciseBox.isNotEmpty;
  }

  Future<int> getCachedExercisesCount() async {
    await init();
    return _exerciseBox.length;
  }

  Future<DateTime?> getLastUpdate() async {
    await init();
    final timestamp = _metadataBox.get(_lastUpdateKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  Future<void> setLastUpdate(DateTime dateTime) async {
    await init();
    await _metadataBox.put(_lastUpdateKey, dateTime.millisecondsSinceEpoch);
  }

  Future<void> setTotalExercises(int count) async {
    await init();
    await _metadataBox.put(_totalExercisesKey, count);
  }

  Future<int> getTotalExercises() async {
    await init();
    return _metadataBox.get(_totalExercisesKey, defaultValue: 0) ?? 0;
  }

  Future<void> saveExercises(List<ExerciseDbEntity> exercises) async {
    await init();
    
    // Limpiar ejercicios existentes
    await _exerciseBox.clear();
    
    // Guardar nuevos ejercicios
    for (final exercise in exercises) {
      await _exerciseBox.put(exercise.exerciseId, exercise);
    }
    
    // Guardar metadatos
    await setLastUpdate(DateTime.now());
    await setTotalExercises(exercises.length);
  }

  Future<List<ExerciseDbEntity>> getAllExercises() async {
    await init();
    return _exerciseBox.values.toList();
  }

  Future<List<ExerciseDbEntity>> searchExercises(String query) async {
    await init();
    final allExercises = _exerciseBox.values.toList();
    
    if (query.isEmpty) return allExercises;
    
    final lowercaseQuery = query.toLowerCase();
    return allExercises.where((exercise) {
      return exercise.name.toLowerCase().contains(lowercaseQuery) ||
             exercise.targetMuscles.any((muscle) => muscle.toLowerCase().contains(lowercaseQuery)) ||
             exercise.bodyParts.any((part) => part.toLowerCase().contains(lowercaseQuery)) ||
             exercise.equipments.any((equipment) => equipment.toLowerCase().contains(lowercaseQuery));
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

  Future<List<ExerciseDbEntity>> getExercisesByEquipment(String equipment) async {
    await init();
    return _exerciseBox.values.where((exercise) {
      return exercise.equipments.contains(equipment);
    }).toList();
  }

  Future<bool> needsUpdate() async {
    await init();
    
    print('🔍 Verificando si necesita actualización...');
    
    // Si no hay ejercicios, necesita actualización
    final hasExercisesData = await hasExercises();
    print('   - Tiene ejercicios: $hasExercisesData');
    
    if (!hasExercisesData) {
      print('   - No hay ejercicios, necesita descarga');
      return true;
    }
    
    // Verificar cuántos ejercicios hay
    final exerciseCount = await getCachedExercisesCount();
    print('   - Cantidad de ejercicios: $exerciseCount');
    
    // Si hay menos de 100 ejercicios, necesita más
    if (exerciseCount < 100) {
      print('   - Pocos ejercicios ($exerciseCount), necesita más');
      return true;
    }
    
    // Si han pasado más de 7 días desde la última actualización
    final lastUpdate = await getLastUpdate();
    if (lastUpdate == null) {
      print('   - No hay fecha de última actualización');
      return true;
    }
    
    final daysSinceUpdate = DateTime.now().difference(lastUpdate).inDays;
    print('   - Días desde última actualización: $daysSinceUpdate');
    
    final needsUpdateResult = daysSinceUpdate >= 7;
    print('   - Necesita actualización: $needsUpdateResult');
    
    return needsUpdateResult;
  }

  Future<void> downloadAllExercises({Function(int, int)? onProgress}) async {
    await init();
    
    print('🔄 Iniciando descarga de todos los ejercicios...');
    
    List<ExerciseDbEntity> allExercises = [];
    int totalPages = 1;
    int downloaded = 0;
    
    try {
      // Obtener la primera página para conocer el total de páginas
      final firstResponse = await _exerciseDbService.getExercises(limit: 50, offset: 0);
      totalPages = firstResponse.metadata.totalPages;
      
      // Limitar a las primeras 30 páginas para evitar rate limiting excesivo
      final maxPages = totalPages > 30 ? 30 : totalPages;
      print('📊 Descargando $maxPages páginas de $totalPages totales (50 ejercicios por página)');
      
      // Convertir ExerciseDbExercise a ExerciseDbEntity
      final convertedExercises = firstResponse.data.map((exercise) => _convertToEntity(exercise)).toList();
      allExercises.addAll(convertedExercises);
      downloaded += convertedExercises.length;
      
      // Descargar GIFs del primer bloque
      await _downloadGifsForBlock(convertedExercises);
      
      print('📊 Total de páginas: $totalPages');
      print('📊 Total de ejercicios: ${firstResponse.metadata.totalExercises}');
      
      // Descargar el resto de páginas con rate limiting
      for (int page = 2; page <= maxPages; page++) {
        final offset = (page - 1) * 50;
        
        // Intentar descargar con retry logic
        bool success = false;
        int retryCount = 0;
        const maxRetries = 3;
        
        while (!success && retryCount < maxRetries) {
          try {
            final response = await _exerciseDbService.getExercises(limit: 50, offset: offset);
            
            // Convertir ExerciseDbExercise a ExerciseDbEntity
            final convertedExercises = response.data.map((exercise) => _convertToEntity(exercise)).toList();
            allExercises.addAll(convertedExercises);
            downloaded += convertedExercises.length;
            
            // Descargar GIFs de este bloque inmediatamente
            await _downloadGifsForBlock(convertedExercises);
            
            success = true;
            
            // Reportar progreso
            if (onProgress != null) {
              onProgress(downloaded, firstResponse.metadata.totalExercises);
            }
            
            print('📥 Página $page/$totalPages - Ejercicios descargados: $downloaded');
            
          } catch (e) {
            retryCount++;
            print('⚠️ Error en página $page (intento $retryCount/$maxRetries): $e');
            
            if (retryCount < maxRetries) {
              // Esperar más tiempo entre reintentos (exponential backoff)
              final waitTime = Duration(seconds: retryCount * 5);
              print('⏳ Esperando ${waitTime.inSeconds} segundos antes del reintento...');
              await Future.delayed(waitTime);
            } else {
              print('❌ Falló después de $maxRetries intentos en página $page');
              throw e;
            }
          }
        }
        
        // Pausa entre páginas para respetar rate limits
        await Future.delayed(const Duration(seconds: 2));
      }
      
      // Guardar todos los ejercicios
      await saveExercises(allExercises);
      
      print('✅ Descarga completa: ${allExercises.length} ejercicios y sus GIFs descargados');
      
    } catch (e) {
      print('❌ Error durante la descarga: $e');
      rethrow;
    }
  }

  Future<String?> getLocalGifPath(String exerciseId) async {
    await init();
    return await _imageCacheService.getLocalGifPath(exerciseId);
  }

  Future<void> clearCache() async {
    await init();
    await _exerciseBox.clear();
    await _metadataBox.clear();
    await _imageCacheService.clearCache();
  }

  Future<void> close() async {
    if (_isInitialized) {
      await _exerciseBox.close();
      await _metadataBox.close();
      _isInitialized = false;
    }
  }

  // Método para convertir ExerciseDbExercise a ExerciseDbEntity
  ExerciseDbEntity _convertToEntity(ExerciseDbExercise exercise) {
    return ExerciseDbEntity(
      exerciseId: exercise.exerciseId,
      name: exercise.name,
      gifUrl: exercise.gifUrl,
      targetMuscles: exercise.targetMuscles,
      bodyParts: exercise.bodyParts,
      equipments: exercise.equipments,
      secondaryMuscles: exercise.secondaryMuscles,
      instructions: exercise.instructions,
    );
  }

  // Método para descargar GIFs de un bloque de ejercicios
  Future<void> _downloadGifsForBlock(List<ExerciseDbEntity> exercises) async {
    final gifUrls = exercises.where((e) => e.gifUrl.isNotEmpty).map((e) => e.gifUrl).toList();
    final exerciseIds = exercises.where((e) => e.gifUrl.isNotEmpty).map((e) => e.exerciseId).toList();
    
    if (gifUrls.isEmpty) return;
    
    print('📥 Descargando ${gifUrls.length} GIFs del bloque...');
    
    // Descargar todos los GIFs del bloque en paralelo
    final futures = <Future>[];
    for (int i = 0; i < gifUrls.length; i++) {
      futures.add(_imageCacheService.downloadGif(gifUrls[i], exerciseIds[i]));
    }
    
    // Esperar a que terminen todas las descargas
    await Future.wait(futures);
    
    print('✅ ${gifUrls.length} GIFs del bloque descargados');
  }
}
