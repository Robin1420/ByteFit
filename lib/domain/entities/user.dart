import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String nombre;

  @HiveField(2)
  final int edad;

  @HiveField(3)
  final double peso;

  @HiveField(4)
  final double altura;

  @HiveField(5)
  final String sexo;

  @HiveField(6)
  final double metaCalorica;

  @HiveField(7)
  final String? imagenPerfil;

  User({
    required this.id,
    required this.nombre,
    required this.edad,
    required this.peso,
    required this.altura,
    required this.sexo,
    required this.metaCalorica,
    this.imagenPerfil,
  });

  // Método para calcular calorías basales (Harris-Benedict)
  double calcularMetabolismoBasal() {
    if (sexo.toLowerCase() == 'm') {
      // Fórmula para hombres
      return 66.5 + (13.75 * peso) + (5.003 * altura) - (6.75 * edad);
    } else {
      // Fórmula para mujeres
      return 655.1 + (9.563 * peso) + (1.850 * altura) - (4.676 * edad);
    }
  }

  // Método para calcular meta calórica según objetivo
  double calcularMetaCalorica(String objetivo) {
    final metabolismoBasal = calcularMetabolismoBasal();

    switch (objetivo.toLowerCase()) {
      case 'bajar':
        return metabolismoBasal * 0.8; // Déficit del 20%
      case 'subir':
        return metabolismoBasal * 1.2; // Superávit del 20%
      case 'mantener':
      default:
        return metabolismoBasal;
    }
  }

  User copyWith({
    int? id,
    String? nombre,
    int? edad,
    double? peso,
    double? altura,
    String? sexo,
    double? metaCalorica,
    String? imagenPerfil,
  }) {
    return User(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      edad: edad ?? this.edad,
      peso: peso ?? this.peso,
      altura: altura ?? this.altura,
      sexo: sexo ?? this.sexo,
      metaCalorica: metaCalorica ?? this.metaCalorica,
      imagenPerfil: imagenPerfil ?? this.imagenPerfil,
    );
  }

  // Método para convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'edad': edad,
      'peso': peso,
      'altura': altura,
      'sexo': sexo,
      'metaCalorica': metaCalorica,
      'imagenPerfil': imagenPerfil,
    };
  }
}
