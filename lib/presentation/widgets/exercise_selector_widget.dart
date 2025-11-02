import 'package:flutter/material.dart';
import '../../services/exercise_cache_service.dart';
import '../../domain/entities/exercise_db_entity.dart';
import '../../i18n/i18n.dart';

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
  List<ExerciseDbEntity> _exercises = [];
  ExerciseDbEntity? _selectedExercise;
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedExercise = widget.initialExercise;
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    print('🔄 ExerciseSelectorWidget: Loading exercises...');
    setState(() {
      _isLoading = true;
    });

    try {
      await _cacheService.init();
      final hasExercises = await _cacheService.hasExercises();
      print('🔍 ExerciseSelectorWidget: Has exercises: $hasExercises');
      
      if (hasExercises) {
        final exercises = await _cacheService.getAllExercises();
        print('✅ ExerciseSelectorWidget: Loaded ${exercises.length} exercises');
        setState(() {
          _exercises = exercises;
          _isLoading = false;
        });
      } else {
        print('⚠️ ExerciseSelectorWidget: No exercises found');
        setState(() {
          _exercises = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ ExerciseSelectorWidget: Error loading exercises: $e');
      setState(() {
        _exercises = [];
        _isLoading = false;
      });
    }
  }

  List<ExerciseDbEntity> get _filteredExercises {
    if (_searchQuery.isEmpty) return _exercises;
    
    final query = _searchQuery.toLowerCase();
    return _exercises.where((exercise) {
      final translatedName = I18n.translateExercise(exercise.name).toLowerCase();
      final originalName = exercise.name.toLowerCase();
      
      return translatedName.contains(query) || 
             originalName.contains(query) ||
             exercise.targetMuscles.any((muscle) => 
               I18n.translateMuscle(muscle).toLowerCase().contains(query) ||
               muscle.toLowerCase().contains(query)) ||
             exercise.bodyParts.any((part) => 
               I18n.translateBodyPart(part).toLowerCase().contains(query) ||
               part.toLowerCase().contains(query));
    }).toList();
  }

  void _showExerciseDetails(ExerciseDbEntity exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(I18n.translateExercise(exercise.name)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (exercise.gifUrl.isNotEmpty) ...[
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[100],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      exercise.gifUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.fitness_center, size: 50),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              _buildDetailRow('Músculos principales', 
                exercise.targetMuscles.map(I18n.translateMuscle).join(', ')),
              _buildDetailRow('Músculos secundarios', 
                exercise.secondaryMuscles.map(I18n.translateMuscle).join(', ')),
              _buildDetailRow('Partes del cuerpo', 
                exercise.bodyParts.map(I18n.translateBodyPart).join(', ')),
              _buildDetailRow('Equipamiento', 
                exercise.equipments.map(I18n.translateEquipment).join(', ')),
              
              if (exercise.instructions.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Instrucciones:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...exercise.instructions.map((instruction) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $instruction'),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 ExerciseSelectorWidget: Building with ${_exercises.length} exercises');
    print('🔍 ExerciseSelectorWidget: _isLoading = $_isLoading');
    print('🔍 ExerciseSelectorWidget: _searchQuery = "$_searchQuery"');
    print('🔍 ExerciseSelectorWidget: _filteredExercises.length = ${_filteredExercises.length}');
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con título
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.fitness_center, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Seleccionar Ejercicio (${_exercises.length} disponibles)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar ejercicio',
                hintText: 'Escribe el nombre del ejercicio...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Exercise list
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Cargando ejercicios...'),
                  ],
                ),
              ),
            )
          else if (_exercises.isEmpty)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Column(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'No hay ejercicios disponibles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Los ejercicios se descargan automáticamente al iniciar la aplicación.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orange),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadExercises,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recargar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              height: 200,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _filteredExercises.length,
                itemBuilder: (context, index) {
                  final exercise = _filteredExercises[index];
                  final translatedName = I18n.translateExercise(exercise.name);
                  final isSelected = _selectedExercise?.exerciseId == exercise.exerciseId;
                  
                  return ListTile(
                    leading: const Icon(Icons.fitness_center),
                    title: Text(
                      translatedName,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: exercise.name != translatedName 
                        ? Text(
                            exercise.name,
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          )
                        : Text(
                            '${exercise.targetMuscles.map(I18n.translateMuscle).join(', ')}',
                            style: const TextStyle(fontSize: 12),
                          ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () => _showExerciseDetails(exercise),
                        ),
                        if (isSelected)
                          const Icon(Icons.check, color: Colors.green),
                      ],
                    ),
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedExercise = exercise;
                      });
                      widget.onExerciseSelected(exercise);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
