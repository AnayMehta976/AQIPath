import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart'; // For robust polyline decoding

class MapScreenWithActualHeatmap extends StatefulWidget {
  const MapScreenWithActualHeatmap({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MapScreenWithActualHeatmapState createState() =>
      _MapScreenWithActualHeatmapState();
}

class _MapScreenWithActualHeatmapState
    extends State<MapScreenWithActualHeatmap> {
  GoogleMapController? mapController;
  Set<Polyline> _polylines = {};
  Set<Heatmap> _heatmaps = {};

  final String googleDirectionsApiKey = 'YOUR_GOOGLE_DIRECTIONS_API_KEY';
  final String openWeatherAqiApiKey = 'YOUR_OPENWEATHER_AQI_API_KEY';

  // Define the distance interval for AQI sampling (in meters)
  final double _aqiSampleDistanceMeters =
      5000.0; // Example: Sample AQI every 5 kilometers

  @override
  void initState() {
    super.initState();
    _getRouteAndAQIHeatmap();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _getRouteAndAQIHeatmap() async {
    // Current location is Indore, Madhya Pradesh, India (as per the context)
    LatLng origin = LatLng(22.7196, 75.8577); // Indore
    LatLng destination = LatLng(
      23.2599,
      77.4126,
    ); // Bhopal (an example destination)

    // 1. Get Route Data from Google Directions API
    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$googleDirectionsApiKey';

    http.Response response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      Map data = json.decode(response.body);
      String encodedPolyline = data['routes'][0]['overview_polyline']['points'];

      // Decode the polyline into a list of LatLng points
      PolylinePoints polylinePoints = PolylinePoints();
      List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(
        encodedPolyline,
      );
      List<LatLng> routePoints =
          decodedPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

      setState(() {
        _polylines.add(
          Polyline(
            polylineId: PolylineId('full_route'),
            points: routePoints,
            color: Colors.blue, // Base route color
            width: 5,
          ),
        );
      });

      // 2. Prepare WeightedLatLng for Heatmap with distance-based sampling
      List<WeightedLatLng> heatmapDataPoints = [];

      if (routePoints.isNotEmpty) {
        // Always add the start point's AQI
        double initialAqi = await _getAQIForLocation(
          origin.latitude,
          origin.longitude,
        );
        if (initialAqi > 0) {
          heatmapDataPoints.add(
            WeightedLatLng(origin, weight: _getAQIIntensity(initialAqi)),
          );
        }

        LatLng lastSampledPoint = origin;
        double distanceSinceLastSample = 0.0;

        // Loop through the remaining points to sample at defined intervals
        for (int i = 1; i < routePoints.length; i++) {
          LatLng currentPoint = routePoints[i];

          // Calculate the distance between the last sampled point and the current point
          double segmentDistance = Geolocator.distanceBetween(
            lastSampledPoint.latitude,
            lastSampledPoint.longitude,
            currentPoint.latitude,
            currentPoint.longitude,
          );
          distanceSinceLastSample += segmentDistance;

          // If enough distance has been covered OR it's the very last point of the route
          if (distanceSinceLastSample >= _aqiSampleDistanceMeters ||
              i == routePoints.length - 1) {
            double aqi = await _getAQIForLocation(
              currentPoint.latitude,
              currentPoint.longitude,
            );
            if (aqi > 0) {
              heatmapDataPoints.add(
                WeightedLatLng(currentPoint, weight: _getAQIIntensity(aqi)),
              );
            }
            lastSampledPoint = currentPoint;
            distanceSinceLastSample = 0.0; // Reset the distance accumulator
          }
        }
      }

      // 3. Configure HeatmapGradient (colors for different AQI levels)
      final List<Color> colors = <Color>[
        Colors.green.shade500, // Good (AQI ~0-50)
        Colors.yellow.shade500, // Moderate (AQI ~51-100)
        Colors.orange.shade500, // Unhealthy for Sensitive Groups (AQI ~101-150)
        Colors.red.shade500, // Unhealthy (AQI ~151-200)
        Colors.purple.shade500, // Very Unhealthy (AQI ~201-300)
        Colors.brown.shade500, // Hazardous (AQI >300)
      ];

      // Define the intensity points corresponding to the color changes in the gradient.
      // These values should align with your _getAQIIntensity mapping.
      // Example: If max intensity is 10.0, then 0.2 means 20% of 10.0 = 2.0 intensity.
      final List<double> startPoints = <double>[
        0.0, // Green starts at 0 intensity (Good)
        0.2, // Yellow starts (e.g., AQI 50, intensity 1.0)
        0.4, // Orange starts (e.g., AQI 100, intensity 2.0)
        0.6, // Red starts (e.g., AQI 150, intensity 3.0)
        0.8, // Purple starts (e.g., AQI 200, intensity 4.0)
        1.0, // Brown starts (e.g., AQI 300+, intensity 6.0+)
      ];

      final HeatmapGradient gradient = HeatmapGradient(
        colors
            .map((e) => HeatmapGradientColor(e, startPoints[colors.indexOf(e)]))
            .toList(),
      );

      // 4. Create Heatmap object
      final Heatmap aqiHeatmap = Heatmap(
        heatmapId: HeatmapId('aqi_route_heatmap'),
        data: heatmapDataPoints,
        radius: HeatmapRadius.fromPixels(
          20,
        ), // Experiment with this value (in pixels) for the "radical radius" effect
        gradient: gradient,
        opacity: 0.7, // Overall opacity of the heatmap layer
        dissipating:
            false, // Set to false to maintain visual intensity across zoom levels
      );

      setState(() {
        _heatmaps.add(aqiHeatmap);
      });
    } else {
      print('Failed to load directions: ${response.statusCode}');
    }
  }

  // Helper function to map AQI values to heatmap intensity
  double _getAQIIntensity(double aqi) {
    // Assuming AQI is on a 0-500 scale for conventional AQI values.
    // The heatmap intensity typically ranges from 0.0 to a small positive number (e.g., 1.0 to 10.0).
    // You'll need to map your AQI range to a suitable intensity range for visualization.
    const double maxAqiValue = 500.0; // Standard maximum AQI for calculation
    const double maxHeatmapIntensity =
        6.0; // Adjust this max intensity for visual effect

    // Simple linear mapping: Higher AQI = Higher Intensity
    // Cap AQI at maxAqiValue to prevent intensity from exceeding maxHeatmapIntensity
    double normalizedAqi = (aqi.clamp(0.0, maxAqiValue) / maxAqiValue);
    return normalizedAqi * maxHeatmapIntensity;
  }

  // Example AQI API call (OpenWeatherMap Air Pollution API)
  // This API gives AQI as an integer from 1 to 5, where 1 is good, 5 is very poor.
  // We'll convert this to a conventional 0-500 scale for consistency with heatmap intensity.
  Future<double> _getAQIForLocation(double lat, double lon) async {
    String aqiUrl =
        'http://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$openWeatherAqiApiKey';

    try {
      http.Response response = await http.get(Uri.parse(aqiUrl));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        int openWeatherAqi = data['list'][0]['main']['aqi']; // AQI from 1-5

        // Convert OpenWeatherMap's 1-5 AQI to a conventional 0-500 scale
        // A simple linear mapping:
        // 1 -> 50 (Good)
        // 2 -> 100 (Moderate)
        // 3 -> 150 (Unhealthy for Sensitive Groups)
        // 4 -> 200 (Unhealthy)
        // 5 -> 300 (Very Unhealthy)
        // You can extend this for Hazardous (e.g., 5 -> 300-500) if needed.
        return openWeatherAqi *
            100.0; // This makes max AQI 500 if OpenWeather had 5
      } else {
        print(
          'Failed to load AQI for $lat,$lon: ${response.statusCode} - ${response.body}',
        );
        return 0.0; // Default to 0 or handle error appropriately
      }
    } catch (e) {
      print('Error fetching AQI: $e');
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AQI Heatmap on Route')),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: LatLng(22.9, 76.6), // A point between Indore and Bhopal
          zoom: 7.0,
        ),
        polylines: _polylines,
        heatmaps: _heatmaps, // Crucially, add the heatmaps here!
      ),
    );
  }
}
