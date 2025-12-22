import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/datasources/local_datasource.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../data/repositories/meal_repository.dart';
import '../providers/app_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final MealRepository _mealRepo;
  late final ExerciseRepository _exerciseRepo;

  double _todayConsumed = 0;
  double _todayBurned = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _mealRepo = MealRepository(LocalDataSource());
    _exerciseRepo = ExerciseRepository(LocalDataSource());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _todayConsumed = await _mealRepo.getTotalCaloriesByDate(today);
    _todayBurned = await _exerciseRepo.getTotalBurnedCaloriesByDate(today);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: scheme.primary,
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHeader(scheme),
                    const SizedBox(height: 16),
                    _buildProgress(scheme),
                    const SizedBox(height: 16),
                    _buildActivity(scheme),
                    const SizedBox(height: 16),
                    _buildStatus(scheme),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
    final card = scheme.surface;
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        final user = app.currentUser;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: scheme.primary.withOpacity(0.1),
                child:
                    user?.imagenPerfil != null && user!.imagenPerfil!.isNotEmpty
                        ? ClipOval(
                            child: Image.file(File(user.imagenPerfil!),
                                fit: BoxFit.cover))
                        : Icon(Icons.person, color: scheme.onSurface),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bienvenido de vuelta',
                        style: TextStyle(
                            color: scheme.onSurface.withOpacity(0.6),
                            fontSize: 12)),
                    Text(
                      user?.nombre ?? 'Atleta',
                      style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadData,
                icon: Icon(Icons.refresh,
                    color: scheme.onSurface.withOpacity(0.7)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgress(ColorScheme scheme) {
    final card = scheme.surface;
    const accent = Color(0xFF2ED8A7);
    final percent = (_todayBurned / 500).clamp(0.0, 1.0) * 100;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Progreso de entrenamiento',
                    style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  '${_todayBurned.toStringAsFixed(0)} kcal quemadas hoy',
                  style: TextStyle(
                      color: scheme.onSurface.withOpacity(0.6), fontSize: 12),
                ),
              ],
            ),
          ),
          _progressRing(percent, accent, scheme),
        ],
      ),
    );
  }

  Widget _buildActivity(ColorScheme scheme) {
    final card = scheme.surface;
    const accent = Color(0xFF2ED8A7);
    final items = [
      {
        'name': 'CalorÃƒÂ­as',
        'desc': 'Consumidas hoy',
        'value': '${_todayConsumed.toStringAsFixed(0)} kcal'
      },
      {
        'name': 'Quemadas',
        'desc': 'Ejercicio',
        'value': '${_todayBurned.toStringAsFixed(0)} kcal'
      },
      {
        'name': 'Balance',
        'desc': 'Diferencia',
        'value': '${(_todayConsumed - _todayBurned).toStringAsFixed(0)} kcal'
      },
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Actividad de hoy',
                    style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
              Text('Ver detalles',
                  style: TextStyle(
                      color: scheme.onSurface.withOpacity(0.6), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((it) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outline.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it['name']!,
                            style: TextStyle(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w700)),
                        Text(it['desc']!,
                            style: TextStyle(
                                color: scheme.onSurface.withOpacity(0.6),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    it['value']!,
                    style: TextStyle(
                        color: scheme.onSurface, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatus(ColorScheme scheme) {
    final card = scheme.surface;
    const accent = Color(0xFF2ED8A7);
    const accent2 = Color(0xFF0080F5);
    final balance = _todayConsumed - _todayBurned;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Estado general',
                  style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
            Text('Ver mÃƒÂ¡s Ã¢â€ â€™',
                style: TextStyle(
                    color: scheme.onSurface.withOpacity(0.6), fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
        _statusCard(
          card,
          scheme,
          icon: Icons.local_fire_department,
          title: 'CalorÃƒÂ­as consumidas',
          value: '${_todayConsumed.toStringAsFixed(0)} kcal',
          change: '+2.8%',
          progress: (_todayConsumed / 2000).clamp(0.0, 1.0) * 100,
          color: accent2,
        ),
        const SizedBox(height: 10),
        _statusCard(
          card,
          scheme,
          icon: Icons.monitor_weight,
          title: 'Balance calÃƒÂ³rico',
          value: '${balance.toStringAsFixed(0)} kcal',
          change: balance >= 0 ? '+2.0%' : '-2.0%',
          progress: (balance.abs() / 2000).clamp(0.0, 1.0) * 100,
          color: accent,
        ),
      ],
    );
  }

  Widget _statusCard(Color card, ColorScheme scheme,
      {required IconData icon,
      required String title,
      required String value,
      required String change,
      required double progress,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.primary.withOpacity(0.08),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: scheme.onSurface.withOpacity(0.7),
                        fontSize: 12)),
                Text(value,
                    style: TextStyle(
                        color: scheme.onSurface, fontWeight: FontWeight.w700)),
                Text(change, style: TextStyle(color: color, fontSize: 12)),
              ],
            ),
          ),
          _progressRing(progress, color, scheme),
        ],
      ),
    );
  }

  Widget _progressRing(double percent, Color color, ColorScheme scheme) {
    final clamped = percent.clamp(0, 100);
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: clamped / 100,
            strokeWidth: 6,
            backgroundColor: scheme.onSurface.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            '${clamped.toStringAsFixed(0)}%',
            style: TextStyle(
                color: scheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
