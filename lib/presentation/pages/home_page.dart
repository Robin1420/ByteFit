import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        backgroundColor: const Color(0xFF0080F5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode),
            onPressed: () {
              final appProvider =
                  Provider.of<AppProvider>(context, listen: false);
              appProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final user = appProvider.currentUser;

          if (user == null) {
            return const Center(
              child: Text('No hay usuario registrado'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Saludo
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ãƒâ€šÃ‚Â¡Hola, ${user.nombre}!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tu meta calÃƒÆ’Ã‚Â³rica diaria: ${user.metaCalorica.toStringAsFixed(0)} kcal',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // InformaciÃƒÆ’Ã‚Â³n del usuario
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tu Perfil',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Edad', '${user.edad} aÃƒÆ’Ã‚Â±os'),
                        _buildInfoRow('Peso', '${user.peso} kg'),
                        _buildInfoRow('Altura', '${user.altura} cm'),
                        _buildInfoRow('GÃƒÆ’Ã‚Â©nero',
                            user.sexo == 'M' ? 'Masculino' : 'Femenino'),
                        _buildInfoRow('Meta calÃƒÆ’Ã‚Â³rica',
                            '${user.metaCalorica.toStringAsFixed(0)} kcal/dÃƒÆ’Ã‚Â­a'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Mensaje de bienvenida
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 48,
                          color: const Color(0xFF0080F5),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Ãƒâ€šÃ‚Â¡Bienvenido a NutriSync!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Usa la barra de navegaciÃƒÆ’Ã‚Â³n inferior para acceder a todas las funcionalidades de la app.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }
}
