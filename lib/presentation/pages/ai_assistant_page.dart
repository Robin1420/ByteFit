import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import '../providers/app_provider.dart';
import '../../services/gemini_service.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final TextEditingController _controller = TextEditingController();
  final GeminiService _gemini = GeminiService();
  final List<_ChatMessage> _messages = [];
  bool _sending = false;
  late AppProvider _appProvider;

  @override
  Widget build(BuildContext context) {
    _appProvider = Provider.of<AppProvider>(context, listen: false);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoAsset = isDark
        ? 'assets/icons/ICONNutriSyncBlack.png'
        : 'assets/icons/ICONNutriSyncDrack.png';

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  logoAsset,
                  width: 72,
                  height: 72,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'NutriSync AI',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Haz preguntas sobre ejercicios, alimentación o cómo usar la app.',
                style: TextStyle(
                  color: scheme.onSurface.withOpacity(0.7),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceVariant.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _messages.isEmpty
                      ? const Text(
                          'La conversación aparecerá aquí...',
                          style: TextStyle(fontSize: 14),
                        )
                      : ListView.builder(
                          reverse: true,
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages.reversed.toList()[index];
                            final isUser = msg.isUser;
                            final bubble = Container(
                              constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? scheme.primary.withOpacity(0.12)
                                    : scheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: scheme.outline.withOpacity(0.08)),
                              ),
                              child: Text(
                                msg.text,
                                style: TextStyle(
                                  color: scheme.onSurface,
                                ),
                              ),
                            );
                            return Row(
                              mainAxisAlignment: isUser
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isUser) ...[
                                  _buildAvatar(false),
                                  const SizedBox(width: 8),
                                ],
                                bubble,
                                if (isUser) ...[
                                  const SizedBox(width: 8),
                                  _buildAvatar(true),
                                ],
                              ],
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_sending,
                      decoration: InputDecoration(
                        hintText: 'Escribe tu pregunta',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _sending ? null : _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0080F5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _messages.add(_ChatMessage(text: prompt, isUser: true));
      _controller.clear();
    });
    await _persistHistory();
    try {
      final reply = await _gemini.askAssistant(
        prompt,
        history: _messages
            .map((m) => {
                  'role': m.isUser ? 'user' : 'assistant',
                  'text': m.text,
                })
            .toList(),
        userContext: _buildUserContext(),
      );
      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false));
      });
      await _persistHistory();
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
            text: 'Error consultando Gemini: $e', isUser: false));
      });
      await _persistHistory();
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final box = await _openHistoryBox();
      final raw = box.get('ai_thread') as List?;
      if (raw != null) {
        final loaded = raw
            .map((e) => _ChatMessage(
                  text: e['text'] as String? ?? '',
                  isUser: e['isUser'] as bool? ?? false,
                ))
            .toList();
        setState(() {
          _messages.clear();
          _messages.addAll(loaded);
        });
      }
    } catch (_) {}
  }

  Future<void> _persistHistory() async {
    try {
      final box = await _openHistoryBox();
      await box.put(
        'ai_thread',
        _messages
            .map((m) => {
                  'text': m.text,
                  'isUser': m.isUser,
                })
            .toList(),
      );
    } catch (_) {}
  }

  Future<Box> _openHistoryBox() async {
    if (!Hive.isBoxOpen('ai_chat_history')) {
      return Hive.openBox('ai_chat_history');
    }
    return Hive.box('ai_chat_history');
  }

  String _buildUserContext() {
    final user = _appProvider.currentUser;
    if (user == null) return 'Usuario sin perfil, responde genérico.';
    final genero = user.sexo.isEmpty ? 'N/D' : user.sexo;
    return 'Nombre: ${user.nombre}; Género: $genero; Edad: ${user.edad}; Altura: ${user.altura} cm; Peso: ${user.peso} kg; Meta calórica diaria: ${user.metaCalorica.toStringAsFixed(0)} kcal.';
  }

  Widget _buildAvatar(bool isUser) {
    if (isUser) {
      final user = _appProvider.currentUser;
      if (user?.imagenPerfil != null && user!.imagenPerfil!.isNotEmpty) {
        final file = File(user.imagenPerfil!);
        if (file.existsSync()) {
          return CircleAvatar(
            radius: 16,
            backgroundImage: FileImage(file),
          );
        }
      }
      return CircleAvatar(
        radius: 16,
        backgroundColor: const Color(0xFF0080F5).withOpacity(0.15),
        child: const Icon(Icons.person, color: Color(0xFF0080F5)),
      );
    } else {
      return const CircleAvatar(
        radius: 16,
        backgroundImage: AssetImage('assets/icons/icon2.png'),
        backgroundColor: Colors.transparent,
      );
    }
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}
