import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/repositories/meal_repository.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/datasources/local_datasource.dart';
import '../providers/app_provider.dart';
import 'history_page.dart';
import '../widgets/adaptive_icon.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final MealRepository _mealRepository;
  late final ExerciseRepository _exerciseRepository;
  late final UserRepository _userRepository;
  
  bool _isExporting = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _mealRepository = MealRepository(LocalDataSource());
    _exerciseRepository = ExerciseRepository(LocalDataSource());
    _userRepository = UserRepository(LocalDataSource());
  }

  Future<void> _exportToJSON() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Obtener todos los datos
      final user = await _userRepository.getUser();
      final meals = await _mealRepository.getAllMeals();
      final exercises = await _exerciseRepository.getAllExercises();

      // Crear estructura de datos
      final exportData = {
        'user': user?.toJson(),
        'meals': meals.map((meal) => meal.toJson()).toList(),
        'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
      };

      // Convertir a JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Guardar archivo
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/bytecal_export_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Datos exportados a: ${file.path}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Copiar ruta',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: file.path));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ruta copiada al portapapeles')),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _exportToCSV() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final meals = await _mealRepository.getAllMeals();
      final exercises = await _exerciseRepository.getAllExercises();

      // Crear CSV de comidas
      StringBuffer csvContent = StringBuffer();
      csvContent.writeln('Tipo,Fecha,Nombre,Calorías,Imagen');
      
      for (final meal in meals) {
        csvContent.writeln('Comida,${meal.fecha.toIso8601String()},${meal.nombre},${meal.calorias},${meal.imagenPath}');
      }
      
      for (final exercise in exercises) {
        csvContent.writeln('Ejercicio,${exercise.fecha.toIso8601String()},${exercise.tipo},${exercise.caloriasQuemadas},${exercise.imagenPath}');
      }

      // Guardar archivo CSV
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/bytecal_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvContent.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Datos exportados a CSV: ${file.path}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Copiar ruta',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: file.path));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ruta copiada al portapapeles')),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Eliminar todos los datos'),
        content: const Text(
          'Esta acción eliminará TODOS los datos de la aplicación:\n\n'
          '• Perfil de usuario\n'
          '• Historial de comidas\n'
          '• Historial de ejercicios\n'
          '• Todas las imágenes\n\n'
          '¿Estás seguro? Esta acción NO se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar todo'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      // Eliminar todos los datos
      await _mealRepository.deleteAllMeals();
      await _exerciseRepository.deleteAllExercises();
      await _userRepository.deleteUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todos los datos han sido eliminados'),
            backgroundColor: Colors.orange,
          ),
        );

        // Navegar de vuelta al onboarding
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/onboarding',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: const Color(0xFF0080F5),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Sección de exportación
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📤 Exportar Datos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Exporta todos tus datos para respaldo o análisis externo.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isExporting ? null : _exportToJSON,
                          icon: const Icon(Icons.code),
                          label: const Text('JSON'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isExporting ? null : _exportToCSV,
                          icon: const Icon(Icons.table_chart),
                          label: const Text('CSV'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isExporting) ...[
                    const SizedBox(height: 12),
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sección de tema
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎨 Apariencia',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<AppProvider>(
                    builder: (context, appProvider, child) {
                      return SwitchListTile(
                        title: const Text('Modo oscuro'),
                        subtitle: const Text('Activar tema oscuro'),
                        value: appProvider.themeMode == ThemeMode.dark,
                        onChanged: (value) {
                          appProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                        },
                        secondary: const Icon(Icons.dark_mode),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sección de datos
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🗑️ Gestión de Datos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gestiona tus datos almacenados localmente.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.history, color: Colors.blue),
                    title: const Text('Ver historial'),
                    subtitle: const Text('Comidas y ejercicios registrados'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HistoryPage()),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Eliminar todos los datos'),
                    subtitle: const Text('⚠️ Acción irreversible'),
                    trailing: _isDeleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward_ios),
                    onTap: _isDeleting ? null : _deleteAllData,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Información de la app
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ℹ️ Información',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const ListTile(
                    leading: Icon(Icons.info, color: Colors.blue),
                    title: Text('NutriSync by Bytezon'),
                    subtitle: Text('Versión 1.0.0'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.security, color: Colors.green),
                    title: Text('Privacidad'),
                    subtitle: Text('Todos los datos se almacenan localmente'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.psychology, color: Colors.purple),
                    title: Text('IA Gemini'),
                    subtitle: Text('Análisis de imágenes con Google AI'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
