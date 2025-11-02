// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_ai_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseAiInfoAdapter extends TypeAdapter<ExerciseAiInfo> {
  @override
  final int typeId = 7;

  @override
  ExerciseAiInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseAiInfo(
      id: fields[0] as int,
      exerciseId: fields[1] as int,
      description: fields[2] as String,
      execution: fields[3] as String,
      tips: (fields[4] as List).cast<String>(),
      images: (fields[5] as List).cast<String>(),
      muscleGroups: fields[6] as String,
      difficulty: fields[7] as String,
      lastUpdated: fields[8] as DateTime,
      isOfflineAvailable: fields[9] as bool,
      videoUrl: fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseAiInfo obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.exerciseId)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.execution)
      ..writeByte(4)
      ..write(obj.tips)
      ..writeByte(5)
      ..write(obj.images)
      ..writeByte(6)
      ..write(obj.muscleGroups)
      ..writeByte(7)
      ..write(obj.difficulty)
      ..writeByte(8)
      ..write(obj.lastUpdated)
      ..writeByte(9)
      ..write(obj.isOfflineAvailable)
      ..writeByte(10)
      ..write(obj.videoUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseAiInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
