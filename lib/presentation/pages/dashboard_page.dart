import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  int _stepsToday = 0;
  int? _baseSteps;
  StreamSubscription<StepCount>? _stepSubscription;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _mealRepo = MealRepository(LocalDataSource());
    _exerciseRepo = ExerciseRepository(LocalDataSource());
    _loadData();
    _initPedometer();
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

  Future<void> _initPedometer() async {
    final status = await Permission.activityRecognition.request();
    if (!status.isGranted) {
      if (mounted) {
        setState(() => _stepsToday = 0);
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final todayKey = _todayKey();
    final storedDate = prefs.getString('pedometer_date');
    if (storedDate != todayKey) {
      await prefs.setString('pedometer_date', todayKey);
      await prefs.remove('pedometer_base');
      await prefs.remove('pedometer_steps');
      _baseSteps = null;
      _stepsToday = 0;
    } else {
      _baseSteps = prefs.getInt('pedometer_base');
      _stepsToday = prefs.getInt('pedometer_steps') ?? 0;
    }

    _stepSubscription?.cancel();
    _stepSubscription = Pedometer.stepCountStream.listen((event) {
      _handleStep(event.steps);
    }, onError: (e) {
      debugPrint('Pedometer error: $e');
    });
  }

  Future<void> _handleStep(int absoluteSteps) async {
    final prefs = await SharedPreferences.getInstance();
    if (_baseSteps == null) {
      _baseSteps = absoluteSteps;
      await prefs.setInt('pedometer_base', _baseSteps!);
      await prefs.setString('pedometer_date', _todayKey());
    }
    final todaySteps =
        (absoluteSteps - (_baseSteps ?? absoluteSteps)).clamp(0, 200000);
    if (!mounted) return;
    setState(() => _stepsToday = todaySteps);
    await prefs.setInt('pedometer_steps', todaySteps);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  @override
  void dispose() {
    _stepSubscription?.cancel();
    super.dispose();
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
                    _buildStepsCard(scheme),
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
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        final user = app.currentUser;
        final base = scheme.primary;
        final onBase =
            scheme.brightness == Brightness.dark ? scheme.onPrimary : Colors.white;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                base.withOpacity(0.92),
                base.withOpacity(0.78),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: base.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withOpacity(0.18),
                    child: user?.imagenPerfil != null &&
                            user!.imagenPerfil!.isNotEmpty
                        ? ClipOval(
                            child: Image.file(File(user.imagenPerfil!),
                                fit: BoxFit.cover, width: 48, height: 48),
                          )
                        : Icon(Icons.person, color: onBase),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bienvenido de vuelta',
                            style: TextStyle(
                                color: onBase.withOpacity(0.75), fontSize: 12)),
                        Text(
                          user?.nombre ?? 'Atleta',
                          style: TextStyle(
                              color: onBase,
                              fontSize: 19,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _infoChip(scheme, Icons.monitor_weight,
                      '${user?.peso.toStringAsFixed(1) ?? '0'} kg',
                      light: true),
                  _infoChip(scheme, Icons.height,
                      '${user?.altura.toStringAsFixed(0) ?? '0'} cm',
                      light: true),
                  _infoChip(
                      scheme,
                      Icons.local_fire_department,
                      user?.metaCalorica != null
                          ? '${user!.metaCalorica.toStringAsFixed(0)} kcal'
                          : 'Meta N/D',
                      light: true),
                  if (user?.edad != null)
                    _infoChip(scheme, Icons.cake,
                        '${user!.edad.toString()} años',
                        light: true),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepsCard(ColorScheme scheme) {
    final double estimatedKm = (_stepsToday * 0.00078);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            scheme.primary.withOpacity(0.9),
            scheme.primary.withOpacity(0.65),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: const Icon(Icons.directions_walk, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pasos de hoy',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _stepsToday.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'pasos',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Aprox. ${estimatedKm.toStringAsFixed(2)} km',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.track_changes, color: Colors.white70),
        ],
      ),
    );
  }

  Widget _infoChip(ColorScheme scheme, IconData icon, String text,
      {bool light = false}) {
    final bool useLight = light;
    final Color bg = useLight
        ? Colors.white.withOpacity(0.22)
        : scheme.primary.withOpacity(0.08);
    final Color iconBg = useLight
        ? Colors.white.withOpacity(0.28)
        : scheme.primary.withOpacity(0.14);
    final Color fg = useLight ? Colors.white : scheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: useLight ? Colors.white.withOpacity(0.18) : scheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 12, color: useLight ? Colors.white : scheme.primary),
          ),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1)),
        ],
      ),
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
        'name': 'Calorias',
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
            Text('Ver mas',
                style: TextStyle(
                    color: scheme.onSurface.withOpacity(0.6), fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
        _statusCard(
          card,
          scheme,
          icon: Icons.local_fire_department,
          title: 'Calorias consumidas',
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
          title: 'Balance calorico',
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








