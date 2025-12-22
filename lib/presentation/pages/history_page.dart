import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/datasources/local_datasource.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../data/repositories/meal_repository.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/meal.dart';
import 'add_exercise_page.dart';
import 'add_meal_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late final MealRepository _mealRepository;
  late final ExerciseRepository _exerciseRepository;
  late final TabController _tabController;

  List<Meal> _meals = [];
  List<Exercise> _exercises = [];
  bool _isLoading = true;

  List<DateTime> get _last7Days => List.generate(
      7, (i) => _stripTime(DateTime.now().subtract(Duration(days: 6 - i))));

  @override
  void initState() {
    super.initState();
    _mealRepository = MealRepository(LocalDataSource());
    _exerciseRepository = ExerciseRepository(LocalDataSource());
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final meals = await _mealRepository.getAllMeals();
      final exercises = await _exerciseRepository.getAllExercises();

      meals.sort((a, b) => b.fecha.compareTo(a.fecha));
      exercises.sort((a, b) => b.fecha.compareTo(a.fecha));

      if (!mounted) return;
      setState(() {
        _meals = meals;
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Comidas'),
            Tab(text: 'Ejercicios'),
          ],
        ),
      ),
      floatingActionButton: _isLoading
          ? null
          : _tabController.index == 0
              ? _primaryFab(
                  scheme,
                  label: 'Agregar comida',
                  icon: Icons.restaurant,
                  onTap: _goToAddMeal,
                )
              : _primaryFab(
                  scheme,
                  label: 'Registrar ejercicio',
                  icon: Icons.fitness_center,
                  onTap: _goToAddExercise,
                ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMealsTab(scheme),
                _buildExercisesTab(scheme),
              ],
            ),
    );
  }

  Widget _buildMealsTab(ColorScheme scheme) {
    return RefreshIndicator(
      color: scheme.primary,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _weeklyCard(
            scheme,
            title: 'Calorias de la semana',
            subtitle: 'Consumo diario (ultimos 7 dias)',
            icon: Icons.local_fire_department,
            accent: scheme.primary,
            valueForDay: _caloriesForDay,
          ),
          const SizedBox(height: 12),
          _sectionHeader(
            scheme,
            title: 'Comidas registradas',
            action: TextButton.icon(
              onPressed: _goToAddMeal,
              icon: const Icon(Icons.add),
              label: const Text('Agregar comida'),
            ),
          ),
          const SizedBox(height: 4),
          if (_meals.isEmpty)
            _emptyState(
              scheme,
              icon: Icons.restaurant,
              title: 'No hay comidas registradas',
              message:
                  'Agrega tu primera comida para llevar el control diario.',
            )
          else
            ..._meals.map((meal) => _mealCard(meal, scheme)),
        ],
      ),
    );
  }

  Widget _buildExercisesTab(ColorScheme scheme) {
    return RefreshIndicator(
      color: scheme.primary,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _weeklyCard(
            scheme,
            title: 'Calorias quemadas',
            subtitle: 'Actividad diaria (ultimos 7 dias)',
            icon: Icons.fitness_center,
            accent: const Color(0xFF2ED8A7),
            valueForDay: _burnedForDay,
          ),
          const SizedBox(height: 12),
          _sectionHeader(
            scheme,
            title: 'Ejercicios registrados',
            action: TextButton.icon(
              onPressed: _goToAddExercise,
              icon: const Icon(Icons.add),
              label: const Text('Registrar ejercicio'),
            ),
          ),
          const SizedBox(height: 4),
          if (_exercises.isEmpty)
            _emptyState(
              scheme,
              icon: Icons.fitness_center,
              title: 'No hay ejercicios registrados',
              message: 'Registra tus entrenamientos para ver tu progreso.',
            )
          else
            ..._exercises.map((exercise) => _exerciseCard(exercise, scheme)),
        ],
      ),
    );
  }

  Widget _weeklyCard(
    ColorScheme scheme, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required double Function(DateTime day) valueForDay,
  }) {
    final values = _last7Days.map(valueForDay).toList();
    final total = values.fold<double>(0, (sum, v) => sum + v);
    final maxValue = values.fold<double>(0, max);
    final average = values.isNotEmpty ? total / values.length : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: accent.withOpacity(0.12),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700)),
                    Text(subtitle,
                        style: TextStyle(
                            color: scheme.onSurface.withOpacity(0.6),
                            fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${total.toStringAsFixed(0)} kcal',
                      style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Text('Promedio ${average.toStringAsFixed(0)} kcal',
                      style: TextStyle(
                          color: scheme.onSurface.withOpacity(0.6),
                          fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_last7Days.length, (i) {
                final day = _last7Days[i];
                final value = values[i];
                final barHeight = maxValue == 0
                    ? 6.0
                    : max<double>(8.0, (value / maxValue) * 110);
                final isToday = _isSameDay(day, DateTime.now());
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _dayAbbr(day),
                        style: TextStyle(
                          color:
                              scheme.onSurface.withOpacity(isToday ? 1 : 0.7),
                          fontWeight:
                              isToday ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: barHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accent, accent.withOpacity(0.65)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          color:
                              scheme.onSurface.withOpacity(isToday ? 1 : 0.6),
                          fontSize: 12,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mealCard(Meal meal, ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _squareThumb(
            scheme,
            path: meal.imagenPath,
            icon: Icons.restaurant,
            color: scheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.nombre,
                    style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const SizedBox(height: 6),
                Text(
                  '${meal.calorias.toStringAsFixed(0)} kcal',
                  style: TextStyle(
                      color: scheme.primary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(meal.fecha),
                  style: TextStyle(
                      color: scheme.onSurface.withOpacity(0.6), fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _deleteMeal(meal),
            icon: const Icon(Icons.delete_outline),
            color: scheme.error,
            tooltip: 'Eliminar',
          ),
        ],
      ),
    );
  }

  Widget _exerciseCard(Exercise exercise, ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _squareThumb(
            scheme,
            path: exercise.imagenPath,
            icon: Icons.fitness_center,
            color: const Color(0xFF2ED8A7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.tipo,
                    style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const SizedBox(height: 6),
                Text(
                  '${exercise.caloriasQuemadas.toStringAsFixed(0)} kcal quemadas',
                  style: TextStyle(
                      color: const Color(0xFF2ED8A7),
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(exercise.fecha),
                  style: TextStyle(
                      color: scheme.onSurface.withOpacity(0.6), fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _deleteExercise(exercise),
            icon: const Icon(Icons.delete_outline),
            color: scheme.error,
            tooltip: 'Eliminar',
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(ColorScheme scheme,
      {required String title, Widget? action}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 16),
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _squareThumb(ColorScheme scheme,
      {required String path, required IconData icon, required Color color}) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: path.isNotEmpty
            ? Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(icon, color: color),
              )
            : Icon(icon, color: color),
      ),
    );
  }

  Widget _emptyState(ColorScheme scheme,
      {required IconData icon,
      required String title,
      required String message}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: scheme.onSurface.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(title,
              style: TextStyle(
                  color: scheme.onSurface, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(color: scheme.onSurface.withOpacity(0.6)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _primaryFab(ColorScheme scheme,
      {required String label,
      required IconData icon,
      required VoidCallback onTap}) {
    return FloatingActionButton.extended(
      onPressed: onTap,
      backgroundColor: scheme.primary,
      foregroundColor: Colors.white,
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Future<void> _goToAddMeal() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddMealPage()),
    );
    await _loadData();
  }

  Future<void> _goToAddExercise() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddExercisePage()),
    );
    await _loadData();
  }

  Future<void> _deleteMeal(Meal meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const SizedBox.shrink(),
        content: Text('Quieres eliminar "${meal.nombre}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _mealRepository.deleteMeal(meal.id);
        await _loadData();
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Comida eliminada')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  Future<void> _deleteExercise(Exercise exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const SizedBox.shrink(),
        content: Text('Quieres eliminar "${exercise.tipo}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _exerciseRepository.deleteExercise(exercise.id);
        await _loadData();
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ejercicio eliminado')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  double _caloriesForDay(DateTime day) {
    return _meals
        .where((m) => _isSameDay(m.fecha, day))
        .fold<double>(0, (sum, meal) => sum + meal.calorias);
  }

  double _burnedForDay(DateTime day) {
    return _exercises
        .where((e) => _isSameDay(e.fecha, day))
        .fold<double>(0, (sum, exercise) => sum + exercise.caloriasQuemadas);
  }

  String _formatDateTime(DateTime dateTime) {
    final today = _stripTime(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final date = _stripTime(dateTime);
    final time = _formatTime(dateTime);

    if (_isSameDay(date, today)) return 'Hoy - $time';
    if (_isSameDay(date, yesterday)) return 'Ayer - $time';
    return '${date.day}/${date.month}/${date.year} - $time';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _dayAbbr(DateTime date) {
    const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return days[date.weekday - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _stripTime(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
