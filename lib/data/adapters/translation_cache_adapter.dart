import 'package:hive/hive.dart';
import '../../domain/entities/translation_cache.dart';

class TranslationCacheAdapter extends TypeAdapter<TranslationCache> {
  @override
  final int typeId = 8;

  @override
  TranslationCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TranslationCache(
      originalText: fields[0] as String,
      translatedText: fields[1] as String,
      type: fields[2] as String,
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TranslationCache obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.originalText)
      ..writeByte(1)
      ..write(obj.translatedText)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranslationCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
