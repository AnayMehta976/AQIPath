import 'package:aqi_app/data/models/aqi_point.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'route_overviewdetail.dart';

class RouteOption {
  String id;
  final List<AqiPoint> points; // ordered points (start may be center)
  final bool isLoop; // whether route returns to start

  // these are filled after calling Directions API (optional)
  Polyline? polyline;
  Set<Marker>? marker;
  double distanceKm; // total distance in km
  Duration? duration; // travel time
  double avgAqi;
  String? trafficInfo;
  Color routeColor;
  RouteOverview? filterData;
  var stepData;
  // optional

  RouteOption({
    required this.id,
    required this.points,
    required this.isLoop,
    this.avgAqi = 0,
    this.distanceKm = 0,
    this.duration,
    this.trafficInfo,
    required this.routeColor,
    this.filterData,
    this.stepData,
    this.marker,
  });

  @override
  String toString() {
    return 'RouteOption(id: $id, isLoop: $isLoop, points: ${points.length}, avgAqi: ${avgAqi.toStringAsFixed(1)}, distanceKm: ${distanceKm.toStringAsFixed(2)}, durationMin: ${duration?.inMinutes ?? '-'}, traffic: ${trafficInfo ?? 'N/A'})';
  }
}
