import 'package:hive/hive.dart';
import '../../domain/entities/exercise_db_entity.dart';

class ExerciseDbAdapter extends TypeAdapter<ExerciseDbEntity> {
  @override
  final int typeId = 10; // ID único para este adaptador

  @override
  ExerciseDbEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseDbEntity(
      exerciseId: fields[0] as String,
      name: fields[1] as String,
      gifUrl: fields[2] as String,
      targetMuscles: (fields[3] as List).cast<String>(),
      bodyParts: (fields[4] as List).cast<String>(),
      equipments: (fields[5] as List).cast<String>(),
      secondaryMuscles: (fields[6] as List).cast<String>(),
      instructions: (fields[7] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseDbEntity obj) {
    writer
      ..writeByte(8) // Número de campos
      ..writeByte(0)
      ..write(obj.exerciseId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.gifUrl)
      ..writeByte(3)
      ..write(obj.targetMuscles)
      ..writeByte(4)
      ..write(obj.bodyParts)
      ..writeByte(5)
      ..write(obj.equipments)
      ..writeByte(6)
      ..write(obj.secondaryMuscles)
      ..writeByte(7)
      ..write(obj.instructions);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseDbAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
