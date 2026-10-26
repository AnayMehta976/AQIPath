import 'package:google_maps_flutter/google_maps_flutter.dart';

class AqiPoint {
  final String id;
  final LatLng pos;
  final double aqi;

  AqiPoint({required this.id, required this.pos, required this.aqi});

  factory AqiPoint.fromLatLng(
    LatLng p, {
    String? id,
    double aqi = 0,
  }) => AqiPoint(
    id:
        id ??
        'p_${p.latitude.toStringAsFixed(6)}_${p.longitude.toStringAsFixed(6)}',
    pos: p,
    aqi: aqi,
  );

  @override
  String toString() =>
      'AqiPoint(id: $id, lat: ${pos.latitude.toStringAsFixed(6)}, lng: ${pos.longitude.toStringAsFixed(6)}, aqi: ${aqi.toStringAsFixed(1)})';
}
