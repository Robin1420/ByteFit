import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/datasources/local_datasource.dart';
import 'data/adapters/exercise_db_adapter.dart';
import 'presentation/providers/app_provider.dart';
import 'presentation/pages/splash_page.dart';
import 'i18n/i18n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('Initializing Hive...');
    await Hive.initFlutter();
    
    // Registrar adaptadores
    Hive.registerAdapter(ExerciseDbAdapter());
    
    await LocalDataSource.init();
    print('Hive initialization completed');
    
    print('Initializing translations...');
    await I18n.init();
    print('Translations initialized');
  } catch (e) {
    print('Error initializing app: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return MaterialApp(
                 title: 'NutriSync by Bytezon',
          themeMode: appProvider.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0080F5), // rgb(0, 128, 245)
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0080F5), // rgb(0, 128, 245)
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const SplashPage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}