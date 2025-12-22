import 'package:flutter/material.dart';
import '../../services/exercise_cache_service.dart';
import '../../domain/entities/exercise_db_entity.dart';

/// Selector de ejercicios con buscador, filtros y vista previa.
class ExerciseSelectorWidget extends StatefulWidget {
  final Function(ExerciseDbEntity?) onExerciseSelected;
  final ExerciseDbEntity? initialExercise;

  const ExerciseSelectorWidget({
    super.key,
    required this.onExerciseSelected,
    this.initialExercise,
  });

  @override
  State<ExerciseSelectorWidget> createState() => _ExerciseSelectorWidgetState();
}

class _ExerciseSelectorWidgetState extends State<ExerciseSelectorWidget> {
  final ExerciseCacheService _cacheService = ExerciseCacheService();
  final TextEditingController _searchController = TextEditingController();
  List<ExerciseDbEntity> _exercises = [];
  ExerciseDbEntity? _selectedExercise;
  bool _isLoading = false;

  String _selectedMuscle = 'Todos';
  String _selectedBodyPart = 'Todos';
  String _selectedEquipment = 'Todos';

  @override
  void initState() {
    super.initState();
    _selectedExercise = widget.initialExercise;
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    await _cacheService.init();
    final has = await _cacheService.hasExercises();
    if (!mounted) return;
    setState(() {
      _exercises = has ? _cacheService.getAllExercisesSync() : [];
      _isLoading = false;
    });
  }

  List<ExerciseDbEntity> get _filtered {
    final query = _searchController.text.toLowerCase().trim();
    return _exercises.where((ex) {
      final matchesQuery = query.isEmpty ||
          ex.name.toLowerCase().contains(query) ||
          ex.targetMuscles.any((m) => m.toLowerCase().contains(query)) ||
          ex.bodyParts.any((b) => b.toLowerCase().contains(query));
      final matchesMuscle = _selectedMuscle == 'Todos' ||
          ex.targetMuscles.contains(_selectedMuscle) ||
          ex.secondaryMuscles.contains(_selectedMuscle);
      final matchesBody = _selectedBodyPart == 'Todos' ||
          ex.bodyParts.contains(_selectedBodyPart);
      final matchesEquip = _selectedEquipment == 'Todos' ||
          ex.equipments.contains(_selectedEquipment);
      return matchesQuery && matchesMuscle && matchesBody && matchesEquip;
    }).toList();
  }

  List<String> _collectUnique(List<List<String>> lists) {
    final set = <String>{};
    for (final l in lists) {
      set.addAll(l);
    }
    final sorted = set.toList()..sort();
    return ['Todos', ...sorted];
  }

  void _showDetails(ExerciseDbEntity ex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ex.name,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (ex.gifUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ex.gifUrl.startsWith('assets/')
                          ? Image.asset(ex.gifUrl,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover)
                          : Image.network(ex.gifUrl,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover),
                    ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...ex.targetMuscles.map((m) => Chip(label: Text(m))),
                      ...ex.bodyParts.map((b) => Chip(label: Text(b))),
                      ...ex.equipments.map((e) => Chip(label: Text(e))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (ex.instructions.isNotEmpty) ...[
                    Text(
                      'Instrucciones',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    ...ex.instructions.map(
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(child: Text(i)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedExercise = ex;
                        });
                        widget.onExerciseSelected(ex);
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Seleccionar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilters() {
    final muscles = _collectUnique(
        _exercises.map((e) => e.targetMuscles + e.secondaryMuscles).toList());
    final bodyParts =
        _collectUnique(_exercises.map((e) => e.bodyParts).toList());
    final equipment =
        _collectUnique(_exercises.map((e) => e.equipments).toList());

    Widget buildChipList(String label, List<String> items, String selected,
        void Function(String) onSelect) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, idx) {
                final value = items[idx];
                final isSel = value == selected;
                return ChoiceChip(
                  label: Text(value, overflow: TextOverflow.ellipsis),
                  selected: isSel,
                  onSelected: (_) => setState(() => onSelect(value)),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: items.length,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildChipList(
            'Músculos', muscles, _selectedMuscle, (v) => _selectedMuscle = v),
        const SizedBox(height: 12),
        buildChipList('Partes del cuerpo', bodyParts, _selectedBodyPart,
            (v) => _selectedBodyPart = v),
        const SizedBox(height: 12),
        buildChipList('Equipamiento', equipment, _selectedEquipment,
            (v) => _selectedEquipment = v),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercises = _filtered;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + buscador
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fitness_center, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Seleccionar ejercicio (${_exercises.length} disponibles)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (_selectedExercise != null)
                      Chip(
                        backgroundColor: Colors.blue,
                        label: Text(
                          _selectedExercise!.name,
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText:
                        'Buscar por nombre, músculo o parte del cuerpo...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilters(),
                      const SizedBox(height: 12),
                      Container(
                        height: 260,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withOpacity(0.3)),
                        ),
                        child: exercises.isEmpty
                            ? const Center(
                                child: Text('No hay ejercicios que coincidan'),
                              )
                            : ListView.separated(
                                itemCount: exercises.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final ex = exercises[index];
                                  final isSelected =
                                      _selectedExercise?.exerciseId ==
                                          ex.exerciseId;
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: ex.gifUrl.isNotEmpty
                                          ? (ex.gifUrl.startsWith('assets/')
                                              ? Image.asset(ex.gifUrl,
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover)
                                              : Image.network(ex.gifUrl,
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover))
                                          : Container(
                                              width: 48,
                                              height: 48,
                                              color:
                                                  Colors.blue.withOpacity(0.1),
                                              child: const Icon(
                                                  Icons.fitness_center,
                                                  color: Colors.blue),
                                            ),
                                    ),
                                    title: Text(
                                      ex.name,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      ex.targetMuscles.join(', '),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.help_outline),
                                          tooltip: 'Ver detalles',
                                          onPressed: () => _showDetails(ex),
                                        ),
                                        if (isSelected)
                                          const Icon(Icons.check_circle,
                                              color: Colors.green),
                                      ],
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectedExercise = ex;
                                      });
                                      widget.onExerciseSelected(ex);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
