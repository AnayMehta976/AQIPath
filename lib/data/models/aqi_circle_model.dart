import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AQIPoint {
  final double lat;
  final double lng;
  final double? aqi; // Null means unknown

  AQIPoint(this.lat, this.lng, this.aqi);
}

class AQIHeatmapHelper {
  final double desiredMeters;

  AQIHeatmapHelper({this.desiredMeters = 3000}); // covers ~1.5km radius

  double metersPerPixel(double latitude, double zoomLevel) {
    return 156543.03392 * cos(latitude * pi / 180) / pow(2, zoomLevel);
  }

  int radiusInPixels(double latitude, double zoomLevel) {
    final mpp = metersPerPixel(latitude, zoomLevel);
    final radiusPixels = desiredMeters / mpp;

    // Ensure it's never too small visually
    return radiusPixels.round().clamp(40, 500);
  }

  /// Convert your AQI data points to WeightedLatLng.
  List<WeightedLatLng> generateWeightedPoints(List<AQIPoint> points) {
    return points.map((point) {
      return WeightedLatLng(
        LatLng(point.lat, point.lng),
        weight: point.aqi!.toDouble(),
      );
    }).toList();
  }

  /// Build the Heatmap widget.
  Heatmap buildHeatmap({
    required List<WeightedLatLng> data,
    required int radiusPixels,
    double opacity = 0.7,
  }) {
    return Heatmap(
      heatmapId: const HeatmapId('aqi_heatmap'),
      data: data,
      radius: HeatmapRadius.fromPixels(radiusPixels),
      opacity: opacity,
      dissipating: false, // you want fixed meters
      gradient: const HeatmapGradient(<HeatmapGradientColor>[
        HeatmapGradientColor(Colors.green, 0.25),
        HeatmapGradientColor(Colors.orange, 0.5),
        HeatmapGradientColor(Colors.red, 0.75),
      ]),
      maxIntensity: 500, // adjust if your AQI range is big
    );
  }
}
