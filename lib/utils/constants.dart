// Configuración segura para API Keys y constantes de la app

class AppConstants {
  // API Key de Gemini - Configurada directamente
  static const String geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  // API Key de OpenAI - No se usa más, solo Gemini
  static const String openAiApiKey = '';

  // URLs de API
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  // Constantes de la app
  static const String appName = 'NutriSync';
  static const String appVersion = '1.0.0';

  // Paths de almacenamiento
  static const String imagesDir = 'bytecal_images';

  // Mensajes de error
  static const String apiKeyNotConfigured =
      'API Key de Gemini no configurada. Ejecuta la app con:\n'
      'flutter run --dart-define=GEMINI_API_KEY=tu_api_key';

  // Validar que la API key esté configurada
  static void validateApiKey() {
    if (geminiApiKey.isEmpty) {
      throw Exception(apiKeyNotConfigured);
    }
  }
}
