// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      id: fields[0] as int,
      nombre: fields[1] as String,
      edad: fields[2] as int,
      peso: fields[3] as double,
      altura: fields[4] as double,
      sexo: fields[5] as String,
      metaCalorica: fields[6] as double,
      imagenPerfil: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.edad)
      ..writeByte(3)
      ..write(obj.peso)
      ..writeByte(4)
      ..write(obj.altura)
      ..writeByte(5)
      ..write(obj.sexo)
      ..writeByte(6)
      ..write(obj.metaCalorica)
      ..writeByte(7)
      ..write(obj.imagenPerfil);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
