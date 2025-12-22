import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Traduce el JSON offline usando DeepL.
///
/// Uso:
///   $env:DEEPL_API_KEY="TU_KEY"   # PowerShell (o export DEEPL_API_KEY=...)
///   dart run scripts/translate_exercises_deepl.dart
///
/// Lee:  assets/data/exercises_es.json
/// Escribe: assets/data/exercises_es_traducido.json (no toca el original)

Future<void> main() async {
  final apiKey = Platform.environment['DEEPL_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    throw Exception('Define la variable DEEPL_API_KEY con tu API key de DeepL.');
  }

  final sourcePath = 'assets/data/exercises_es.json';
  final targetPath = 'assets/data/exercises_es_traducido.json';

  print('Leyendo $sourcePath ...');
  final sourceFile = File(sourcePath);
  if (!await sourceFile.exists()) {
    throw Exception('No existe $sourcePath. Genera primero los datos offline.');
  }
  final data = jsonDecode(await sourceFile.readAsString());
  final exercises = (data['exercises'] as List).cast<Map<String, dynamic>>();

  // 1) Deduplicar todos los textos
  print('Recolectando textos únicos...');
  final unique = _collectUniqueTexts(exercises);
  print('Total textos únicos a traducir: ${unique.length}');

  // 2) Traducir en lotes
  final translations = await _translateAll(unique, apiKey);
  print('Traducciones obtenidas: ${translations.length}');

  // 3) Reconstruir ejercicios aplicando traducción
  print('Reconstruyendo ejercicios traducidos...');
  final translatedExercises = exercises.map((ex) => _applyTranslations(ex, translations)).toList();

  // 4) Guardar nuevo JSON
  final outData = {
    'version': data['version'] ?? '1.0',
    'total': translatedExercises.length,
    'lastUpdated': DateTime.now().toIso8601String(),
    'exercises': translatedExercises,
  };
  await File(targetPath).writeAsString(jsonEncode(outData));
  print('Listo: $targetPath');
}

Set<String> _collectUniqueTexts(List<Map<String, dynamic>> exercises) {
  final texts = <String>{};
  for (final ex in exercises) {
    void add(dynamic v) {
      if (v == null) return;
      if (v is String && v.trim().isNotEmpty) texts.add(v);
      if (v is List) {
        for (final item in v) {
          if (item is String && item.trim().isNotEmpty) texts.add(item);
        }
      }
    }

    add(ex['name']);
    add(ex['targetMuscles']);
    add(ex['secondaryMuscles']);
    add(ex['bodyParts']);
    add(ex['equipments']);
    add(ex['instructions']);
  }
  return texts;
}

Future<Map<String, String>> _translateAll(Set<String> texts, String apiKey) async {
  const chunkSize = 50;
  final list = texts.toList();
  final result = <String, String>{};

  for (var i = 0; i < list.length; i += chunkSize) {
    final chunk = list.sublist(i, i + chunkSize > list.length ? list.length : i + chunkSize);
    print(' Traduciendo lote ${(i ~/ chunkSize) + 1}/${(list.length / chunkSize).ceil()} (${chunk.length} textos)...');
    final chunkTranslations = await _translateChunk(chunk, apiKey);
    result.addAll(chunkTranslations);
    // Pequeña pausa para ser amable con la API
    if (i + chunkSize < list.length) {
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  return result;
}

Future<Map<String, String>> _translateChunk(List<String> texts, String apiKey) async {
  final bodyParts = <String>[
    'auth_key=${Uri.encodeQueryComponent(apiKey)}',
    'target_lang=ES',
  ];
  for (final t in texts) {
    bodyParts.add('text=${Uri.encodeQueryComponent(t)}');
  }
  final body = bodyParts.join('&');

  final response = await http.post(
    Uri.parse('https://api.deepl.com/v2/translate'),
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: body,
  );

  if (response.statusCode != 200) {
    throw Exception('DeepL error ${response.statusCode}: ${response.body}');
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final translations = (data['translations'] as List).cast<Map<String, dynamic>>();

  if (translations.length != texts.length) {
    throw Exception('DeepL devolvió ${translations.length} traducciones para ${texts.length} textos');
  }

  final map = <String, String>{};
  for (var i = 0; i < texts.length; i++) {
    map[texts[i]] = translations[i]['text'] ?? texts[i];
  }
  return map;
}

Map<String, dynamic> _applyTranslations(Map<String, dynamic> ex, Map<String, String> t) {
  String tr(String s) => t[s] ?? s;
  List<String> trList(List<dynamic>? list) {
    if (list == null) return [];
    return list.map((e) => e is String ? tr(e) : e.toString()).toList();
  }

  final id = ex['exerciseId'];
  return {
    'exerciseId': id,
    'name': ex['name'] is String ? tr(ex['name']) : ex['name'],
    'gifUrl': 'assets/gifs/$id.gif',
    'targetMuscles': trList(ex['targetMuscles'] as List?),
    'bodyParts': trList(ex['bodyParts'] as List?),
    'equipments': trList(ex['equipments'] as List?),
    'secondaryMuscles': trList(ex['secondaryMuscles'] as List?),
    'instructions': trList(ex['instructions'] as List?),
  };
}
