import 'package:flutter/material.dart';
import '../../services/exercise_cache_service.dart';
import 'main_page.dart';
import '../widgets/adaptive_icon.dart';

class ExerciseLoadingPage extends StatefulWidget {
  const ExerciseLoadingPage({super.key});

  @override
  State<ExerciseLoadingPage> createState() => _ExerciseLoadingPageState();
}

class _ExerciseLoadingPageState extends State<ExerciseLoadingPage> {
  final ExerciseCacheService _cacheService = ExerciseCacheService();
  int _downloadedExercises = 0;
  int _totalExercises = 0;
  String _statusMessage = 'Iniciando descarga...';
  bool _isDownloading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      setState(() {
        _isDownloading = true;
        _hasError = false;
        _statusMessage = 'Obteniendo ejercicios...';
      });

      await _cacheService.init();
      
      setState(() {
        _statusMessage = 'Descargando ejercicios de ExerciseDB...';
      });

      await _cacheService.downloadAllExercises(
        onProgress: (downloaded, total) {
          setState(() {
            _downloadedExercises = downloaded;
            _totalExercises = total;
            _statusMessage = 'Descargando ejercicio $downloaded de $total...';
          });
        },
      );

      setState(() {
        _statusMessage = '¡Descarga completada!';
      });

      // Esperar un momento antes de navegar
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      }
      
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error al descargar ejercicios: $e';
        _isDownloading = false;
      });
    }
  }

  Future<void> _retryDownload() async {
    setState(() {
      _hasError = false;
      _downloadedExercises = 0;
      _totalExercises = 0;
    });
    await _startDownload();
  }

  void _navigateToMain() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0080F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo o icono
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const NutriSyncLogo(
                  width: 100,
                  height: 100,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Título
              const Text(
                'NutriSync',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'Obteniendo ejercicios',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Indicador de progreso
              if (_isDownloading && !_hasError) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // GIF del corredor que sigue el progreso
                      Container(
                        height: 60,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            // Barra de progreso de fondo
                            Container(
                              height: 8,
                              margin: const EdgeInsets.only(top: 26),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            // Barra de progreso activa
                            Container(
                              height: 8,
                              margin: const EdgeInsets.only(top: 26),
                              width: _totalExercises > 0 
                                ? (MediaQuery.of(context).size.width - 40) * (_downloadedExercises / _totalExercises)
                                : 0,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            // GIF del corredor que se mueve por encima de la barra
                            Positioned(
                              left: _totalExercises > 0 
                                ? (MediaQuery.of(context).size.width - 40) * (_downloadedExercises / _totalExercises) - 30
                                : -30,
                              top: 0,
                              child: Container(
                                width: 60,
                                height: 60,
                                child: Image.asset(
                                  'assets/Gif/to-run-5304_512.gif',
                                  color: Colors.white,
                                  colorBlendMode: BlendMode.srcIn,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Porcentaje de progreso
                      Text(
                        _totalExercises > 0 
                          ? '${((_downloadedExercises / _totalExercises) * 100).toStringAsFixed(1)}%'
                          : '0%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Contador de ejercicios
                      Text(
                        '$_downloadedExercises / $_totalExercises ejercicios',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Mensaje de estado
                      Text(
                        _statusMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(146, 155, 155, 155),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Mensaje de error
              if (_hasError) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[600],
                        size: 48,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        'Error de descarga',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[600],
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red[600],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _retryDownload,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _navigateToMain,
                            icon: const Icon(Icons.skip_next),
                            label: const Text('Continuar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 40),
              
              // Información adicional
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.white70,
                      size: 24,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    const Text(
                      'Esta descarga solo ocurre la primera vez',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    const Text(
                      'Los ejercicios se guardan localmente para uso offline',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
