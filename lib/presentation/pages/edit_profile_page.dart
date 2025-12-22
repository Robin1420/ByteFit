import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../data/repositories/user_repository.dart';
import '../../data/datasources/local_datasource.dart';
import '../../domain/entities/user.dart';
import '../providers/app_provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  String _selectedGender = 'M';
  String _selectedGoal = 'mantener';
  String? _selectedImagePath;
  final ImagePicker _picker = ImagePicker();

  bool _isSaving = false;
  late final UserRepository _userRepository;

  @override
  void initState() {
    super.initState();
    _userRepository = UserRepository(LocalDataSource());
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final user = appProvider.currentUser;

    if (user != null) {
      _nameController.text = user.nombre;
      _ageController.text = user.edad.toString();
      _weightController.text = user.peso.toString();
      _heightController.text = user.altura.toString();
      _selectedGender = user.sexo;
      _selectedImagePath = user.imagenPerfil;

      // Determinar objetivo basado en la meta calÃƒÂ³rica
      final metabolismoBasal = user.calcularMetabolismoBasal();
      if (user.metaCalorica < metabolismoBasal * 0.9) {
        _selectedGoal = 'bajar';
      } else if (user.metaCalorica > metabolismoBasal * 1.1) {
        _selectedGoal = 'subir';
      } else {
        _selectedGoal = 'mantener';
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final currentUser = appProvider.currentUser;

      if (currentUser == null) return;

      // Crear usuario temporal para calcular nueva meta
      final tempUser = User(
        id: currentUser.id,
        nombre: _nameController.text.trim(),
        edad: int.parse(_ageController.text),
        peso: double.parse(_weightController.text),
        altura: double.parse(_heightController.text),
        sexo: _selectedGender,
        metaCalorica: 0, // Se calcularÃƒÂ¡ automÃƒÂ¡ticamente
      );

      // Calcular nueva meta calÃƒÂ³rica
      final newGoal = tempUser.calcularMetaCalorica(_selectedGoal);
      final userWithGoal = tempUser.copyWith(
        metaCalorica: newGoal,
        imagenPerfil: _selectedImagePath,
      );

      // Guardar en la base de datos
      await _userRepository.saveUser(userWithGoal);

      // Actualizar en el provider
      appProvider.setUser(userWithGoal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ã‚Â¡Perfil actualizado exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar perfil: $e'),
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al tomar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImagePath = null;
    });
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('GalerÃƒÂ­a'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('CÃƒÂ¡mara'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            if (_selectedImagePath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar imagen'),
                onTap: () {
                  Navigator.pop(context);
                  _removeImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: const Color(0xFF0080F5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: Text(
              'Guardar',
              style: TextStyle(
                color: _isSaving ? Colors.grey : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto de perfil
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Foto de Perfil',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            // Imagen de perfil
                            GestureDetector(
                              onTap: _showImagePicker,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      const Color(0xFF0080F5).withOpacity(0.1),
                                  border: Border.all(
                                    color: const Color(0xFF0080F5),
                                    width: 3,
                                  ),
                                ),
                                child: _selectedImagePath != null
                                    ? ClipOval(
                                        child: Image.file(
                                          File(_selectedImagePath!),
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Color(0xFF0080F5),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Botones de acciÃƒÂ³n
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _pickImage,
                                  icon:
                                      const Icon(Icons.photo_library, size: 16),
                                  label: const Text('GalerÃƒÂ­a'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0080F5),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _takePhoto,
                                  icon: const Icon(Icons.camera_alt, size: 16),
                                  label: const Text('CÃƒÂ¡mara'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0080F5),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                ),
                                if (_selectedImagePath != null) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: _removeImage,
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    tooltip: 'Eliminar imagen',
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // InformaciÃƒÂ³n personal
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'InformaciÃƒÂ³n Personal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nombre
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa tu nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Edad
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Edad',
                          prefixIcon: Icon(Icons.cake),
                          border: OutlineInputBorder(),
                          suffixText: 'aÃƒÂ±os',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu edad';
                          }
                          final age = int.tryParse(value);
                          if (age == null || age < 10 || age > 120) {
                            return 'Edad debe estar entre 10 y 120 aÃƒÂ±os';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Peso y Altura
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Peso',
                                prefixIcon: Icon(Icons.monitor_weight),
                                border: OutlineInputBorder(),
                                suffixText: 'kg',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Peso requerido';
                                }
                                final weight = double.tryParse(value);
                                if (weight == null ||
                                    weight < 20 ||
                                    weight > 300) {
                                  return 'Peso entre 20-300 kg';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Altura',
                                prefixIcon: Icon(Icons.height),
                                border: OutlineInputBorder(),
                                suffixText: 'cm',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Altura requerida';
                                }
                                final height = double.tryParse(value);
                                if (height == null ||
                                    height < 100 ||
                                    height > 250) {
                                  return 'Altura entre 100-250 cm';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // GÃƒÂ©nero
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GÃƒÂ©nero',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Masculino'),
                              value: 'M',
                              groupValue: _selectedGender,
                              onChanged: (value) {
                                setState(() {
                                  _selectedGender = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Femenino'),
                              value: 'F',
                              groupValue: _selectedGender,
                              onChanged: (value) {
                                setState(() {
                                  _selectedGender = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Objetivo
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Objetivo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text('Bajar de peso'),
                            subtitle:
                                const Text('DÃƒÂ©ficit calÃƒÂ³rico del 20%'),
                            value: 'bajar',
                            groupValue: _selectedGoal,
                            onChanged: (value) {
                              setState(() {
                                _selectedGoal = value!;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Mantener peso'),
                            subtitle: const Text('Equilibrio calÃƒÂ³rico'),
                            value: 'mantener',
                            groupValue: _selectedGoal,
                            onChanged: (value) {
                              setState(() {
                                _selectedGoal = value!;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Subir de peso'),
                            subtitle:
                                const Text('SuperÃƒÂ¡vit calÃƒÂ³rico del 20%'),
                            value: 'subir',
                            groupValue: _selectedGoal,
                            onChanged: (value) {
                              setState(() {
                                _selectedGoal = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Vista previa de la meta calÃƒÂ³rica
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vista Previa',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPreviewCard(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // BotÃƒÂ³n de guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0080F5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                          'Guardar Cambios',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    if (_nameController.text.isEmpty ||
        _ageController.text.isEmpty ||
        _weightController.text.isEmpty ||
        _heightController.text.isEmpty) {
      return const Text(
        'Completa todos los campos para ver la vista previa',
        style: TextStyle(color: Colors.grey),
      );
    }

    try {
      final tempUser = User(
        id: 0,
        nombre: _nameController.text.trim(),
        edad: int.parse(_ageController.text),
        peso: double.parse(_weightController.text),
        altura: double.parse(_heightController.text),
        sexo: _selectedGender,
        metaCalorica: 0,
      );

      final metabolismoBasal = tempUser.calcularMetabolismoBasal();
      final metaCalorica = tempUser.calcularMetaCalorica(_selectedGoal);
      final imc =
          (tempUser.peso / ((tempUser.altura / 100) * (tempUser.altura / 100)));

      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildPreviewItem(
                    'IMC', imc.toStringAsFixed(1), Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPreviewItem(
                    'Metabolismo',
                    '${metabolismoBasal.toStringAsFixed(0)} kcal',
                    Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0080F5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: const Color(0xFF0080F5).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Text(
                  'Nueva Meta CalÃƒÂ³rica',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${metaCalorica.toStringAsFixed(0)} kcal/dÃƒÂ­a',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0080F5),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } catch (e) {
      return const Text(
        'Datos invÃƒÂ¡lidos',
        style: TextStyle(color: Colors.red),
      );
    }
  }

  Widget _buildPreviewItem(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
