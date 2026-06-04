// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_color_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveColorModelAdapter extends TypeAdapter<HiveColorModel> {
  @override
  final int typeId = 0;

  @override
  HiveColorModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveColorModel(
      hex: fields[0] as String,
      r: fields[1] as int,
      g: fields[2] as int,
      b: fields[3] as int,
      nama: fields[4] as String,
      tags: (fields[5] as List).cast<String>(),
      catatan: fields[6] as String,
      sesiId: fields[7] as String,
      savedAt: fields[8] as DateTime,
      isSynced: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HiveColorModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.hex)
      ..writeByte(1)
      ..write(obj.r)
      ..writeByte(2)
      ..write(obj.g)
      ..writeByte(3)
      ..write(obj.b)
      ..writeByte(4)
      ..write(obj.nama)
      ..writeByte(5)
      ..write(obj.tags)
      ..writeByte(6)
      ..write(obj.catatan)
      ..writeByte(7)
      ..write(obj.sesiId)
      ..writeByte(8)
      ..write(obj.savedAt)
      ..writeByte(9)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveColorModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
