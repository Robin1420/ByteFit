import 'package:hive/hive.dart';

@HiveType(typeId: 8)
class TranslationCache {
  @HiveField(0)
  final String originalText;

  @HiveField(1)
  final String translatedText;

  @HiveField(2)
  final String type; // 'exercise', 'muscle', 'bodyPart', 'equipment'

  @HiveField(3)
  final DateTime createdAt;

  TranslationCache({
    required this.originalText,
    required this.translatedText,
    required this.type,
    required this.createdAt,
  });

  TranslationCache copyWith({
    String? originalText,
    String? translatedText,
    String? type,
    DateTime? createdAt,
  }) {
    return TranslationCache(
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
