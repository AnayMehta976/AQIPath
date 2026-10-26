import 'package:aqi_app/data/models/route_overviewdetail.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionResult {
  final String uid;
  final Map<String, dynamic> directionData; // raw API response
  final List<List<LatLng>> polylineAllRoutes; // decoded polylines
  final List<RouteOverview> filterData; // summary info

  DirectionResult({
    required this.uid,
    required this.directionData,
    required this.polylineAllRoutes,
    required this.filterData,
  });

  factory DirectionResult.fromJson(Map<String, dynamic> json) {
    return DirectionResult(
      uid: json['uid'] as String,
      directionData: json['direction_data'] as Map<String, dynamic>,
      polylineAllRoutes:
          (json['polyline_allroutes'] as List)
              .map(
                (route) =>
                    (route as List)
                        .map((point) => LatLng(point['lat'], point['lng']))
                        .toList(),
              )
              .toList(),
      filterData:
          (json['filter_data'] as List)
              .map((e) => RouteOverview.fromLeg(e))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "direction_data": directionData,
    "polyline_allroutes":
        polylineAllRoutes
            .map(
              (route) =>
                  route
                      .map((p) => {"lat": p.latitude, "lng": p.longitude})
                      .toList(),
            )
            .toList(),
    "filter_data": filterData.map((e) => e.toJson()).toList(),
  };
  @override
  String toString() {
    return 'DirectionResult('
        'uid: $uid, '
        'directionData: $directionData, '
        'polylineAllRoutes: ${polylineAllRoutes.map((r) => r.map((p) => "[${p.latitude}, ${p.longitude}]").toList()).toList()}, '
        'filterData: ${filterData.map((f) => f.toString()).toList()}'
        ')';
  }
}
