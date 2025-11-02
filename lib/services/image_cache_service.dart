import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class ImageCacheService {
  static const String _cacheDirName = 'exercise_gifs';
  late Directory _cacheDir;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${appDir.path}/$_cacheDirName');
    
    if (!await _cacheDir.exists()) {
      await _cacheDir.create(recursive: true);
    }
    
    _isInitialized = true;
  }

  Future<String?> downloadGif(String gifUrl, String exerciseId) async {
    await init();
    
    try {
      // Verificar si ya existe localmente
      final localPath = '${_cacheDir.path}/$exerciseId.gif';
      final localFile = File(localPath);
      
      if (await localFile.exists()) {
        return localPath;
      }
      
      // Descargar el GIF
      print('📥 Descargando GIF para ejercicio $exerciseId...');
      final response = await http.get(Uri.parse(gifUrl));
      
      if (response.statusCode == 200) {
        await localFile.writeAsBytes(response.bodyBytes);
        print('✅ GIF descargado: $exerciseId');
        return localPath;
      } else {
        print('❌ Error descargando GIF $exerciseId: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error descargando GIF $exerciseId: $e');
      return null;
    }
  }

  Future<String?> getLocalGifPath(String exerciseId) async {
    await init();
    
    final localPath = '${_cacheDir.path}/$exerciseId.gif';
    final localFile = File(localPath);
    
    if (await localFile.exists()) {
      return localPath;
    }
    
    return null;
  }

  Future<void> downloadGifsInBatch(List<String> gifUrls, List<String> exerciseIds, {Function(int, int)? onProgress}) async {
    await init();
    
    print('🔄 Iniciando descarga de ${gifUrls.length} GIFs...');
    
    for (int i = 0; i < gifUrls.length; i++) {
      try {
        await downloadGif(gifUrls[i], exerciseIds[i]);
        
        if (onProgress != null) {
          onProgress(i + 1, gifUrls.length);
        }
        
        // Pequeña pausa entre descargas
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        print('❌ Error descargando GIF ${exerciseIds[i]}: $e');
      }
    }
    
    print('✅ Descarga de GIFs completada');
  }

  Future<void> clearCache() async {
    await init();
    
    if (await _cacheDir.exists()) {
      await _cacheDir.delete(recursive: true);
      await _cacheDir.create(recursive: true);
    }
  }

  Future<int> getCacheSize() async {
    await init();
    
    if (!await _cacheDir.exists()) return 0;
    
    int totalSize = 0;
    await for (final entity in _cacheDir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    
    return totalSize;
  }
}
