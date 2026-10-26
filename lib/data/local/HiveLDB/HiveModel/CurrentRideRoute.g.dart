// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'CurrentRideRoute.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CurrentRideRouteAdapter extends TypeAdapter<CurrentRideRoute> {
  @override
  final int typeId = 33;

  @override
  CurrentRideRoute read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CurrentRideRoute(
      polylines: (fields[0] as List)
          .map((dynamic e) => (e as List).cast<PolylinePoint>())
          .toList(),
      currentpont: fields[1] as LatLngPoint,
      startaddress: fields[2] as String,
      endaddress: fields[3] as String,
      modeOfTravel: fields[4] as String,
      aqiDetailList: (fields[5] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      routeDetail: (fields[6] as Map?)?.cast<dynamic, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, CurrentRideRoute obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.polylines)
      ..writeByte(1)
      ..write(obj.currentpont)
      ..writeByte(2)
      ..write(obj.startaddress)
      ..writeByte(3)
      ..write(obj.endaddress)
      ..writeByte(4)
      ..write(obj.modeOfTravel)
      ..writeByte(5)
      ..write(obj.aqiDetailList)
      ..writeByte(6)
      ..write(obj.routeDetail);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrentRideRouteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PolylinePointAdapter extends TypeAdapter<PolylinePoint> {
  @override
  final int typeId = 35;

  @override
  PolylinePoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PolylinePoint(
      lat: fields[0] as double,
      lng: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, PolylinePoint obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.lat)
      ..writeByte(1)
      ..write(obj.lng);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolylinePointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LatLngPointAdapter extends TypeAdapter<LatLngPoint> {
  @override
  final int typeId = 34;

  @override
  LatLngPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LatLngPoint(
      lat: fields[0] as double,
      lng: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, LatLngPoint obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.lat)
      ..writeByte(1)
      ..write(obj.lng);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLngPointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
