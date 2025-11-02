import 'exercise_db_entity.dart';

class ExerciseDbResponse {
  final bool success;
  final ExerciseDbMetadata metadata;
  final List<ExerciseDbEntity> data;

  ExerciseDbResponse({
    required this.success,
    required this.metadata,
    required this.data,
  });

  factory ExerciseDbResponse.fromJson(Map<String, dynamic> json) {
    return ExerciseDbResponse(
      success: json['success'] ?? false,
      metadata: ExerciseDbMetadata.fromJson(json['metadata'] ?? {}),
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => ExerciseDbEntity.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'metadata': metadata.toJson(),
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
}

class ExerciseDbMetadata {
  final int totalPages;
  final int totalExercises;
  final int currentPage;
  final String? previousPage;
  final String? nextPage;

  ExerciseDbMetadata({
    required this.totalPages,
    required this.totalExercises,
    required this.currentPage,
    this.previousPage,
    this.nextPage,
  });

  factory ExerciseDbMetadata.fromJson(Map<String, dynamic> json) {
    return ExerciseDbMetadata(
      totalPages: json['totalPages'] ?? 0,
      totalExercises: json['totalExercises'] ?? 0,
      currentPage: json['currentPage'] ?? 0,
      previousPage: json['previousPage'],
      nextPage: json['nextPage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPages': totalPages,
      'totalExercises': totalExercises,
      'currentPage': currentPage,
      'previousPage': previousPage,
      'nextPage': nextPage,
    };
  }
}
