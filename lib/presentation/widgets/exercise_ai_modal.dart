import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../domain/entities/exercise_ai_info.dart';

class ExerciseAiModal extends StatefulWidget {
  final ExerciseAiInfo aiInfo;
  final String exerciseName;
  final Function(ExerciseAiInfo)? onRefresh;

  const ExerciseAiModal({
    super.key,
    required this.aiInfo,
    required this.exerciseName,
    this.onRefresh,
  });

  @override
  State<ExerciseAiModal> createState() => _ExerciseAiModalState();
}

class _ExerciseAiModalState extends State<ExerciseAiModal> {
  late YoutubePlayerController _controller;
  bool _isVideoLoaded = false;
  bool _isRefreshing = false;
  late ExerciseAiInfo _currentAiInfo;

  @override
  void initState() {
    super.initState();
    _currentAiInfo = widget.aiInfo;
    _initializeVideo();
  }

  void _initializeVideo() {
    if (_currentAiInfo.videoUrl.isNotEmpty) {
      final videoId = YoutubePlayer.convertUrlToId(_currentAiInfo.videoUrl);
      if (videoId != null) {
        _controller = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            isLive: false,
            forceHD: false,
            enableCaption: true,
            showLiveFullscreenButton: true,
          ),
        );
        _isVideoLoaded = true;
      }
    }
  }

  @override
  void dispose() {
    if (_isVideoLoaded) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _refreshContent() async {
    if (widget.onRefresh == null) return;
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      // Llamar al callback de recarga que manejará la lógica real
      final updatedAiInfo = await widget.onRefresh!(_currentAiInfo);
      
      // Actualizar la información local
      setState(() {
        _currentAiInfo = updatedAiInfo;
        // Reinicializar el video si cambió
        if (_isVideoLoaded) {
          _controller.dispose();
        }
        _initializeVideo();
      });
      
      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guía del ejercicio actualizada'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Mostrar mensaje de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0080F5), Color(0xFF0066CC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Guía del Ejercicio',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isRefreshing ? null : () => _refreshContent(),
                  icon: _isRefreshing 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                  tooltip: 'Recargar guía',
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                         // Dificultad y grupos musculares
                         Row(
                           children: [
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                               decoration: BoxDecoration(
                                 color: _getDifficultyColor(_currentAiInfo.difficulty).withOpacity(0.1),
                                 borderRadius: BorderRadius.circular(16),
                                 border: Border.all(
                                   color: _getDifficultyColor(_currentAiInfo.difficulty).withOpacity(0.3),
                                 ),
                               ),
                               child: Text(
                                 _currentAiInfo.difficulty,
                                 style: TextStyle(
                                   fontSize: 12,
                                   color: _getDifficultyColor(_currentAiInfo.difficulty),
                                   fontWeight: FontWeight.w600,
                                 ),
                               ),
                             ),
                             const SizedBox(width: 12),
                             Expanded(
                               child: Text(
                                 _currentAiInfo.muscleGroups,
                                 style: TextStyle(
                                   fontSize: 14,
                                   color: Colors.grey[600],
                                 ),
                               ),
                             ),
                           ],
                         ),
                  const SizedBox(height: 20),
                  
                  // Descripción
                  _buildSection(
                    'Descripción',
                    Icons.info_outline,
                    _currentAiInfo.description,
                  ),
                  const SizedBox(height: 20),

                  // Ejecución
                  _buildSection(
                    'Cómo Ejecutar',
                    Icons.play_circle_outline,
                    _currentAiInfo.execution,
                  ),
                  const SizedBox(height: 20),

                  // Tips
                  if (_currentAiInfo.tips.isNotEmpty) ...[
                    _buildTipsSection(),
                    const SizedBox(height: 20),
                  ],

                  // Imágenes (solo si hay imágenes)
                  if (_currentAiInfo.images.isNotEmpty) ...[
                    _buildImagesSection(),
                    const SizedBox(height: 20),
                  ],

                  // Video de YouTube
                  if (_currentAiInfo.videoUrl.isNotEmpty && _isVideoLoaded) ...[
                    _buildVideoSection(),
                    const SizedBox(height: 20),
                  ],

                  // Footer
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF0080F5), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1A1A1A),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Color(0xFF0080F5), size: 20),
            SizedBox(width: 8),
            Text(
              'Tips Importantes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
               ..._currentAiInfo.tips.map((tip) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2, right: 12),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  tip,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.image, color: Color(0xFF0080F5), size: 20),
            SizedBox(width: 8),
            Text(
              'Imágenes de Referencia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
                 itemCount: _currentAiInfo.images.length,
            itemBuilder: (context, index) {
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                 child: Image.network(
                   _currentAiInfo.images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Imagen no disponible', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.play_circle_filled, color: Color(0xFF0080F5), size: 20),
            SizedBox(width: 8),
            Text(
              'Video Tutorial',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: const Color(0xFF0080F5),
              onReady: () {
                // Video está listo para reproducir
              },
              onEnded: (data) {
                // Video terminó
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.update,
            size: 16,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 8),
                 Text(
                   'Actualizado: ${_formatDate(_currentAiInfo.lastUpdated)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          const Spacer(),
                 if (_currentAiInfo.isOfflineAvailable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.offline_bolt,
                    size: 12,
                    color: Colors.green[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Disponible offline',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'principiante':
        return Colors.green;
      case 'intermedio':
        return Colors.orange;
      case 'avanzado':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m atrás';
    } else {
      return 'Ahora';
    }
  }

}
