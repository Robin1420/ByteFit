import 'package:hive/hive.dart';

part 'exercise.g.dart';

@HiveType(typeId: 2)
class Exercise {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final DateTime fecha;

  @HiveField(2)
  final String tipo;

  @HiveField(3)
  final double caloriasQuemadas;

  @HiveField(4)
  final String imagenPath;

  Exercise({
    required this.id,
    required this.fecha,
    required this.tipo,
    required this.caloriasQuemadas,
    required this.imagenPath,
  });

  Exercise copyWith({
    int? id,
    DateTime? fecha,
    String? tipo,
    double? caloriasQuemadas,
    String? imagenPath,
  }) {
    return Exercise(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      tipo: tipo ?? this.tipo,
      caloriasQuemadas: caloriasQuemadas ?? this.caloriasQuemadas,
      imagenPath: imagenPath ?? this.imagenPath,
    );
  }

  // Método para convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String(),
      'tipo': tipo,
      'caloriasQuemadas': caloriasQuemadas,
      'imagenPath': imagenPath,
    };
  }
}
