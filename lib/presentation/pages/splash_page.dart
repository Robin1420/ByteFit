import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../../services/exercise_cache_service.dart';
import 'onboarding_page.dart';
import 'main_page.dart';
import 'exercise_loading_page.dart';
import '../widgets/adaptive_icon.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final exerciseCache = ExerciseCacheService();
      
      // Cargar usuario desde storage
      await appProvider.loadUserFromStorage();
      
      // Verificar si necesita descargar ejercicios
      await exerciseCache.init();
      final hasExercises = await exerciseCache.hasExercises();
      final needsDownload = await exerciseCache.needsUpdate();
      
      print('🔍 Verificación de ejercicios:');
      print('   - Tiene ejercicios: $hasExercises');
      print('   - Necesita descarga: $needsDownload');
      
      if (needsDownload || !hasExercises) {
        print('📥 Redirigiendo a pantalla de descarga...');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ExerciseLoadingPage()),
          );
        }
        return;
      }
      
      // Navegar a la pantalla correspondiente
      await Future.delayed(const Duration(seconds: 2)); // Splash duration
      
      if (mounted) {
        if (appProvider.hasUser) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingPage()),
          );
        }
      }
    } catch (e) {
      print('Error in splash initialization: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const NutriSyncLogo(
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 20),
            Text(
              'NutriSync',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'by Bytezon',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
