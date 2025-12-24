import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/datasources/local_datasource.dart';
import '../../data/repositories/meal_repository.dart';
import '../../domain/entities/meal.dart';
import '../../services/gemini_service.dart';

class AddMealPage extends StatefulWidget {
  const AddMealPage({super.key});

  @override
  State<AddMealPage> createState() => _AddMealPageState();
}

class _AddMealPageState extends State<AddMealPage> {
  late final MealRepository _mealRepository;
  final ImagePicker _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();

  double _todayCalories = 0;
  int _todayMeals = 0;
  double _weekCalories = 0;
  List<double> _weekDayCalories = List.filled(7, 0);
  List<Meal> _meals = [];

  @override
  void initState() {
    super.initState();
    _mealRepository = MealRepository(LocalDataSource());
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        color: scheme.primary,
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            _statsHeader(scheme),
            const SizedBox(height: 16),
            _mealTypesSection(scheme),
            const SizedBox(height: 16),
            _weeklyCalendarCard(scheme),
          ],
        ),
      ),
    );
  }

  Widget _statsHeader(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen de consumo',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        _statCard(
          scheme,
          title: 'Hoy',
          subtitle: 'Comidas registradas',
          value: '${_todayCalories.toStringAsFixed(0)} kcal',
          detail: '$_todayMeals comidas',
          icon: Icons.today,
          backgroundAsset: 'assets/Imagenes/card_comida.png',
          useLightText: true,
        ),
      ],
    );
  }

  Widget _mealTypesSection(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comidas del dÃ­a',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        ..._mealTypes.map((type) {
          final consumed = _getCaloriesForType(type.key);
          final goal = _mealGoals[type.key] ?? 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outline.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: type.color.withOpacity(0.12),
                  child: Icon(type.icon, color: type.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type.title,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 2),
                      Text(
                        '${consumed.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} kcal',
                        style: TextStyle(
                          color: scheme.onSurface.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => _openMealModal(type),
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.primary.withOpacity(0.15),
                    foregroundColor: scheme.primary,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Future<void> _openMealModal(_MealType type) async {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    File? selectedImage;
    bool analyzing = false;
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setStateModal) {
            Future<void> pick(ImageSource source) async {
              final XFile? image = await _picker.pickImage(source: source);
              if (image != null) {
                setStateModal(() => selectedImage = File(image.path));
              }
            }

            Future<void> analyze() async {
              if (selectedImage == null) return;
              setStateModal(() => analyzing = true);
              try {
                final result =
                    await _geminiService.analyzeFoodImage(selectedImage!);
                setStateModal(() {
                  nameController.text = result['nombre'] ?? '';
                  caloriesController.text =
                      result['calorias']?.toString() ?? '';
                });
                _showSnack('AnÃ¡lisis completado. Revisa los datos.');
              } catch (e) {
                _showSnack('Error al analizar: $e', isError: true);
              } finally {
                setStateModal(() => analyzing = false);
              }
            }

            Future<void> save() async {
              if (caloriesController.text.isEmpty) {
                _showSnack('Ingresa calorias', isError: true);
                return;
              }
              final calories = double.tryParse(caloriesController.text);
              if (calories == null) {
                _showSnack('Calorias invalidas', isError: true);
                return;
              }
              setStateModal(() => saving = true);
              try {
                final now = DateTime.now();
                final meal = Meal(
                  id: now.microsecondsSinceEpoch % 1000000,
                  fecha: now,
                  nombre:
                      '${type.title} - ${nameController.text.trim().isEmpty ? type.title : nameController.text.trim()}',
                  calorias: calories,
                  imagenPath: selectedImage?.path ?? '',
                );
                await _mealRepository.saveMeal(meal);
                await _loadStats();
                if (mounted) Navigator.pop(context, true);
              } catch (e) {
                _showSnack('Error al guardar: $e', isError: true);
              } finally {
                setStateModal(() => saving = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agregar ${type.title.toLowerCase()}',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (selectedImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          Image.file(
                            selectedImage!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: CircleAvatar(
                              backgroundColor: scheme.surface.withOpacity(0.9),
                              child: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () =>
                                    setStateModal(() => selectedImage = null),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  if (selectedImage != null) const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          label: 'Tomar foto',
                          icon: Icons.camera_alt,
                          onTap: () => pick(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _actionButton(
                          label: 'GalerÃ­a',
                          icon: Icons.photo_library,
                          onTap: () => pick(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del alimento',
                      prefixIcon: Icon(Icons.restaurant),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: caloriesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Calorias',
                      prefixIcon: Icon(Icons.local_fire_department),
                      suffixText: 'kcal',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: analyzing ? null : analyze,
                          icon: analyzing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome),
                          label:
                              Text(analyzing ? 'Analizando...' : 'Analizar IA'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: saving ? null : save,
                          child: saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statCard(
    ColorScheme scheme, {
    required String title,
    required String subtitle,
    required String value,
    required String detail,
    required IconData icon,
    String? backgroundAsset,
    bool useLightText = false,
  }) {
    final textColor = useLightText ? Colors.white : scheme.onSurface;
    final subTextColor = useLightText
        ? Colors.white.withOpacity(0.85)
        : scheme.onSurface.withOpacity(0.6);

    return Container(
      decoration: BoxDecoration(
        color: backgroundAsset == null ? scheme.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            if (backgroundAsset != null)
              Positioned.fill(
                  child: Image.asset(backgroundAsset, fit: BoxFit.cover)),
            if (backgroundAsset != null)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: const [0.0, 0.5, 0.85, 1],
                      colors: [
                        scheme.primary.withOpacity(0.88),
                        scheme.primary.withOpacity(0.62),
                        scheme.primary.withOpacity(0.24),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w700)),
                            Text(subtitle,
                                style: TextStyle(
                                    color: subTextColor, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    value,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 12,
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

  Widget _weeklyCalendarCard(ColorScheme scheme) {
    final days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final maxValue = _weekDayCalories.fold<double>(
        0, (maxVal, v) => v > maxVal ? v : maxVal);

    return Container(
      padding: const EdgeInsets.all(14),
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
                radius: 18,
                backgroundColor: scheme.primary.withOpacity(0.12),
                child: Icon(Icons.calendar_view_week, color: scheme.primary),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Semana',
                      style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700)),
                  Text('Lunes a Domingo',
                      style: TextStyle(
                          color: scheme.onSurface.withOpacity(0.6),
                          fontSize: 12)),
                ],
              ),
              const Spacer(),
              Text(
                '${_weekCalories.toStringAsFixed(0)} kcal',
                style: TextStyle(
                    color: scheme.onSurface, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final value = _weekDayCalories[index];
              final barHeight =
                  maxValue == 0 ? 10.0 : (value / maxValue) * 90 + 10;
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      value.toStringAsFixed(0),
                      style: TextStyle(
                        color: scheme.onSurface.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      height: barHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            scheme.primary,
                            scheme.primary.withOpacity(0.6)
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      days[index],
                      style: TextStyle(
                        color: scheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _loadStats() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayCalories = await _mealRepository.getTotalCaloriesByDate(today);
    final todayMeals = await _mealRepository.getMealsByDate(today);
    final weekMeals = await _mealRepository.getMealsLastWeek();
    final weekCalories =
        weekMeals.fold<double>(0, (sum, meal) => sum + meal.calorias);
    final allMeals = await _mealRepository.getAllMeals();

    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final weekDayCalories = List<double>.filled(7, 0);
    for (final meal in weekMeals) {
      final day = DateTime(meal.fecha.year, meal.fecha.month, meal.fecha.day);
      final diff = day.difference(startOfWeek).inDays;
      if (diff >= 0 && diff < 7) {
        weekDayCalories[diff] += meal.calorias;
      }
    }

    if (!mounted) return;
    setState(() {
      _todayCalories = todayCalories;
      _todayMeals = todayMeals.length;
      _weekCalories = weekCalories;
      _weekDayCalories = weekDayCalories;
      _meals = allMeals;
    });
  }

  double _getCaloriesForType(String typeKey) {
    final prefix = '$typeKey -';
    return _meals
        .where((meal) =>
            meal.nombre.toLowerCase().startsWith(prefix.toLowerCase()))
        .fold<double>(0, (sum, meal) => sum + meal.calorias);
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _MealType {
  final String key;
  final String title;
  final IconData icon;
  final Color color;
  const _MealType(this.key, this.title, this.icon, this.color);
}

const _mealTypes = [
  _MealType('Desayuno', 'Desayuno', Icons.free_breakfast, Color(0xFF0EA5E9)),
  _MealType('Almuerzo', 'Almuerzo', Icons.lunch_dining, Color(0xFF22C55E)),
  _MealType('Cena', 'Cena', Icons.dinner_dining, Color(0xFFF97316)),
  _MealType('Snacks', 'Snacks', Icons.local_pizza, Color(0xFFE11D48)),
];

const _mealGoals = {
  'Desayuno': 500.0,
  'Almuerzo': 700.0,
  'Cena': 600.0,
  'Snacks': 250.0,
};
