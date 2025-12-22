import 'package:hive/hive.dart';

part 'exercise_ai_info.g.dart';

@HiveType(typeId: 7)
class ExerciseAiInfo {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int exerciseId; // Foreign key to WorkoutExercise

  @HiveField(2)
  final String description; // Descripción del ejercicio

  @HiveField(3)
  final String execution; // Cómo ejecutar el ejercicio

  @HiveField(4)
  final List<String> tips; // Tips para mejorar

  @HiveField(5)
  final List<String> images; // URLs o paths de imágenes

  @HiveField(6)
  final String muscleGroups; // Grupos musculares trabajados

  @HiveField(7)
  final String difficulty; // Nivel de dificultad

  @HiveField(8)
  final DateTime lastUpdated; // Cuándo se actualizó la información

  @HiveField(9)
  final bool isOfflineAvailable; // Si está disponible sin internet

  @HiveField(10)
  final String videoUrl; // URL del video de YouTube

  ExerciseAiInfo({
    required this.id,
    required this.exerciseId,
    required this.description,
    required this.execution,
    required this.tips,
    required this.images,
    required this.muscleGroups,
    required this.difficulty,
    required this.lastUpdated,
    this.isOfflineAvailable = true,
    this.videoUrl = '',
  });

  ExerciseAiInfo copyWith({
    int? id,
    int? exerciseId,
    String? description,
    String? execution,
    List<String>? tips,
    List<String>? images,
    String? muscleGroups,
    String? difficulty,
    DateTime? lastUpdated,
    bool? isOfflineAvailable,
    String? videoUrl,
  }) {
    return ExerciseAiInfo(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      description: description ?? this.description,
      execution: execution ?? this.execution,
      tips: tips ?? this.tips,
      images: images ?? this.images,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      difficulty: difficulty ?? this.difficulty,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isOfflineAvailable: isOfflineAvailable ?? this.isOfflineAvailable,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'description': description,
      'execution': execution,
      'tips': tips,
      'images': images,
      'muscleGroups': muscleGroups,
      'difficulty': difficulty,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isOfflineAvailable': isOfflineAvailable,
      'videoUrl': videoUrl,
    };
  }

  factory ExerciseAiInfo.fromJson(Map<String, dynamic> json) {
    return ExerciseAiInfo(
      id: json['id'],
      exerciseId: json['exerciseId'],
      description: json['description'],
      execution: json['execution'],
      tips: List<String>.from(json['tips']),
      images: List<String>.from(json['images']),
      muscleGroups: json['muscleGroups'],
      difficulty: json['difficulty'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
      isOfflineAvailable: json['isOfflineAvailable'] ?? true,
      videoUrl: json['videoUrl'] ?? '',
    );
  }
}
