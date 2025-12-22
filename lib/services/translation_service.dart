import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../domain/entities/translation_cache.dart';
import '../domain/entities/exercise_db_entity.dart';
import '../utils/constants.dart';

class TranslationService {
  static const String _boxName = 'translations';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  late Box<TranslationCache> _translationBox;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _translationBox = await Hive.openBox<TranslationCache>(_boxName);
    _isInitialized = true;
  }

  // Traducir lista de ejercicios en batch
  Future<Map<String, String>> translateExercisesBatch(
      List<String> exercises) async {
    await init();

    Map<String, String> translations = {};
    List<String> toTranslate = [];

    // Primero intentar obtener de caché
    for (var exercise in exercises) {
      final cached = _getFromCache(exercise, 'exercise');
      if (cached != null) {
        translations[exercise] = cached;
      } else {
        toTranslate.add(exercise);
      }
    }

    // Traducir los que no están en caché
    if (toTranslate.isNotEmpty) {
      try {
        final batchTranslations = await _translateBatchWithGemini(toTranslate);

        // Guardar en caché y agregar al resultado
        for (var entry in batchTranslations.entries) {
          translations[entry.key] = entry.value;
          await _saveToCache(entry.key, entry.value, 'exercise');
        }
      } catch (e) {
        print('Error traduciendo lote: $e');
        // Para los que fallaron, usar el original
        for (var exercise in toTranslate) {
          translations[exercise] = exercise;
        }
      }
    }

    return translations;
  }

  // Traducir un solo texto
  Future<String> translate(String text, String type) async {
    await init();

    // Intentar obtener de caché primero
    final cached = _getFromCache(text, type);
    if (cached != null) {
      return cached;
    }

    // Si no está en caché, traducir con Gemini
    try {
      final translated = await _translateWithGemini(text, type);
      await _saveToCache(text, translated, type);
      return translated;
    } catch (e) {
      print('Error traduciendo "$text": $e');
      return text; // Retornar original si falla
    }
  }

  // Traducir múltiples ejercicios en una sola llamada a Gemini
  Future<Map<String, String>> _translateBatchWithGemini(
      List<String> exercises) async {
    if (AppConstants.geminiApiKey.isEmpty) {
      return {for (var e in exercises) e: e};
    }

    // Procesar en lotes de 50 para evitar respuestas muy largas
    const batchSize = 50;
    Map<String, String> allTranslations = {};

    for (int i = 0; i < exercises.length; i += batchSize) {
      final batch = exercises.skip(i).take(batchSize).toList();

      final prompt = '''
Traduce los siguientes nombres de ejercicios del inglés al español.
Mantén el formato JSON exacto. No agregues explicaciones adicionales.

Ejercicios a traducir:
${batch.map((e) => '"$e"').join(',\n')}

Responde SOLO con un objeto JSON en este formato:
{
  "exercise_name_1": "nombre_traducido_1",
  "exercise_name_2": "nombre_traducido_2"
}

IMPORTANTE:
- Solo responde con el JSON, sin texto adicional
- Las traducciones deben ser naturales en español
- Mantén los términos técnicos del fitness
''';

      try {
        final response = await http
            .post(
              Uri.parse(_baseUrl),
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': AppConstants.geminiApiKey,
              },
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': prompt}
                    ]
                  }
                ],
                'generationConfig': {
                  'temperature': 0.3,
                  'maxOutputTokens': 2000,
                }
              }),
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw Exception('Timeout en traducción'),
            );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['candidates'] != null && data['candidates'].isNotEmpty) {
            final candidate = data['candidates'][0];
            final content = candidate['content']['parts'][0]['text'];

            // Limpiar y parsear JSON
            final cleanContent =
                content.replaceAll('```json', '').replaceAll('```', '').trim();

            final translations =
                jsonDecode(cleanContent) as Map<String, dynamic>;

            // Agregar al mapa de traducciones
            for (var entry in translations.entries) {
              allTranslations[entry.key] = entry.value.toString();
            }
          }
        }

        // Pequeña pausa entre lotes
        if (i + batchSize < exercises.length) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        print('Error traduciendo lote: $e');
        // Usar originales para este lote
        for (var exercise in batch) {
          if (!allTranslations.containsKey(exercise)) {
            allTranslations[exercise] = exercise;
          }
        }
      }
    }

    return allTranslations;
  }

  // Traducir un solo texto con Gemini
  Future<String> _translateWithGemini(String text, String type) async {
    if (AppConstants.geminiApiKey.isEmpty) {
      return text;
    }

    String typeInSpanish = _getTypeInSpanish(type);

    final prompt = '''
Traduce al español el siguiente $typeInSpanish de fitness: "$text"

Responde SOLO con la traducción, sin explicaciones adicionales.
La traducción debe ser natural y usar términos técnicos apropiados del fitness en español.
''';

    final response = await http
        .post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': AppConstants.geminiApiKey,
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.3,
              'maxOutputTokens': 100,
            }
          }),
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception('Timeout en traducción'),
        );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['candidates'] != null && data['candidates'].isNotEmpty) {
        final candidate = data['candidates'][0];
        final content = candidate['content']['parts'][0]['text'];
        return content.trim();
      }
    }

    throw Exception('Error al traducir: ${response.statusCode}');
  }

  String _getTypeInSpanish(String type) {
    switch (type) {
      case 'exercise':
        return 'ejercicio';
      case 'muscle':
        return 'músculo';
      case 'bodyPart':
        return 'parte del cuerpo';
      case 'equipment':
        return 'equipamiento';
      default:
        return 'término';
    }
  }

  String? _getFromCache(String text, String type) {
    final key = '${type}_${text.toLowerCase()}';
    final cached = _translationBox.get(key);
    return cached?.translatedText;
  }

  Future<void> _saveToCache(
      String original, String translated, String type) async {
    final key = '${type}_${original.toLowerCase()}';
    final cache = TranslationCache(
      originalText: original,
      translatedText: translated,
      type: type,
      createdAt: DateTime.now(),
    );
    await _translationBox.put(key, cache);
  }

  Future<void> clearCache() async {
    await init();
    await _translationBox.clear();
  }

  Future<int> getCacheSize() async {
    await init();
    return _translationBox.length;
  }

  /// Traduce ejercicios completos (todos los campos) en batch
  Future<List<ExerciseDbEntity>> translateCompleteExercises(
      List<ExerciseDbEntity> exercises) async {
    if (AppConstants.geminiApiKey.isEmpty) {
      print('⚠️ API Key de Gemini no configurada, ejercicios no traducidos');
      return exercises;
    }

    // Procesar en lotes de 5 para evitar respuestas muy largas y errores de parsing
    const batchSize = 5;
    List<ExerciseDbEntity> translatedExercises = [];

    for (int i = 0; i < exercises.length; i += batchSize) {
      final batch = exercises.skip(i).take(batchSize).toList();

      print(
          '🔄 Traduciendo lote ${(i ~/ batchSize) + 1}/${(exercises.length / batchSize).ceil()} (${batch.length} ejercicios)...');

      try {
        // Crear el prompt con todos los ejercicios del lote
        final exercisesJson = batch
            .map((e) => {
                  'id': e.exerciseId,
                  'name': e.name,
                  'targetMuscles': e.targetMuscles,
                  'bodyParts': e.bodyParts,
                  'equipments': e.equipments,
                  'secondaryMuscles': e.secondaryMuscles,
                  'instructions': e.instructions,
                })
            .toList();

        final prompt = '''
Traduce estos ejercicios de fitness del inglés al español. Responde SOLO con el JSON, nada más.

Entrada:
${jsonEncode(exercisesJson)}

Salida esperada (array JSON):
[
  {
    "id": "mismo_id_sin_cambios",
    "name": "nombre_traducido_al_español",
    "targetMuscles": ["músculos_en_español"],
    "bodyParts": ["partes_en_español"],
    "equipments": ["equipamiento_en_español"],
    "secondaryMuscles": ["músculos_secundarios_en_español"],
    "instructions": ["instrucciones_en_español"]
  }
]

REGLAS CRÍTICAS:
1. NO cambies los IDs
2. Traduce TODO al español
3. USA COMILLAS DOBLES siempre
4. NO uses apóstrofes ni caracteres especiales
5. RESPONDE SOLO CON EL JSON (sin ```json ni texto extra)
''';

        final response = await http
            .post(
              Uri.parse(_baseUrl),
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': AppConstants.geminiApiKey,
              },
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': prompt}
                    ]
                  }
                ],
                'generationConfig': {
                  'temperature': 0.1,
                  'maxOutputTokens': 16000,
                }
              }),
            )
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () =>
                  throw Exception('Timeout en traducción de ejercicios'),
            );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['candidates'] != null && data['candidates'].isNotEmpty) {
            final candidate = data['candidates'][0];
            final content = candidate['content']['parts'][0]['text'];

            // Limpiar y parsear JSON
            var cleanContent =
                content.replaceAll('```json', '').replaceAll('```', '').trim();

            // Intentar reparar JSON común mal formado
            // Quitar texto antes del primer [
            final startIndex = cleanContent.indexOf('[');
            if (startIndex > 0) {
              cleanContent = cleanContent.substring(startIndex);
            }

            // Quitar texto después del último ]
            final endIndex = cleanContent.lastIndexOf(']');
            if (endIndex >= 0 && endIndex < cleanContent.length - 1) {
              cleanContent = cleanContent.substring(0, endIndex + 1);
            }

            List<dynamic> translatedData;
            try {
              translatedData = jsonDecode(cleanContent);
            } catch (e) {
              print('⚠️ Error parseando JSON: $e');
              print(
                  'Contenido problemático: ${cleanContent.substring(0, cleanContent.length > 200 ? 200 : cleanContent.length)}...');
              throw Exception('JSON inválido: $e');
            }

            // Crear nuevas instancias de ExerciseDbEntity con datos traducidos
            for (int j = 0; j < batch.length; j++) {
              final original = batch[j];
              final translated = translatedData[j];

              final translatedExercise = ExerciseDbEntity(
                exerciseId: original.exerciseId,
                name: translated['name'] ?? original.name,
                gifUrl: original.gifUrl, // No traducir URL
                targetMuscles: List<String>.from(
                    translated['targetMuscles'] ?? original.targetMuscles),
                bodyParts: List<String>.from(
                    translated['bodyParts'] ?? original.bodyParts),
                equipments: List<String>.from(
                    translated['equipments'] ?? original.equipments),
                secondaryMuscles: List<String>.from(
                    translated['secondaryMuscles'] ??
                        original.secondaryMuscles),
                instructions: List<String>.from(
                    translated['instructions'] ?? original.instructions),
              );

              translatedExercises.add(translatedExercise);
            }

            print('✅ Lote traducido exitosamente');
          } else {
            print('⚠️ Respuesta vacía de Gemini, usando ejercicios originales');
            translatedExercises.addAll(batch);
          }
        } else {
          print(
              '⚠️ Error ${response.statusCode} de Gemini, usando ejercicios originales');
          translatedExercises.addAll(batch);
        }

        // Pausa entre lotes para respetar rate limits
        if (i + batchSize < exercises.length) {
          await Future.delayed(const Duration(milliseconds: 2000));
        }
      } catch (e) {
        print('❌ Error traduciendo lote: $e');
        print('⚠️ Usando ejercicios originales (sin traducir) para este lote');

        // Usar ejercicios originales para este lote como fallback
        translatedExercises.addAll(batch);

        // Pausa más larga después de un error
        await Future.delayed(const Duration(milliseconds: 3000));
      }
    }

    return translatedExercises;
  }
}
