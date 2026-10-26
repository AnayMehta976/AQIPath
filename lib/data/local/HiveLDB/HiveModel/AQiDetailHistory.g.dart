// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'AQiDetailHistory.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AQIDetailHistoryAdapter extends TypeAdapter<AQIDetailHistory> {
  @override
  final int typeId = 0;

  @override
  AQIDetailHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AQIDetailHistory(
      aqi: fields[0] as int,
      idx: fields[1] as int,
      attributions: (fields[2] as List).cast<Attribution>(),
      city: fields[3] as AQICity,
      dominentpol: fields[4] as String,
      iaqi: fields[5] as IAQI,
      time: fields[6] as AQITime,
      forecast: fields[7] as Forecast,
      debugSyncTime: fields[8] as String,
      inputlatlng: (fields[9] as List).cast<double>(),
    );
  }

  @override
  void write(BinaryWriter writer, AQIDetailHistory obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.aqi)
      ..writeByte(1)
      ..write(obj.idx)
      ..writeByte(2)
      ..write(obj.attributions)
      ..writeByte(3)
      ..write(obj.city)
      ..writeByte(4)
      ..write(obj.dominentpol)
      ..writeByte(5)
      ..write(obj.iaqi)
      ..writeByte(6)
      ..write(obj.time)
      ..writeByte(7)
      ..write(obj.forecast)
      ..writeByte(8)
      ..write(obj.debugSyncTime)
      ..writeByte(9)
      ..write(obj.inputlatlng);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AQIDetailHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AttributionAdapter extends TypeAdapter<Attribution> {
  @override
  final int typeId = 1;

  @override
  Attribution read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Attribution(
      url: fields[0] as String,
      name: fields[1] as String,
      logo: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Attribution obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.logo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttributionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AQICityAdapter extends TypeAdapter<AQICity> {
  @override
  final int typeId = 2;

  @override
  AQICity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AQICity(
      geo: (fields[0] as List).cast<double>(),
      name: fields[1] as String,
      url: fields[2] as String,
      location: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AQICity obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.geo)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.url)
      ..writeByte(3)
      ..write(obj.location);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AQICityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class IAQIAdapter extends TypeAdapter<IAQI> {
  @override
  final int typeId = 3;

  @override
  IAQI read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IAQI(
      values: (fields[0] as Map).cast<String, double>(),
    );
  }

  @override
  void write(BinaryWriter writer, IAQI obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.values);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IAQIAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AQITimeAdapter extends TypeAdapter<AQITime> {
  @override
  final int typeId = 4;

  @override
  AQITime read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AQITime(
      s: fields[0] as String,
      tz: fields[1] as String,
      v: fields[2] as int,
      iso: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AQITime obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.s)
      ..writeByte(1)
      ..write(obj.tz)
      ..writeByte(2)
      ..write(obj.v)
      ..writeByte(3)
      ..write(obj.iso);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AQITimeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ForecastAdapter extends TypeAdapter<Forecast> {
  @override
  final int typeId = 5;

  @override
  Forecast read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Forecast(
      pm10: (fields[0] as List).cast<DailyForecast>(),
      pm25: (fields[1] as List).cast<DailyForecast>(),
      uvi: (fields[2] as List).cast<DailyForecast>(),
    );
  }

  @override
  void write(BinaryWriter writer, Forecast obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.pm10)
      ..writeByte(1)
      ..write(obj.pm25)
      ..writeByte(2)
      ..write(obj.uvi);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForecastAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DailyForecastAdapter extends TypeAdapter<DailyForecast> {
  @override
  final int typeId = 6;

  @override
  DailyForecast read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyForecast(
      avg: fields[0] as int,
      day: fields[1] as String,
      max: fields[2] as int,
      min: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DailyForecast obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.avg)
      ..writeByte(1)
      ..write(obj.day)
      ..writeByte(2)
      ..write(obj.max)
      ..writeByte(3)
      ..write(obj.min);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyForecastAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
