import 'package:hive/hive.dart';
part 'AQiDetailHistory.g.dart';

@HiveType(typeId: 0)
class AQIDetailHistory extends HiveObject {
  @HiveField(0)
  int aqi;

  @HiveField(1)
  int idx;

  @HiveField(2)
  List<Attribution> attributions;

  @HiveField(3)
  AQICity city;

  @HiveField(4)
  String dominentpol;

  @HiveField(5)
  IAQI iaqi;

  @HiveField(6)
  AQITime time;

  @HiveField(7)
  Forecast forecast;

  @HiveField(8)
  String debugSyncTime;

  @HiveField(9)
  List<double> inputlatlng;

  AQIDetailHistory({
    required this.aqi,
    required this.idx,
    required this.attributions,
    required this.city,
    required this.dominentpol,
    required this.iaqi,
    required this.time,
    required this.forecast,
    required this.debugSyncTime,
    required this.inputlatlng,
  });
}

/// sub-classes
@HiveType(typeId: 1)
class Attribution {
  @HiveField(0)
  String url;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? logo;

  Attribution({required this.url, required this.name, this.logo});
}

@HiveType(typeId: 2)
class AQICity {
  @HiveField(0)
  List<double> geo;

  @HiveField(1)
  String name;

  @HiveField(2)
  String url;

  @HiveField(3)
  String? location;

  AQICity({
    required this.geo,
    required this.name,
    required this.url,
    this.location,
  });
}

@HiveType(typeId: 3)
class IAQI {
  @HiveField(0)
  Map<String, double> values;

  IAQI({required this.values});
}

@HiveType(typeId: 4)
class AQITime {
  @HiveField(0)
  String s;

  @HiveField(1)
  String tz;

  @HiveField(2)
  int v;

  @HiveField(3)
  String iso;

  AQITime({
    required this.s,
    required this.tz,
    required this.v,
    required this.iso,
  });
}

@HiveType(typeId: 5)
class Forecast {
  @HiveField(0)
  List<DailyForecast> pm10;

  @HiveField(1)
  List<DailyForecast> pm25;

  @HiveField(2)
  List<DailyForecast> uvi;

  Forecast({required this.pm10, required this.pm25, required this.uvi});
}

@HiveType(typeId: 6)
class DailyForecast {
  @HiveField(0)
  int avg;

  @HiveField(1)
  String day;

  @HiveField(2)
  int max;

  @HiveField(3)
  int min;

  DailyForecast({
    required this.avg,
    required this.day,
    required this.max,
    required this.min,
  });
}
