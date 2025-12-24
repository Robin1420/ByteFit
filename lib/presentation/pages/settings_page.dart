import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import 'profile_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        top: true,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            Text('Configuraciones',
                style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            _settingsCard(
              scheme,
              title: 'Tema',
              subtitle: 'Claro / Oscuro',
              icon: Icons.brightness_6,
              trailing: Switch(
                value:
                    Theme.of(context).brightness == Brightness.dark,
                onChanged: (v) {
                  final appProvider =
                      Provider.of<AppProvider>(context, listen: false);
                  appProvider.themeMode =
                      v ? ThemeMode.dark : ThemeMode.light;
                },
              ),
            ),
            _settingsCard(
              scheme,
              title: 'Idioma',
              subtitle: 'Español',
              icon: Icons.language,
            ),
            _settingsCard(
              scheme,
              title: 'Notificaciones',
              subtitle: 'Gestiona tus recordatorios',
              icon: Icons.notifications,
            ),
            _settingsCard(
              scheme,
              title: 'Mi perfil',
              subtitle: 'Editar foto, nombre y datos',
              icon: Icons.person,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),
            _settingsCard(
              scheme,
              title: 'Privacidad',
              subtitle: 'Exportar o eliminar datos',
              icon: Icons.lock,
            ),
            _settingsCard(
              scheme,
              title: 'Acerca de',
              subtitle: 'Versión y soporte',
              icon: Icons.info_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsCard(ColorScheme scheme,
      {required String title,
      required String subtitle,
      required IconData icon,
      VoidCallback? onTap,
      Widget? trailing}) {
    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.primary.withOpacity(0.1),
            child: Icon(icon, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: scheme.onSurface, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: scheme.onSurface.withOpacity(0.7),
                        fontSize: 12)),
              ],
            ),
          ),
          trailing ??
              Icon(Icons.chevron_right,
                  color: scheme.onSurface.withOpacity(0.6)),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: card,
      );
    }
    return card;
  }
}
