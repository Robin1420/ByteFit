import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class GeminiService {
  final String apiKey;

  GeminiService() : apiKey = AppConstants.geminiApiKey {
    // Validar que la API key esté configurada al crear el servicio
    if (apiKey.isEmpty) {
      throw Exception(AppConstants.apiKeyNotConfigured);
    }
  }

  Future<Map<String, dynamic>> analyzeFoodImage(File imageFile) async {
    try {
      final base64Image = await _convertImageToBase64(imageFile);
      
      final response = await http.post(
        Uri.parse('${AppConstants.geminiBaseUrl}/models/gemini-pro-vision:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'Analiza esta imagen de comida y estima las calorías. '
                          'Responde SOLO con un JSON válido: {\"nombre\": \"nombre del alimento\", \"calorias\": número}. '
                          'Sé preciso en la estimación calórica basándote en el tamaño y tipo de alimento.'
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
        throw Exception('Error de API Gemini: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al analizar imagen de comida: $e');
    }
  }

  Future<Map<String, dynamic>> analyzeExerciseImage(File imageFile) async {
    try {
      final base64Image = await _convertImageToBase64(imageFile);
      
      final response = await http.post(
        Uri.parse('${AppConstants.geminiBaseUrl}/models/gemini-pro-vision:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'Analiza esta imagen de ejercicio físico y estima las calorías quemadas. '
                          'Responde SOLO con un JSON válido: {\"tipo\": \"tipo de ejercicio\", \"calorias_quemadas\": número}. '
                          'Considera intensidad y duración aproximada de 30 minutos.'
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
        throw Exception('Error de API Gemini: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al analizar imagen de ejercicio: $e');
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
      // Limpiar respuesta y extraer JSON
      final cleanedText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      
      // Buscar objeto JSON
      final jsonMatch = RegExp(r'\{.*\}').firstMatch(cleanedText);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        return json.decode(jsonString);
      }
      
      // Intentar parsear directamente
      return json.decode(cleanedText);
    } catch (e) {
      throw Exception('Error al parsear respuesta de Gemini: $e. Respuesta: $responseText');
    }
  }

  // Método para verificar conexión con Gemini
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
}
