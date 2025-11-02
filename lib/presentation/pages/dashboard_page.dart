import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../data/repositories/meal_repository.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../data/datasources/local_datasource.dart';
import '../providers/app_provider.dart';
import 'edit_profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final MealRepository _mealRepository;
  late final ExerciseRepository _exerciseRepository;
  
  List<Map<String, dynamic>> _weeklyData = [];
  double _todayConsumed = 0;
  double _todayBurned = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _mealRepository = MealRepository(LocalDataSource());
    _exerciseRepository = ExerciseRepository(LocalDataSource());
    _loadDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar datos cuando cambie el usuario
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Obtener datos de la última semana (7 días completos)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: today.weekday - 1)); // Lunes de esta semana
      
      _weeklyData = [];
      for (int i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        final consumed = await _mealRepository.getTotalCaloriesByDate(date);
        final burned = await _exerciseRepository.getTotalBurnedCaloriesByDate(date);
        
        _weeklyData.add({
          'date': date,
          'consumed': consumed,
          'burned': burned,
          'balance': consumed - burned,
        });
      }

      // Datos de hoy
      _todayConsumed = await _mealRepository.getTotalCaloriesByDate(today);
      _todayBurned = await _exerciseRepository.getTotalBurnedCaloriesByDate(today);
      
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con título y botón de refresh
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'NutriSync Dashboard',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                          });
                          _loadDashboardData();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Información personal del usuario
                  _buildUserInfo(),
                  const SizedBox(height: 20),
                  
                  // Resumen de hoy
                  _buildTodaySummary(),
                  const SizedBox(height: 20),
                  
                  // Gráfico semanal
                  _buildWeeklyChart(),
                  const SizedBox(height: 20),
                  
                  // Lista de días
                  _buildWeeklyList(),
                ],
              ),
            ),
    );
  }

  Widget _buildTodaySummary() {
    final balance = _todayConsumed - _todayBurned;
    final isPositive = balance > 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de Hoy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Consumido',
                    _todayConsumed.toStringAsFixed(0),
                    'kcal',
                    Colors.orange,
                    Icons.restaurant,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    'Quemado',
                    _todayBurned.toStringAsFixed(0),
                    'kcal',
                    Colors.green,
                    Icons.fitness_center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPositive ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isPositive ? Colors.red.shade200 : Colors.green.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: isPositive ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Balance: ${balance.toStringAsFixed(0)} kcal',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, String unit, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            '$value $unit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    if (_weeklyData.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Balance Semanal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text('No hay datos para mostrar'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Balance Semanal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < _weeklyData.length) {
                            final date = _weeklyData[value.toInt()]['date'] as DateTime;
                            const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
                            return Text(
                              days[date.weekday - 1],
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _weeklyData.asMap().entries.map((entry) {
                        final balance = entry.value['balance'] as double;
                        return FlSpot(entry.key.toDouble(), balance);
                      }).toList(),
                      isCurved: true,
                      color: const Color(0xFF0080F5),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF0080F5).withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalle Semanal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._weeklyData.map((day) {
              final date = day['date'] as DateTime;
              final consumed = day['consumed'] as double;
              final burned = day['burned'] as double;
              final balance = day['balance'] as double;
              final isToday = date.day == DateTime.now().day;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isToday ? Colors.blue.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isToday ? Colors.blue.shade200 : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        _getDayName(date),
                        style: TextStyle(
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday ? Colors.blue : Colors.black,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${consumed.toStringAsFixed(0)} kcal',
                        style: const TextStyle(fontSize: 12, color: Colors.orange),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${burned.toStringAsFixed(0)} kcal',
                        style: const TextStyle(fontSize: 12, color: Colors.green),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${balance.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: balance > 0 ? Colors.red : Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _getDayName(DateTime date) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[date.weekday - 1];
  }

  Widget _buildUserInfo() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final user = appProvider.currentUser;
        
        if (user == null) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar pequeño con botón de editar
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EditProfilePage()),
                        );
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0080F5).withOpacity(0.1),
                          border: Border.all(
                            color: const Color(0xFF0080F5),
                            width: 2,
                          ),
                        ),
                        child: user.imagenPerfil != null && user.imagenPerfil!.isNotEmpty
                            ? ClipOval(
                                child: Image.file(
                                  File(user.imagenPerfil!),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person,
                                      color: Color(0xFF0080F5),
                                      size: 24,
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                color: Color(0xFF0080F5),
                                size: 24,
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Hola, ${user.nombre}!',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Meta calórica: ${user.metaCalorica.toStringAsFixed(0)} kcal/día',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Estadísticas personales
                Row(
                  children: [
                    Expanded(
                      child: _buildPersonalStatCard(
                        'Edad',
                        '${user.edad} años',
                        Icons.cake,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPersonalStatCard(
                        'Peso',
                        '${user.peso} kg',
                        Icons.monitor_weight,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPersonalStatCard(
                        'Altura',
                        '${user.altura} cm',
                        Icons.height,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildPersonalStatCard(
                        'IMC',
                        _calculateBMI(user.peso, user.altura).toStringAsFixed(1),
                        Icons.analytics,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPersonalStatCard(
                        'Metabolismo',
                        user.calcularMetabolismoBasal().toStringAsFixed(0),
                        Icons.local_fire_department,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPersonalStatCard(
                        'Género',
                        user.sexo == 'M' ? 'M' : 'F',
                        Icons.person,
                        Colors.teal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonalStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateBMI(double weight, double height) {
    // BMI = weight (kg) / height (m)²
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }
}
