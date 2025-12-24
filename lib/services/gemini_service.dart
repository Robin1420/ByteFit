import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class GeminiService {
  final String apiKey;
  List<String>? _availableModels;

  GeminiService() : apiKey = AppConstants.geminiApiKey {
    if (apiKey.isEmpty) {
      throw Exception(AppConstants.apiKeyNotConfigured);
    }
  }

  Future<Map<String, dynamic>> analyzeFoodImage(File imageFile) async {
    try {
      final base64Image = await _convertImageToBase64(imageFile);

      final response = await http.post(
        Uri.parse(
            '${AppConstants.geminiBaseUrl}/models/gemini-pro-vision:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      'Analiza esta imagen de comida y estima las calorías. Responde SOLO con un JSON válido: {"nombre": "nombre del alimento", "calorias": número}. Sé preciso en la estimación calórica basándote en el tamaño y tipo de alimento.'
                },
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 200,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['candidates'] == null || data['candidates'].isEmpty) {
          throw Exception('No se recibió respuesta válida de Gemini');
        }
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        return _parseGeminiResponse(text);
      } else {
        throw Exception(
            'Error de API Gemini: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al analizar imagen de comida: $e');
    }
  }

  Future<Map<String, dynamic>> analyzeExerciseImage(File imageFile) async {
    try {
      final base64Image = await _convertImageToBase64(imageFile);

      final response = await http.post(
        Uri.parse(
            '${AppConstants.geminiBaseUrl}/models/gemini-pro-vision:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      'Analiza esta imagen de ejercicio físico y estima las calorías quemadas. Responde SOLO con un JSON válido: {"tipo": "tipo de ejercicio", "calorias_quemadas": número}. Considera intensidad y duración aproximada de 30 minutos.'
                },
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 200,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['candidates'] == null || data['candidates'].isEmpty) {
          throw Exception('No se recibió respuesta válida de Gemini');
        }
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        return _parseGeminiResponse(text);
      } else {
        throw Exception(
            'Error de API Gemini: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al analizar imagen de ejercicio: $e');
    }
  }

  Future<String> askAssistant(
    String prompt, {
    List<Map<String, String>> history = const [],
    String userContext = '',
  }) async {
    // Descubrir modelos disponibles una vez
    _availableModels ??= await _listTextModels();
    final models = _availableModels!;

    Exception? lastError;
    for (final model in models) {
      print('🔎 Intentando modelo Gemini: $model');
      try {
        final response = await http.post(
          Uri.parse(
              '${AppConstants.geminiBaseUrl}/models/$model:generateContent?key=$apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'contents': [
              {
                'parts': [
                  {
                    'text':
                        'Eres un coach de fitness y nutrición. Responde en español de forma breve y estructurada: usa viñetas con guiones (-) o párrafos cortos, máximo 5 puntos, sin markdown ni **, y solo 1 emoji si aporta claridad. Incluye números concretos cuando apliquen. Contexto del usuario: $userContext. Historia: ${_historyToText(history)}. Pregunta actual: $prompt'
                  }
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.4,
              'maxOutputTokens': 256,
            }
          }),
        );

        if (response.statusCode == 200) {
          print('✅ Gemini respuesta 200 con $model');
          final data = json.decode(response.body);
          if (data['candidates'] == null || data['candidates'].isEmpty) {
            throw Exception('Respuesta vacía de Gemini');
          }
          final text = data['candidates'][0]['content']['parts'][0]['text'];
          return text?.trim() ?? 'Sin respuesta';
        } else {
          print(
              '⚠️ Error de API Gemini (${response.statusCode}) con $model: ${response.body}');
          lastError = Exception(
              'Error de API Gemini (${response.statusCode}) con $model: ${response.body}');
          continue;
        }
      } catch (e) {
        print('⚠️ Excepción con modelo $model: $e');
        lastError = Exception('Error al consultar Gemini con $model: $e');
        continue;
      }
    }
    throw lastError ??
        Exception('No se pudo obtener respuesta de Gemini con los modelos probados.');
  }

  Future<List<String>> _listTextModels() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.geminiBaseUrl}/models?key=$apiKey'),
      );
      if (response.statusCode != 200) {
        print('⚠️ Error listando modelos Gemini: ${response.body}');
        return [
          // fallback a modelos comunes
          'gemini-1.5-flash-latest',
          'gemini-1.5-flash',
        ];
      }
      final data = json.decode(response.body) as Map<String, dynamic>;
      final List<dynamic> models = data['models'] ?? [];
      final filtered = models
          .where((m) =>
              (m['supportedGenerationMethods'] as List<dynamic>?)
                      ?.contains('generateContent') ==
                  true)
          .map((m) => m['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .map((name) =>
              name.startsWith('models/') ? name.substring(7) : name) // limpiar prefijo
          .toSet() // evitar duplicados
          .toList()
        ..sort((a, b) => a.contains('flash') ? -1 : 1);
      if (filtered.isEmpty) {
        return [
          'gemini-1.5-flash-latest',
          'gemini-1.5-flash',
        ];
      }
      return filtered;
    } catch (e) {
      print('⚠️ Excepción listando modelos: $e');
      return [
        'gemini-1.5-flash-latest',
        'gemini-1.5-flash',
      ];
    }
  }

  Future<String> _convertImageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      throw Exception('Error al procesar imagen: $e');
    }
  }

  Map<String, dynamic> _parseGeminiResponse(String responseText) {
    try {
      final cleanedText =
          responseText.replaceAll('```json', '').replaceAll('```', '').trim();

      final jsonMatch = RegExp(r'\{.*\}').firstMatch(cleanedText);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        return json.decode(jsonString);
      }
      return json.decode(cleanedText);
    } catch (e) {
      throw Exception(
          'Error al parsear respuesta de Gemini: $e. Respuesta: $responseText');
    }
  }

  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.geminiBaseUrl}/models?key=$apiKey'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  String _historyToText(List<Map<String, String>> history) {
    if (history.isEmpty) return '';
    final buffer = StringBuffer();
    for (final item in history) {
      final role = item['role'] ?? 'user';
      final text = item['text'] ?? '';
      buffer.writeln('$role: $text');
    }
    return buffer.toString();
  }
}
