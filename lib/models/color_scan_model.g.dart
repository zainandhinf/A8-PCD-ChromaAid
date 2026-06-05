// GENERATED CODE - DO NOT MODIFY BY HAND
// Jalankan: flutter pub run build_runner build
// untuk regenerasi jika model berubah.

part of 'color_scan_model.dart';

class ColorScanModelAdapter extends TypeAdapter<ColorScanModel> {
  @override
  final int typeId = 0;

  @override
  ColorScanModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ColorScanModel(
      mongoId: fields[0] as String?,
      localId: fields[1] as String,
      r: fields[2] as int,
      g: fields[3] as int,
      b: fields[4] as int,
      hex: fields[5] as String,
      colorName: fields[6] as String,
      note: fields[7] as String,
      capturedAt: fields[8] as String,
      synced: fields[9] as bool,
      session: fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ColorScanModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.mongoId)
      ..writeByte(1)
      ..write(obj.localId)
      ..writeByte(2)
      ..write(obj.r)
      ..writeByte(3)
      ..write(obj.g)
      ..writeByte(4)
      ..write(obj.b)
      ..writeByte(5)
      ..write(obj.hex)
      ..writeByte(6)
      ..write(obj.colorName)
      ..writeByte(7)
      ..write(obj.note)
      ..writeByte(8)
      ..write(obj.capturedAt)
      ..writeByte(9)
      ..write(obj.synced)
      ..writeByte(10)
      ..write(obj.session);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorScanModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
