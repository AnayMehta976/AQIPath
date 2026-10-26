import 'package:hive/hive.dart';

part 'CurrentRideRoute.g.dart';

@HiveType(typeId: 33)
class CurrentRideRoute extends HiveObject {
  @HiveField(0)
  List<List<PolylinePoint>> polylines;

  @HiveField(1)
  LatLngPoint currentpont;

  @HiveField(2)
  String startaddress;

  @HiveField(3)
  String endaddress;

  @HiveField(4)
  String modeOfTravel;

  @HiveField(5)
  List<Map<String, dynamic>> aqiDetailList; // dynamic AQI list

  @HiveField(6)
  Map<dynamic, dynamic>? routeDetail; // dynamic route detail

  CurrentRideRoute({
    required this.polylines,
    required this.currentpont,
    required this.startaddress,
    required this.endaddress,
    required this.modeOfTravel,
    required this.aqiDetailList,
    this.routeDetail,
  });
}

@HiveType(typeId: 35)
class PolylinePoint {
  @HiveField(0)
  double lat;

  @HiveField(1)
  double lng;

  PolylinePoint({required this.lat, required this.lng});
}

@HiveType(typeId: 34)
class LatLngPoint {
  @HiveField(0)
  double lat;

  @HiveField(1)
  double lng;

  LatLngPoint({required this.lat, required this.lng});
}
