// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'MainNavigationHistory.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MainNavigationHistoryAdapter extends TypeAdapter<MainNavigationHistory> {
  @override
  final int typeId = 40;

  @override
  MainNavigationHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MainNavigationHistory(
      startAddress: fields[0] as String,
      endAddress: fields[1] as String,
      stratEndLatLng: (fields[2] as List).cast<double>(),
      dateOfSync: fields[3] as DateTime,
      routeAvgAqi: fields[4] as double,
      detailDataReferenceId: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MainNavigationHistory obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.startAddress)
      ..writeByte(1)
      ..write(obj.endAddress)
      ..writeByte(2)
      ..write(obj.stratEndLatLng)
      ..writeByte(3)
      ..write(obj.dateOfSync)
      ..writeByte(4)
      ..write(obj.routeAvgAqi)
      ..writeByte(5)
      ..write(obj.detailDataReferenceId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MainNavigationHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
