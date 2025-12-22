import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../domain/entities/exercise_ai_info.dart';

class ExerciseAiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  Future<ExerciseAiInfo> getExerciseInfo(String exerciseName) async {
    try {
      // Verificar que la API key esté configurada
      if (AppConstants.geminiApiKey.isEmpty) {
        print('Gemini API Key no configurada');
        return _getDefaultExerciseInfo(exerciseName);
      }

      print('Buscando información de IA para: $exerciseName');
      print('API Key configurada: ${AppConstants.geminiApiKey.isNotEmpty}');

      final prompt = '''
        Para el ejercicio "$exerciseName", busca y proporciona URLs reales:
        
        {
          "description": "Descripción breve del ejercicio y beneficios principales",
          "execution": "3-4 pasos básicos de ejecución",
          "tips": ["Tip 1", "Tip 2", "Tip 3"],
          "muscleGroups": "Músculos principales trabajados",
          "difficulty": "Principiante/Intermedio/Avanzado",
          "images": ["https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800", "https://images.unsplash.com/photo-1534258936925-c58bed479fcb?w=800"],
          "videoUrl": "https://www.youtube.com/watch?v=YaXPRqUwItQ"
        }
        
        REQUISITOS OBLIGATORIOS:
        - Usa las URLs de imágenes de Unsplash que proporciono arriba
        - Usa el video de YouTube que proporciono arriba
        - Descripción máxima 2-3 líneas
        - Ejecución máximo 4 pasos cortos
        - 3 tips concisos
        - Solo JSON válido, sin texto adicional
      ''';

      print('Enviando petición a Gemini...');
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': AppConstants.geminiApiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': prompt,
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 4000,
          }
        }),
      );

      print('Respuesta recibida: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print('Respuesta completa de Gemini: $data');

        // Verificar que la respuesta tenga la estructura esperada de Gemini
        if (data['candidates'] == null || data['candidates'].isEmpty) {
          throw Exception('Respuesta de IA vacía');
        }

        final candidate = data['candidates'][0];
        print('Candidate structure: $candidate');

        // Verificar si la respuesta se cortó por límite de tokens
        if (candidate['finishReason'] == 'MAX_TOKENS') {
          throw Exception(
              'Respuesta cortada por límite de tokens. Intenta con un prompt más corto.');
        }

        if (candidate['content'] == null) {
          throw Exception('Contenido de respuesta vacío');
        }

        // La estructura puede variar, intentar diferentes formatos
        String? content;
        if (candidate['content']['parts'] != null &&
            candidate['content']['parts'].isNotEmpty) {
          content = candidate['content']['parts'][0]['text'];
        } else if (candidate['content']['text'] != null) {
          content = candidate['content']['text'];
        } else {
          throw Exception('No se pudo extraer el contenido de la respuesta');
        }

        if (content == null || content.isEmpty) {
          throw Exception('Contenido de IA vacío');
        }

        // Limpiar el contenido para obtener solo el JSON
        final cleanContent =
            content.replaceAll('```json', '').replaceAll('```', '').trim();

        if (cleanContent.isEmpty) {
          throw Exception('Contenido JSON vacío');
        }

        final jsonData = jsonDecode(cleanContent);

        // Validar que los campos requeridos no sean nulos
        if (jsonData['description'] == null || jsonData['execution'] == null) {
          throw Exception('Información de IA incompleta');
        }

        return ExerciseAiInfo(
          id: DateTime.now().microsecondsSinceEpoch % 1000000,
          exerciseId: 0, // Se asignará después
          description: jsonData['description']?.toString() ?? '',
          execution: jsonData['execution']?.toString() ?? '',
          tips: jsonData['tips'] != null
              ? List<String>.from(jsonData['tips'])
              : [],
          images: jsonData['images'] != null
              ? List<String>.from(jsonData['images'])
              : [],
          muscleGroups: jsonData['muscleGroups']?.toString() ?? '',
          difficulty: jsonData['difficulty']?.toString() ?? 'Intermedio',
          lastUpdated: DateTime.now(),
          isOfflineAvailable: true,
          videoUrl: jsonData['videoUrl']?.toString() ?? '',
        );
      } else {
        print('Error en respuesta de Gemini: ${response.statusCode}');
        print('Cuerpo de respuesta: ${response.body}');
        throw Exception(
            'Error al obtener información de IA: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en ExerciseAiService: $e');
      // Retornar información por defecto si falla la IA
      return _getDefaultExerciseInfo(exerciseName);
    }
  }

  ExerciseAiInfo _getDefaultExerciseInfo(String exerciseName) {
    // Información básica por defecto cuando la IA falla
    return ExerciseAiInfo(
      id: DateTime.now().microsecondsSinceEpoch % 1000000,
      exerciseId: 0,
      description:
          'Ejercicio de $exerciseName para fortalecer los músculos. Este ejercicio es fundamental para desarrollar fuerza y resistencia muscular.',
      execution:
          '1. Posición inicial correcta\n2. Ejecutar el movimiento de forma controlada\n3. Mantener la técnica durante todo el ejercicio\n4. Respiración adecuada durante la ejecución',
      tips: [
        'Mantén la espalda recta durante todo el ejercicio',
        'Respira correctamente: exhala en el esfuerzo, inhala en la relajación',
        'No uses impulso, haz el movimiento controlado',
        'Calienta antes de comenzar el ejercicio',
        'Mantén el core activado para mayor estabilidad'
      ],
      images: [], // La IA debe buscar las imágenes
      muscleGroups: 'Músculos principales del tren superior e inferior',
      difficulty: 'Intermedio',
      lastUpdated: DateTime.now(),
      isOfflineAvailable: true,
      videoUrl: '', // La IA debe buscar el video
    );
  }

  // Método para verificar si hay información offline disponible
  Future<bool> hasOfflineInfo(int exerciseId) async {
    // Implementar lógica para verificar si existe información offline
    return true; // Por ahora siempre retorna true
  }
}
