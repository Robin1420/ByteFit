import 'package:flutter/material.dart';
import '../../domain/entities/exercise_db_entity.dart';
import '../../i18n/i18n.dart';

class ExerciseAutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final List<ExerciseDbEntity> allExercises;
  final List<ExerciseDbEntity> filteredExercises;
  final bool isLoadingExercises;
  final Function(ExerciseDbEntity) onShowDetails;

  const ExerciseAutocompleteField({
    super.key,
    required this.controller,
    required this.allExercises,
    required this.filteredExercises,
    required this.isLoadingExercises,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<ExerciseDbEntity>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return filteredExercises.take(10);
        }
        
        final query = textEditingValue.text.toLowerCase();
        return allExercises.where((exercise) {
          final exerciseName = exercise.name.toLowerCase();
          final translatedName = I18n.translateExercise(exercise.name).toLowerCase();
          return exerciseName.contains(query) || translatedName.contains(query);
        }).take(10);
      },
      displayStringForOption: (ExerciseDbEntity exercise) {
        return I18n.translateExercise(exercise.name);
      },
      onSelected: (ExerciseDbEntity exercise) {
        controller.text = I18n.translateExercise(exercise.name);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          onFieldSubmitted: (value) => onFieldSubmitted(),
          decoration: InputDecoration(
            labelText: 'Nombre del Ejercicio',
            hintText: 'Buscar ejercicio...',
            prefixIcon: const Icon(Icons.fitness_center),
            suffixIcon: isLoadingExercises
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor selecciona un ejercicio';
            }
            return null;
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final exercise = options.elementAt(index);
                  final translatedName = I18n.translateExercise(exercise.name);
                  
                  return ListTile(
                    dense: true,
                    leading: exercise.gifUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              exercise.gifUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.fitness_center, size: 20),
                                );
                              },
                            ),
                          )
                        : Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.fitness_center, size: 20),
                          ),
                    title: Text(
                      translatedName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: exercise.name != translatedName
                        ? Text(
                            exercise.name,
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
                          )
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.info_outline, size: 20),
                      onPressed: () => onShowDetails(exercise),
                    ),
                    onTap: () => onSelected(exercise),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

