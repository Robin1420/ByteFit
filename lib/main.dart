import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/datasources/local_datasource.dart';
import 'data/adapters/exercise_db_adapter.dart';
import 'data/adapters/translation_cache_adapter.dart';
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
    Hive.registerAdapter(TranslationCacheAdapter());

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
        // Paleta principal: celeste brillante para dar mÃ¡s energÃ­a al tema
        const primary = Color(0xFF0080F5);
        const surface = Color(0xFFF4FAFF);
        final baseText = ThemeData.light().textTheme;

        ThemeData buildTheme(Brightness brightness) {
          final isDark = brightness == Brightness.dark;
          final scheme = ColorScheme.fromSeed(
            seedColor: primary,
            brightness: brightness,
            surface: isDark ? const Color(0xFF0F172A) : surface,
            background: isDark ? const Color(0xFF0B1220) : surface,
          ).copyWith(
            primary: primary,
            secondary: primary,
            primaryContainer: brightness == Brightness.dark
                ? const Color(0xFF0A4D9E)
                : const Color(0xFFD6EAFF),
            onPrimary: Colors.white,
          );

          return ThemeData(
            colorScheme: scheme,
            brightness: brightness,
            useMaterial3: true,
            scaffoldBackgroundColor: scheme.background,
            iconTheme: IconThemeData(color: scheme.primary),
            primaryIconTheme: IconThemeData(color: scheme.primary),
            cardTheme: CardThemeData(
              color: scheme.surface,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(0),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: scheme.surface,
              elevation: 0,
              centerTitle: false,
              foregroundColor: scheme.onSurface,
              titleTextStyle: baseText.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: scheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            checkboxTheme: CheckboxThemeData(
              fillColor:
                  MaterialStateProperty.resolveWith((_) => scheme.primary),
              checkColor:
                  MaterialStateProperty.resolveWith((_) => Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            radioTheme: RadioThemeData(
              fillColor:
                  MaterialStateProperty.resolveWith((_) => scheme.primary),
            ),
            switchTheme: SwitchThemeData(
              thumbColor:
                  MaterialStateProperty.resolveWith((_) => scheme.primary),
              trackColor: MaterialStateProperty.resolveWith(
                  (_) => scheme.primary.withOpacity(0.35)),
            ),
            progressIndicatorTheme: ProgressIndicatorThemeData(
              color: scheme.primary,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: isDark ? scheme.surfaceVariant : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: scheme.outline.withOpacity(0.4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: scheme.outline.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primary, width: 1.4),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            chipTheme: ChipThemeData(
              backgroundColor: scheme.primary.withOpacity(0.08),
              selectedColor: scheme.primary.withOpacity(0.16),
              labelStyle: baseText.bodyMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            listTileTheme: ListTileThemeData(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            visualDensity: VisualDensity.adaptivePlatformDensity,
          );
        }

        return MaterialApp(
          title: 'NutriSync by Bytezon',
          themeMode: appProvider.themeMode,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          home: const SplashPage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
