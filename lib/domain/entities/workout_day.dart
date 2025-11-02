import 'package:hive/hive.dart';

part 'workout_day.g.dart';

@HiveType(typeId: 4)
class WorkoutDay {
  @HiveField(0)
  final int id;
  
  @HiveField(1)
  final int routineId;
  
  @HiveField(2)
  final String name;
  
  @HiveField(3)
  final int order;

  WorkoutDay({
    required this.id,
    required this.routineId,
    required this.name,
    required this.order,
  });

  WorkoutDay copyWith({
    int? id,
    int? routineId,
    String? name,
    int? order,
  }) {
    return WorkoutDay(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      name: name ?? this.name,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routineId': routineId,
      'name': name,
      'order': order,
    };
  }
}
