import 'package:hive/hive.dart';

part 'meal.g.dart';

@HiveType(typeId: 1)
class Meal {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final DateTime fecha;

  @HiveField(2)
  final String nombre;

  @HiveField(3)
  final double calorias;

  @HiveField(4)
  final String imagenPath;

  Meal({
    required this.id,
    required this.fecha,
    required this.nombre,
    required this.calorias,
    required this.imagenPath,
  });

  Meal copyWith({
    int? id,
    DateTime? fecha,
    String? nombre,
    double? calorias,
    String? imagenPath,
  }) {
    return Meal(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      nombre: nombre ?? this.nombre,
      calorias: calorias ?? this.calorias,
      imagenPath: imagenPath ?? this.imagenPath,
    );
  }

  // Método para convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String(),
      'nombre': nombre,
      'calorias': calorias,
      'imagenPath': imagenPath,
    };
  }
}
