// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'AQIBulkDataHistory.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AqibulkdatahistoryAdapter extends TypeAdapter<Aqibulkdatahistory> {
  @override
  final int typeId = 20;

  @override
  Aqibulkdatahistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Aqibulkdatahistory(
      uid: fields[0] as String,
      direction_uid: fields[1] as String,
      pointlatlng: (fields[2] as List).cast<double>(),
      synctime: fields[3] as DateTime,
      aqidetailjsondata: (fields[4] as Map).cast<String, dynamic>(),
      apiType: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Aqibulkdatahistory obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.direction_uid)
      ..writeByte(2)
      ..write(obj.pointlatlng)
      ..writeByte(3)
      ..write(obj.synctime)
      ..writeByte(4)
      ..write(obj.aqidetailjsondata)
      ..writeByte(5)
      ..write(obj.apiType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AqibulkdatahistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
