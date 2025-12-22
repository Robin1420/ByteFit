import 'package:hive/hive.dart';

part 'workout_exercise.g.dart';

@HiveType(typeId: 5)
class WorkoutExercise {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int dayId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final int sets;

  @HiveField(4)
  final String reps;

  @HiveField(5)
  final double weight;

  @HiveField(6)
  final int restTimeSeconds;

  @HiveField(7)
  final int order;

  WorkoutExercise({
    required this.id,
    required this.dayId,
    required this.name,
    this.sets = 3,
    this.reps = '8-12',
    this.weight = 0.0,
    this.restTimeSeconds = 60,
    required this.order,
  });

  WorkoutExercise copyWith({
    int? id,
    int? dayId,
    String? name,
    int? sets,
    String? reps,
    double? weight,
    int? restTimeSeconds,
    int? order,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      dayId: dayId ?? this.dayId,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      restTimeSeconds: restTimeSeconds ?? this.restTimeSeconds,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayId': dayId,
      'name': name,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'restTimeSeconds': restTimeSeconds,
      'order': order,
    };
  }
}
