import 'package:hive/hive.dart';
import 'meal.dart';
import 'exercise.dart';

part 'daily_summary.g.dart';

@HiveType(typeId: 6)
class DailySummary {
  @HiveField(0)
  final int id;
  
  @HiveField(1)
  final DateTime fecha;
  
  @HiveField(2)
  final double totalConsumido;
  
  @HiveField(3)
  final double totalQuemado;
  
  @HiveField(4)
  final double balance;

  DailySummary({
    required this.id,
    required this.fecha,
    required this.totalConsumido,
    required this.totalQuemado,
    required this.balance,
  });

  // Método para calcular balance automáticamente
  static DailySummary calcularResumenDiario({
    required int id,
    required DateTime fecha,
    required List<Meal> comidas,
    required List<Exercise> ejercicios,
  }) {
    final totalConsumido = comidas.fold<double>(0, (sum, meal) => sum + meal.calorias);
    final totalQuemado = ejercicios.fold<double>(0, (sum, exercise) => sum + exercise.caloriasQuemadas);
    final balance = totalConsumido - totalQuemado;

    return DailySummary(
      id: id,
      fecha: fecha,
      totalConsumido: totalConsumido,
      totalQuemado: totalQuemado,
      balance: balance,
    );
  }

  DailySummary copyWith({
    int? id,
    DateTime? fecha,
    double? totalConsumido,
    double? totalQuemado,
    double? balance,
  }) {
    return DailySummary(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      totalConsumido: totalConsumido ?? this.totalConsumido,
      totalQuemado: totalQuemado ?? this.totalQuemado,
      balance: balance ?? this.balance,
    );
  }
}
