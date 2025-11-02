import 'dart:convert';
import 'package:http/http.dart' as http;

class ExerciseDbService {
  static const String _baseUrl = 'https://www.exercisedb.dev/api/v1';
  
  // Obtener lista de ejercicios con paginación
  Future<ExerciseDbResponse> getExercises({
    int offset = 0,
    int limit = 20,
    String? sortBy,
    String? sortOrder = 'asc',
  }) async {
    try {
      final queryParams = {
        'offset': offset.toString(),
        'limit': limit.toString(),
        if (sortBy != null) 'sortBy': sortBy,
        'sortOrder': sortOrder,
      };
      
      final uri = Uri.parse('$_baseUrl/exercises').replace(
        queryParameters: queryParams,
      );
      
      print('Obteniendo ejercicios de ExerciseDB: $uri');
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExerciseDbResponse.fromJson(data);
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit excedido. Demasiadas peticiones. Código: ${response.statusCode}');
      } else {
        throw Exception('Error al obtener ejercicios: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en ExerciseDbService: $e');
      rethrow;
    }
  }
  
  // Obtener ejercicio específico por ID
  Future<ExerciseDbExercise> getExerciseById(String exerciseId) async {
    try {
      final uri = Uri.parse('$_baseUrl/exercises/$exerciseId');
      
      print('Obteniendo ejercicio específico: $exerciseId');
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExerciseDbExercise.fromJson(data);
      } else {
        throw Exception('Error al obtener ejercicio: ${response.statusCode}');
      }
    } catch (e) {
      print('Error obteniendo ejercicio específico: $e');
      rethrow;
    }
  }
  
  // Buscar ejercicios por nombre
  Future<ExerciseDbResponse> searchExercises(String query) async {
    try {
      final uri = Uri.parse('$_baseUrl/exercises').replace(
        queryParameters: {
          'name': query,
          'limit': '50',
        },
      );
      
      print('Buscando ejercicios: $query');
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExerciseDbResponse.fromJson(data);
      } else {
        throw Exception('Error al buscar ejercicios: ${response.statusCode}');
      }
    } catch (e) {
      print('Error buscando ejercicios: $e');
      rethrow;
    }
  }
}

// Modelos de datos para ExerciseDB
class ExerciseDbResponse {
  final bool success;
  final ExerciseDbMetadata metadata;
  final List<ExerciseDbExercise> data;

  ExerciseDbResponse({
    required this.success,
    required this.metadata,
    required this.data,
  });

  factory ExerciseDbResponse.fromJson(Map<String, dynamic> json) {
    return ExerciseDbResponse(
      success: json['success'] ?? false,
      metadata: ExerciseDbMetadata.fromJson(json['metadata'] ?? {}),
      data: (json['data'] as List<dynamic>?)
          ?.map((exercise) => ExerciseDbExercise.fromJson(exercise))
          .toList() ?? [],
    );
  }
}

class ExerciseDbMetadata {
  final int totalPages;
  final int totalExercises;
  final int currentPage;
  final String? previousPage;
  final String? nextPage;

  ExerciseDbMetadata({
    required this.totalPages,
    required this.totalExercises,
    required this.currentPage,
    this.previousPage,
    this.nextPage,
  });

  factory ExerciseDbMetadata.fromJson(Map<String, dynamic> json) {
    return ExerciseDbMetadata(
      totalPages: json['totalPages'] ?? 0,
      totalExercises: json['totalExercises'] ?? 0,
      currentPage: json['currentPage'] ?? 1,
      previousPage: json['previousPage'],
      nextPage: json['nextPage'],
    );
  }
}

class ExerciseDbExercise {
  final String exerciseId;
  final String name;
  final String gifUrl;
  final List<String> targetMuscles;
  final List<String> bodyParts;
  final List<String> equipments;
  final List<String> secondaryMuscles;
  final List<String> instructions;

  ExerciseDbExercise({
    required this.exerciseId,
    required this.name,
    required this.gifUrl,
    required this.targetMuscles,
    required this.bodyParts,
    required this.equipments,
    required this.secondaryMuscles,
    required this.instructions,
  });

  factory ExerciseDbExercise.fromJson(Map<String, dynamic> json) {
    return ExerciseDbExercise(
      exerciseId: json['exerciseId'] ?? '',
      name: json['name'] ?? '',
      gifUrl: json['gifUrl'] ?? '',
      targetMuscles: (json['targetMuscles'] as List<dynamic>?)
          ?.map((muscle) => muscle.toString())
          .toList() ?? [],
      bodyParts: (json['bodyParts'] as List<dynamic>?)
          ?.map((part) => part.toString())
          .toList() ?? [],
      equipments: (json['equipments'] as List<dynamic>?)
          ?.map((equipment) => equipment.toString())
          .toList() ?? [],
      secondaryMuscles: (json['secondaryMuscles'] as List<dynamic>?)
          ?.map((muscle) => muscle.toString())
          .toList() ?? [],
      instructions: (json['instructions'] as List<dynamic>?)
          ?.map((instruction) => instruction.toString())
          .toList() ?? [],
    );
  }

  // Método para obtener todos los músculos (principales + secundarios)
  List<String> getAllMuscles() {
    return [...targetMuscles, ...secondaryMuscles];
  }

  // Método para obtener descripción resumida
  String getShortDescription() {
    if (instructions.isNotEmpty) {
      return instructions.first.replaceAll('Step:1 ', '');
    }
    return 'Ejercicio de ${targetMuscles.join(', ')}';
  }
}
