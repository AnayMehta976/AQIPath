// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'LoadSearchHistory.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LoadsearchhistoryAdapter extends TypeAdapter<Loadsearchhistory> {
  @override
  final int typeId = 30;

  @override
  Loadsearchhistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Loadsearchhistory(
      uid: fields[0] as String,
      startlatlng: (fields[1] as List).cast<double>(),
      endlatlng: (fields[2] as List).cast<double>(),
      synctime: fields[3] as DateTime,
      directionjsondata: (fields[4] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, Loadsearchhistory obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.startlatlng)
      ..writeByte(2)
      ..write(obj.endlatlng)
      ..writeByte(3)
      ..write(obj.synctime)
      ..writeByte(4)
      ..write(obj.directionjsondata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadsearchhistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
