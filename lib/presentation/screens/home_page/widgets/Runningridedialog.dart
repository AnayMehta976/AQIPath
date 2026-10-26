import 'package:aqi_app/constants/color_constant.dart';
import 'package:aqi_app/data/local/HiveLDB/HiveModel/CurrentRideRoute.dart';
import 'package:aqi_app/data/local/HiveLDB/Hive_DataRetival.dart';
import 'package:aqi_app/utils/Background_services/Background_services_mtd.dart';
import 'package:aqi_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            spreadRadius: -6,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class RideContent extends StatelessWidget {
  final CurrentRideRoute route;
  final VoidCallback onShowMap;
  final VoidCallback onCancelTracking;
  final Position cLatLng;

  const RideContent({
    required this.route,
    required this.onShowMap,
    required this.onCancelTracking,
    required this.cLatLng,
  });
  static String formatDistance(int distanceInMeters) {
    if (distanceInMeters < 1000) {
      // less than 1 km → show in meters
      return "${distanceInMeters.toStringAsFixed(0)} m";
    } else {
      // 1 km or more → show in km with 2 decimals
      double km = distanceInMeters / 1000;
      return "${km.toStringAsFixed(2)} km";
    }
  }

  static String formatDuration(dynamic durationInTraffic) {
    if (durationInTraffic == null) return "";

    // Google API usually returns seconds as int
    int seconds = 0;
    if (durationInTraffic is int) {
      seconds = durationInTraffic;
    } else if (durationInTraffic is String) {
      seconds = int.tryParse(durationInTraffic) ?? 0;
    }

    if (seconds == 0) return "0 min";

    int minutes = (seconds / 60).round();

    if (minutes < 60) {
      return "$minutes min";
    } else {
      int hours = minutes ~/ 60;
      int remainingMin = minutes % 60;
      return remainingMin == 0 ? "$hours hr" : "$hours hr $remainingMin min";
    }
  }

  static String getDistanceCovered(LatLng startPoint, LatLng currentPoint) {
    double distanceInMeters = geo.Geolocator.distanceBetween(
      startPoint.latitude,
      startPoint.longitude,
      currentPoint.latitude,
      currentPoint.longitude,
    );

    if (distanceInMeters < 1000) {
      return "${distanceInMeters.toStringAsFixed(0)} m";
    } else {
      double km = distanceInMeters / 1000;
      return "${km.toStringAsFixed(1)} km";
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final distanceKm = formatDistance(route.routeDetail?['distance'] ?? 0.0);
    final coverdist = getDistanceCovered(
      LatLng(route.polylines[0].first.lat, route.polylines[0].first.lng),
      LatLng(cLatLng.latitude, cLatLng.longitude),
    );
    final durationMinutes = formatDuration(
      route.routeDetail?['duration_in_traffic'] ?? 0.0,
    );
    final avgAqi = _extractAvgAqi(route.aqiDetailList);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_modeIcon(route.modeOfTravel), color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Recent ${route.modeOfTravel} Ride',
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  DataReterival.deleteCurrentRide();
                  AppLocationService.stopTracking();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Stats Row
          Row(
            children: [
              _StatTile(
                label: 'Distance',
                value: distanceKm,
                icon: Icons.route_rounded,
              ),
              const SizedBox(width: 10),
              _StatTile(
                label: 'Duration',
                value: durationMinutes,
                icon: Icons.timer_rounded,
              ),
              const SizedBox(width: 10),
              _StatTile(
                label: 'Mode',
                value: route.modeOfTravel,
                icon: _modeIcon(route.modeOfTravel),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Start / End Points
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _PointRow(
                  label: "Start",
                  value:
                      route.startaddress, // e.g. "Ward 07, Main Street, City"
                  icon: Icons.play_circle_fill_rounded,
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: cs.outlineVariant.withOpacity(0.6)),
                const SizedBox(height: 8),
                _PointRow(
                  label: "End",
                  value: route.endaddress, // e.g. "Sector 15, City Mall"
                  icon: Icons.flag_rounded,
                  color: Colors.red,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // AQI chip
          if (avgAqi != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Chip(
                    label: Text('Avg AQI: ${avgAqi.toStringAsFixed(0)}'),
                    avatar: const Icon(Icons.eco_rounded, size: 18),
                    backgroundColor: _aqiColor(avgAqi).withOpacity(0.5),
                    side: BorderSide(
                      color: _aqiColor(avgAqi).withOpacity(0.45),
                    ),
                    labelStyle: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  4.toSpace,
                  Chip(
                    label: Text('Cover: $coverdist'),
                    avatar: Icon(_modeIcon(route.modeOfTravel), size: 18),
                    backgroundColor: COLOR_CONST.deleteButtonColor.withOpacity(
                      0.5,
                    ),
                    side: BorderSide(
                      color: _aqiColor(avgAqi).withOpacity(0.45),
                    ),
                    labelStyle: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 14),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onShowMap();
                  },
                  icon: const Icon(Icons.map_rounded),
                  label: const Text('Show on Map'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onCancelTracking();
                  },
                  icon: const Icon(Icons.cancel_rounded),
                  label: const Text('Cancel Tracking'),
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _modeIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'driving':
        return Icons.directions_car_filled_rounded;
      case 'walking':
        return Icons.directions_walk_rounded;
      case 'cycling':
      case 'bicycling':
        return Icons.directions_bike_rounded;
      case 'transit':
        return Icons.directions_bus_rounded;
      default:
        return Icons.directions_rounded;
    }
  }

  double? _extractAvgAqi(List<Map<String, dynamic>> list) {
    if (list.isEmpty) return null;
    final values =
        list
            .map((e) => (e['aqi'] as num?)?.toDouble())
            .whereType<double>()
            .toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  Color _aqiColor(double aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow.shade700;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.deepOrange;
    if (aqi <= 300) return Colors.red;
    return Colors.purple;
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 15, color: cs.primary),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: text.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointRow extends StatelessWidget {
  final String label;
  final String value; // <-- now directly a string (address, landmark, etc.)
  final IconData icon;
  final Color color;

  const _PointRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: text.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis, // trims long addresses
              ),
            ],
          ),
        ),
      ],
    );
  }
}
