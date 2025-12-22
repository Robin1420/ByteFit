import 'package:hive/hive.dart';

part 'workout_routine.g.dart';

@HiveType(typeId: 3)
class WorkoutRoutine {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final bool isActive;

  WorkoutRoutine({
    required this.id,
    required this.name,
    this.description = '',
    this.isActive = true,
  });

  WorkoutRoutine copyWith({
    int? id,
    String? name,
    String? description,
    bool? isActive,
  }) {
    return WorkoutRoutine(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isActive': isActive,
    };
  }
}
