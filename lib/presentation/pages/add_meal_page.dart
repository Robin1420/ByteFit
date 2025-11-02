import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/gemini_service.dart';
import '../../data/repositories/meal_repository.dart';
import '../../data/datasources/local_datasource.dart';
import '../../domain/entities/meal.dart';

class AddMealPage extends StatefulWidget {
  const AddMealPage({super.key});

  @override
  State<AddMealPage> createState() => _AddMealPageState();
}

class _AddMealPageState extends State<AddMealPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  
  File? _selectedImage;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  
  final ImagePicker _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();
  late final MealRepository _mealRepository;

  @override
  void initState() {
    super.initState();
    _mealRepository = MealRepository(LocalDataSource());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await _geminiService.analyzeFoodImage(_selectedImage!);
      
      setState(() {
        _nameController.text = result['nombre'] ?? '';
        _caloriesController.text = result['calorias']?.toString() ?? '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Análisis completado! Revisa y ajusta los datos si es necesario.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al analizar imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Generar ID único más pequeño
      final now = DateTime.now();
      final mealId = now.microsecondsSinceEpoch % 1000000; // ID de 6 dígitos
      
      final meal = Meal(
        id: mealId,
        fecha: DateTime.now(),
        nombre: _nameController.text.trim(),
        calorias: double.parse(_caloriesController.text),
        imagenPath: _selectedImage?.path ?? '',
      );

      await _mealRepository.saveMeal(meal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Comida guardada exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar comida: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Comida'),
        backgroundColor: const Color(0xFF0080F5),
        foregroundColor: Colors.white,
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              onPressed: _isAnalyzing ? null : _analyzeImage,
              tooltip: 'Analizar con IA',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagen seleccionada
              if (_selectedImage != null) ...[
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Botón de análisis IA
                ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _analyzeImage,
                  icon: _isAnalyzing 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(_isAnalyzing ? 'Analizando...' : 'Analizar con IA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0080F5),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Botones para seleccionar imagen
              if (_selectedImage == null) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Tomar Foto'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galería'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Nombre del alimento
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del alimento',
                  prefixIcon: Icon(Icons.restaurant),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa el nombre del alimento';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Calorías
              TextFormField(
                controller: _caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Calorías',
                  prefixIcon: Icon(Icons.local_fire_department),
                  border: OutlineInputBorder(),
                  suffixText: 'kcal',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa las calorías';
                  }
                  final calories = double.tryParse(value);
                  if (calories == null || calories < 0 || calories > 5000) {
                    return 'Calorías deben estar entre 0 y 5000';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Botón de guardar
              ElevatedButton(
                onPressed: _isSaving ? null : _saveMeal,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF0080F5),
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Guardar Comida',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
