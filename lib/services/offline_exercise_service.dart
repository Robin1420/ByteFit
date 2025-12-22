import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../domain/entities/exercise_db_entity.dart';

/// Servicio para cargar ejercicios desde assets locales (100% offline)
class OfflineExerciseService {
  static const String _boxName = 'exercises';
  static const String _metadataBox = 'metadata';
  static const String _exercisesAssetPath = 'assets/data/exercises_es.json';

  /// Inicializa la base de datos offline cargando desde assets
  Future<void> initializeFromAssets() async {
    print('📦 Inicializando base de datos offline desde assets...');

    try {
      // Verificar si ya está inicializado
      final metadataBox = await Hive.openBox<dynamic>(_metadataBox);
      final isInitialized =
          metadataBox.get('offline_initialized', defaultValue: false);

      if (isInitialized == true) {
        print('✅ Base de datos ya inicializada, omitiendo carga');
        return;
      }

      // Cargar JSON desde assets
      print('📄 Cargando exercises_es.json desde assets...');
      final jsonString = await rootBundle.loadString(_exercisesAssetPath);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final exercises = (data['exercises'] as List)
          .map((e) => _exerciseFromJson(e as Map<String, dynamic>))
          .toList();

      print('✅ ${exercises.length} ejercicios cargados del JSON');

      // Guardar en Hive
      print('💾 Guardando en base de datos local (Hive)...');
      final exerciseBox = await Hive.openBox<ExerciseDbEntity>(_boxName);

      // Limpiar ejercicios anteriores
      await exerciseBox.clear();

      // Guardar todos los ejercicios
      for (final exercise in exercises) {
        await exerciseBox.put(exercise.exerciseId, exercise);
      }

      // Marcar como inicializado
      await metadataBox.put('offline_initialized', true);
      await metadataBox.put('total_exercises', exercises.length);
      await metadataBox.put(
          'last_update', DateTime.now().millisecondsSinceEpoch);
      await metadataBox.put('version', data['version'] ?? '1.0');

      print(
          '✅ Base de datos offline inicializada con ${exercises.length} ejercicios');
      print('🎉 App 100% lista para funcionar offline!');
    } catch (e) {
      print('❌ Error inicializando base de datos offline: $e');
      rethrow;
    }
  }

  /// Convierte JSON a ExerciseDbEntity
  ExerciseDbEntity _exerciseFromJson(Map<String, dynamic> json) {
    return ExerciseDbEntity(
      exerciseId: json['exerciseId'] as String,
      name: json['name'] as String,
      gifUrl: json['gifUrl'] as String,
      targetMuscles: (json['targetMuscles'] as List).cast<String>(),
      bodyParts: (json['bodyParts'] as List).cast<String>(),
      equipments: (json['equipments'] as List).cast<String>(),
      secondaryMuscles: (json['secondaryMuscles'] as List).cast<String>(),
      instructions: (json['instructions'] as List).cast<String>(),
    );
  }

  /// Verifica si la base de datos offline está disponible
  Future<bool> isOfflineDataAvailable() async {
    try {
      final metadataBox = await Hive.openBox<dynamic>(_metadataBox);
      return metadataBox.get('offline_initialized', defaultValue: false)
          as bool;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el GIF local si está disponible
  String getLocalGifPath(String exerciseId) {
    // Los GIFs están en assets/gifs/{exerciseId}.gif
    return 'assets/gifs/$exerciseId.gif';
  }

  /// Verifica si un GIF local existe
  Future<bool> hasLocalGif(String exerciseId) async {
    try {
      await rootBundle.load(getLocalGifPath(exerciseId));
      return true;
    } catch (e) {
      return false;
    }
  }
}
