class ExerciseDbEntity {
  final String exerciseId;
  final String name;
  final String gifUrl;
  final List<String> targetMuscles;
  final List<String> bodyParts;
  final List<String> equipments;
  final List<String> secondaryMuscles;
  final List<String> instructions;

  ExerciseDbEntity({
    required this.exerciseId,
    required this.name,
    required this.gifUrl,
    required this.targetMuscles,
    required this.bodyParts,
    required this.equipments,
    required this.secondaryMuscles,
    required this.instructions,
  });

  factory ExerciseDbEntity.fromJson(Map<String, dynamic> json) {
    return ExerciseDbEntity(
      exerciseId: json['exerciseId'] ?? '',
      name: json['name'] ?? '',
      gifUrl: json['gifUrl'] ?? '',
      targetMuscles: List<String>.from(json['targetMuscles'] ?? []),
      bodyParts: List<String>.from(json['bodyParts'] ?? []),
      equipments: List<String>.from(json['equipments'] ?? []),
      secondaryMuscles: List<String>.from(json['secondaryMuscles'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'name': name,
      'gifUrl': gifUrl,
      'targetMuscles': targetMuscles,
      'bodyParts': bodyParts,
      'equipments': equipments,
      'secondaryMuscles': secondaryMuscles,
      'instructions': instructions,
    };
  }

  ExerciseDbEntity copyWith({
    String? exerciseId,
    String? name,
    String? gifUrl,
    List<String>? targetMuscles,
    List<String>? bodyParts,
    List<String>? equipments,
    List<String>? secondaryMuscles,
    List<String>? instructions,
  }) {
    return ExerciseDbEntity(
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      gifUrl: gifUrl ?? this.gifUrl,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      bodyParts: bodyParts ?? this.bodyParts,
      equipments: equipments ?? this.equipments,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      instructions: instructions ?? this.instructions,
    );
  }
}
