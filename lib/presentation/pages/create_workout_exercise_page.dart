import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/datasources/local_datasource.dart';
import '../../data/repositories/workout_exercise_repository.dart';
import '../../domain/entities/workout_exercise.dart';

class CreateWorkoutExercisePage extends StatefulWidget {
  final int dayId;
  final String dayName;

  const CreateWorkoutExercisePage({
    super.key,
    required this.dayId,
    required this.dayName,
  });

  @override
  State<CreateWorkoutExercisePage> createState() =>
      _CreateWorkoutExercisePageState();
}

class _CreateWorkoutExercisePageState extends State<CreateWorkoutExercisePage> {
  late final WorkoutExerciseRepository _exerciseRepository;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _setsController = TextEditingController(text: '3');
  final TextEditingController _repsController =
      TextEditingController(text: '8-12');
  final TextEditingController _weightController =
      TextEditingController(text: '0');
  final TextEditingController _restController =
      TextEditingController(text: '60');

  List<_ExerciseItem> _allExercises = [];
  List<_ExerciseItem> _filteredExercises = [];
  Set<String> _bodyParts = {};
  String _bodyPartFilter = 'Todos';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _exerciseRepository = WorkoutExerciseRepository(LocalDataSource());
    _loadExercisesFromAsset();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _restController.dispose();
    super.dispose();
  }

  Future<void> _loadExercisesFromAsset() async {
    try {
      final raw =
          await rootBundle.loadString('assets/data/exercises_es_traducido.json');
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final list = (decoded['exercises'] as List<dynamic>)
          .map((e) => _ExerciseItem.fromMap(e as Map<String, dynamic>))
          .toList();

      final parts = <String>{'Todos'};
      for (final ex in list) {
        parts.addAll(ex.bodyParts);
      }

      setState(() {
        _allExercises = list;
        _bodyParts = parts;
        _filteredExercises = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo cargar ejercicios locales: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredExercises = _allExercises.where((ex) {
        final matchesQuery = ex.name.toLowerCase().contains(query);
        final matchesBody = _bodyPartFilter == 'Todos'
            ? true
            : ex.bodyParts.map((e) => e.toLowerCase()).contains(
                  _bodyPartFilter.toLowerCase(),
                );
        return matchesQuery && matchesBody;
      }).toList();
    });
  }

  Future<void> _addExercise(_ExerciseItem item) async {
    if (_saving) return;
    if (!_validateInputs()) return;

    setState(() => _saving = true);
    try {
      final existing =
          await _exerciseRepository.getExercisesByDayId(widget.dayId);
      final nextOrder = existing.length + 1;

      final exercise = WorkoutExercise(
        id: DateTime.now().millisecondsSinceEpoch,
        dayId: widget.dayId,
        name: item.name,
        sets: int.tryParse(_setsController.text) ?? 3,
        reps: _repsController.text.trim().isEmpty
            ? '8-12'
            : _repsController.text.trim(),
        weight: double.tryParse(_weightController.text) ?? 0,
        restTimeSeconds: int.tryParse(_restController.text) ?? 60,
        order: nextOrder,
      );

      await _exerciseRepository.saveExercise(exercise);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar ejercicio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _validateInputs() {
    if (_setsController.text.trim().isEmpty ||
        _repsController.text.trim().isEmpty ||
        _restController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa series, repeticiones y descanso'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
    return true;
  }

  void _showExerciseSheet(_ExerciseItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Agregar Ejercicio\n${item.name}',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    item.gifUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _setsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Series'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _repsController,
                        decoration: const InputDecoration(
                          labelText: 'Repeticiones',
                          hintText: '8-12',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Peso (kg)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _restController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Descanso (s)'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _saving ? null : () => _addExercise(item),
              child: Text(_saving ? 'Agregando...' : 'Agregar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Ejercicios - ${widget.dayName}'),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar ejercicio',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: scheme.surfaceVariant.withOpacity(0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: _bodyParts
                        .map(
                          (part) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(part),
                              selected: _bodyPartFilter == part,
                              onSelected: (_) {
                                setState(() {
                                  _bodyPartFilter = part;
                                });
                                _applyFilters();
                              },
                              selectedColor:
                                  scheme.primary.withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: _bodyPartFilter == part
                                    ? scheme.primary
                                    : scheme.onSurface,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _filteredExercises.isEmpty
                      ? const Center(
                          child: Text('No se encontraron ejercicios'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          itemCount: _filteredExercises.length,
                          itemBuilder: (context, index) {
                            final ex = _filteredExercises[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _showExerciseSheet(ex),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.asset(
                                          ex.gifUrl,
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            width: 70,
                                            height: 70,
                                            color: Colors.grey.shade200,
                                            child: const Icon(
                                              Icons.image_not_supported,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ex.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              ex.bodyParts.join(', '),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            Text(
                                              ex.targetMuscles.join(', '),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle),
                                        color: scheme.primary,
                                        onPressed: () => _showExerciseSheet(ex),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _ExerciseItem {
  final String id;
  final String name;
  final String gifUrl;
  final List<String> targetMuscles;
  final List<String> bodyParts;

  _ExerciseItem({
    required this.id,
    required this.name,
    required this.gifUrl,
    required this.targetMuscles,
    required this.bodyParts,
  });

  factory _ExerciseItem.fromMap(Map<String, dynamic> map) {
    return _ExerciseItem(
      id: map['exerciseId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      gifUrl: map['gifUrl']?.toString() ?? '',
      targetMuscles: List<String>.from(map['targetMuscles'] ?? const []),
      bodyParts: List<String>.from(map['bodyParts'] ?? const []),
    );
  }
}
