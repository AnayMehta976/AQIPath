import 'dart:developer' as mlog;
import 'dart:math' as math;
import 'dart:math';
import 'dart:ui';
import 'package:aqi_app/data/models/aqi_responses.dart';
import 'package:aqi_app/data/models/route_option.dart';
import 'package:aqi_app/data/request/allAPIs.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../configs/navigationservices.dart';
import '../data/models/aqi_point.dart';
import '../presentation/screens/auto_aqiroute_screen/aqi_routes_widgets.dart';

class GeoUtils {
  static double haversineKm(LatLng p1, LatLng p2) {
    const R = 6371.0;
    final dLat = _degToRad(p2.latitude - p1.latitude);
    final dLon = _degToRad(p2.longitude - p1.longitude);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(p1.latitude)) *
            math.cos(_degToRad(p2.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static LatLng destinationPoint(
    LatLng start,
    double bearingDeg,
    double distKm,
  ) {
    const R = 6371.0;
    final bearing = _degToRad(bearingDeg);
    final lat1 = _degToRad(start.latitude);
    final lon1 = _degToRad(start.longitude);

    final lat2 = math.asin(
      math.sin(lat1) * math.cos(distKm / R) +
          math.cos(lat1) * math.sin(distKm / R) * math.cos(bearing),
    );
    final lon2 =
        lon1 +
        math.atan2(
          math.sin(bearing) * math.sin(distKm / R) * math.cos(lat1),
          math.cos(distKm / R) - math.sin(lat1) * math.sin(lat2),
        );
    return LatLng(_radToDeg(lat2), _radToDeg(lon2));
  }

  static double _degToRad(double d) => d * math.pi / 180;
  static double _radToDeg(double r) => r * 180 / math.pi;

  int calculateMaxStops(double radiusKm, {double stepDistance = 0.6}) {
    // Estimate desired path length:
    // - Loop ~ 2× radius (go out and back around)
    // - Path ~ 1× radius (straight coverage)
    final desiredLen = radiusKm;

    // Estimate stops needed
    final rawStops =
        (desiredLen / stepDistance).round(); // round instead of floor

    // Ensure minimum of 3 stops
    return rawStops < 3 ? 3 : rawStops;
  }

  bool isValidRoute(RouteOption route, double radiusKm) {
    final estDistance = route.distanceKm;
    final target = radiusKm;
    mlog.log("myfinal routes: - $estDistance $target");
    //estDistance >= (0.8 * target) &&
    if (route.isLoop) {
      return estDistance <= target / 2.5;
    }
    return estDistance <= (1.5 * target) && estDistance >= target / 2;
  }

  double estimateDistance(List<AqiPoint> points) {
    double dist = 0;
    for (int i = 0; i < points.length - 1; i++) {
      dist += haversineKm(points[i].pos, points[i + 1].pos);
    }
    return dist;
  }

  List<LatLng> decodePolyline(String poly) {
    final List<LatLng> points = [];
    int index = 0, len = poly.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  //--------------------------------------------------------
  void scoreAndSortRoutes(List<RouteOption> routes, filterMode) {
    for (final r in routes) {
      // ensure avgAqi and distanceKm set
      r.avgAqi = calculateAvgAqi(r.points);
      r.distanceKm = estimateDistance(r.points);
    }

    routes.sort((a, b) {
      if (filterMode == 'distance') {
        return a.distanceKm.compareTo(b.distanceKm);
      }
      if (filterMode == 'traffic') {
        return (a.trafficInfo ?? '').compareTo(b.trafficInfo ?? '');
      }
      // default: aqi
      return a.avgAqi.compareTo(b.avgAqi);
    });
  }

  AqiPoint? findBestNextPoint(
    AqiPoint current,
    List<AqiPoint> candidates,
    List<AqiPoint> alreadyPicked,
  ) {
    const double minSeparationKm = 0.6; // ensure spread
    // filter unused points and keep those at least 600m->700 away
    final available =
        candidates.where((p) {
          if (alreadyPicked.contains(p)) return false;
          final dist = haversineKm(current.pos, p.pos);
          return dist >= minSeparationKm;
        }).toList();

    if (available.isEmpty) return null;

    // rank by AQI first, then distance
    available.sort((a, b) {
      final scoreA = a.aqi + haversineKm(current.pos, a.pos);
      final scoreB = b.aqi + haversineKm(current.pos, b.pos);
      return scoreA.compareTo(scoreB);
    });

    return available.first;
  }

  AqiPoint? findBestNextPoint2(
    AqiPoint current,
    List<AqiPoint> candidates,
    List<AqiPoint> alreadyPicked,
    List<List<AqiPoint>> coveredpath, {
    int maxUsage = 2,
    double minSeparationKm = 0.4,
    int startfrompoint = 12,
  }) {
    List<AqiPoint> sublist = candidates.sublist(startfrompoint);
    final available =
        sublist.where((p) {
          // ❌ don’t reuse within the same path
          if (alreadyPicked.contains(p)) return false;

          // Count global usage, but skip the first index of each path (center/start)
          final usedCount =
              coveredpath
                  .expand((path) => path.skip(1)) // skip index 0 (center)
                  .where((pt) => pt == p)
                  .length;

          if (usedCount >= maxUsage) return false;

          // ❌ too close to current
          final dist = haversineKm(current.pos, p.pos);
          return dist >= minSeparationKm;
        }).toList();

    if (available.isEmpty) return null;

    // ✅ rank by AQI + distance
    available.sort((a, b) {
      final scoreA = a.aqi + haversineKm(current.pos, a.pos);
      final scoreB = b.aqi + haversineKm(current.pos, b.pos);
      return scoreA.compareTo(scoreB);
    });

    return available.first;
  }

  List<RouteOption> pickBalancedTopK(List<RouteOption> allRoutes, int kTop) {
    final loops = allRoutes.where((r) => r.isLoop).toList();
    final nonLoops = allRoutes.where((r) => !r.isLoop).toList();

    loops.sort((a, b) => a.avgAqi.compareTo(b.avgAqi));
    nonLoops.sort((a, b) => a.avgAqi.compareTo(b.avgAqi));

    final half = (kTop / 2).ceil();
    final chosen = <RouteOption>[];

    chosen.addAll(loops.take(half));
    chosen.addAll(nonLoops.take(kTop - chosen.length));

    if (chosen.length < kTop) {
      // fill remaining from the global sorted list
      final sorted = [...allRoutes]
        ..sort((a, b) => a.avgAqi.compareTo(b.avgAqi));
      for (final r in sorted) {
        if (chosen.length >= kTop) break;
        if (!chosen.contains(r)) chosen.add(r);
      }
    }

    return chosen;
  }

  double calculateAvgAqi(List<AqiPoint> pts) {
    if (pts.isEmpty) return 0;
    return pts.map((p) => p.aqi).reduce((a, b) => a + b) / pts.length;
  }

  double aqiToHue(double aqi) {
    if (aqi <= 50) return BitmapDescriptor.hueGreen; // green
    if (aqi <= 100) return BitmapDescriptor.hueYellow; // yellow
    if (aqi <= 200) return BitmapDescriptor.hueOrange; // orange
    return BitmapDescriptor.hueRed; // red
  }

  Future<List<AqiPoint>> assignInterpolatedAqiToCandidates(
    List<LatLng> candidates,
    List<AqiPoint> anchors,
  ) async {
    final List<AqiPoint> results = [];
    int idCounter = 0;

    for (final c in candidates) {
      final aqi = interpolateFromAnchors(c, anchors);
      results.add(AqiPoint(id: 'cand-${idCounter++}', pos: c, aqi: aqi));
    }

    return results;
  }

  List<AqiPoint> sublistUntilDistance(
    AqiPoint center,
    List<AqiPoint> combo,
    double fraction, // e.g., 0.33 for 1/3, 0.5 for 1/2
    double totaldistancekinKM,
  ) {
    debugPrint("mylist for loop : ${combo.length}");
    if (combo.isEmpty) return [center];

    final totalDistance = totaldistancekinKM;
    final targetDistance = totalDistance * fraction;

    final sublist = <AqiPoint>[center];
    double accumulatedDistance = 0.0;
    for (final point in combo.skip(1)) {
      final dist = GeoUtils.haversineKm(center.pos, point.pos);
      accumulatedDistance = dist;

      if (accumulatedDistance <= totalDistance * 0.6) {
        // sublist.clear();
        sublist.add(point);
      } else {
        break; // reached the fraction threshold
      }
    }
    debugPrint("mylist for sublist : ${sublist.length}");
    return sublist;
  }

  Future<List<LatLng>> generateDenseCandidatePoints(
    LatLng center,
    double radiusKm,
  ) async {
    final List<LatLng> points = [];
    final random = Random();
    // Base distance step = 50m in km
    const double baseStepKm = 0.05;
    // Convert radius to meters to handle better
    final double radiusMeters = radiusKm * 1000;

    // progressive step expansion
    double prevDist = 0;
    int layer = 1;

    while (true) {
      // Current distance for this layer
      double currDist = (50 * layer + (layer + 1) * 50).toDouble();
      print("layer $layer distance $currDist");
      if (currDist > radiusMeters) break;

      // Place points between prevDist..currDist
      for (int dir = 0; dir < 12; dir++) {
        final baseAngle = dir * 30.0;

        // distance jitter: between prevDist+10m and currDist-10m
        final double distMeters =
            prevDist +
            10 +
            random.nextDouble() * ((currDist - prevDist) - 20).clamp(5, 9999);

        final distKm = distMeters / 1000.0;

        // angle jitter: ±5° random around base angle
        final double angle = baseAngle + (random.nextDouble() * 10 - 5);

        final pos = destinationPoint(center, angle, distKm);
        points.add(pos);

        // Optionally add second "zigzag" offset point closer/further
        if (random.nextBool()) {
          final offsetDistKm = distKm + ((random.nextDouble() - 0.5) * 0.05);
          final offsetAngle = angle + (random.nextDouble() * 6 - 3);
          points.add(destinationPoint(center, offsetAngle, offsetDistKm));
        }
      }

      prevDist = currDist;
      layer++;
    }

    // Add a few random interior points to make it less uniform
    for (int i = 0; i < (radiusMeters / 100).floor(); i++) {
      final double d = random.nextDouble() * radiusKm;
      final double angle = random.nextDouble() * 360;
      points.add(destinationPoint(center, angle, d));
    }
    // Cap points for performance
    mlog.log("Generated improved candidate points: ${points.length}");
    return points.take(650).toList();
  }

  Future<AqiResponse> _fetchAqiForPoint(LatLng point) async {
    return AllAPIRequest.fetchAqiByLocationViaGoogle(
      lat: point.latitude,
      lng: point.longitude,
      detailedResponse: true,
    );
  }

  // sortByDistanceFromCenter(List<AqiPoint> candidates, AqiPoint center) {
  //   candidates;
  // }

  double _fetchAqiForPointSemulate(LatLng point) {
    return ((point.latitude + point.longitude).abs() * 10).toInt() % 500;
  }

  Future<Marker> markerForAqiPoint(
    AqiPoint ap, {
    bool isactual = false,
    String? mycustomimage,
    Size? mysize,
  }) async {
    final h = aqiToHue(ap.aqi);
    final BitmapDescriptor icon;
    if (isactual) {
      icon = await BitmapDescriptor.asset(
        ImageConfiguration(size: mysize ?? Size(45, 45)),
        mycustomimage ?? "assets/images/pin.png",
      );
    } else {
      icon = BitmapDescriptor.defaultMarkerWithHue(h);
    }
    return Marker(
      markerId: MarkerId(ap.id),
      position: ap.pos,
      icon: icon,
      infoWindow: InfoWindow(title: 'AQI: ${ap.aqi.toStringAsFixed(0)}'),
      onTap: () {
        final BuildContext? context =
            NavigationService.navigatorKey.currentContext;
        showModalBottomSheet(
          useSafeArea: true,
          context: context!,
          builder: (_) => AqiRoutesWidgets().aqiPointDetailsSheet(ap, context),
        );
      },
    );
  }

  Future generateStandardAnchors(LatLng center, double radiusKm) async {
    final List<AqiPoint> anchors = [];
    final List<WeightedLatLng> heatmapPoints = [];
    final Set<Marker> markers = {};
    // start at 600m spacing
    double stepKm = 0.7;
    double currentDist = stepKm;
    int ringIndex = 0;

    while (currentDist <= radiusKm) {
      // alternate angle sets
      final List<int> bearings =
          (ringIndex % 2 == 0)
              ? [0, 90, 180, 270] // NESW
              : [45, 135, 225, 315]; // Diagonals
      int idCounter = 0;
      for (final b in bearings) {
        LatLng p = destinationPoint(center, b.toDouble(), currentDist);
        // anchors.add(destinationPoint(center, b.toDouble(), currentDist));
        final aqi = await _fetchAqiForPoint(p);
        // final aqi = _fetchAqiForPointSemulate(p);
        print("Auto AQI: - "+aqi.aqi.toString());
        final ap = AqiPoint(
          id: 'main-${idCounter++}',
          pos: p,
          aqi: aqi.aqi.toDouble(), //aqi,
        );
        anchors.add(ap);
        heatmapPoints.add(
          WeightedLatLng(ap.pos, weight: ap.aqi.toDouble().clamp(0, 500)),
        );

        markers.add(await markerForAqiPoint(ap, isactual: true));
        // increase distance
        currentDist += stepKm;
        // after 2km, step doubles
        if (currentDist > 3 && stepKm == 0.7) stepKm = 1;
        // if (currentDist > 4 && stepKm == 1.2) stepKm = 1.5;
        ringIndex++;
      }

      mlog.log("Standard anchors: ${anchors.length}");
      return [anchors, heatmapPoints, markers];
    }
  }

  double interpolateFromAnchors(LatLng point, List<AqiPoint> anchors) {
    if (anchors.isEmpty) return 0;

    // sort anchors by distance
    anchors.sort(
      (a, b) => haversineKm(point, a.pos).compareTo(haversineKm(point, b.pos)),
    );
    // take nearest 3
    final nearest = anchors.take(3).toList();

    // weighted average: closer anchors get more weight
    double totalWeight = 0;
    double weightedSum = 0;

    for (var ap in nearest) {
      final d = haversineKm(point, ap.pos);
      final weight = 1 / (d + 0.001); // avoid div by zero
      weightedSum += ap.aqi * weight;
      totalWeight += weight;
    }

    return weightedSum / totalWeight;
  }

  LatLngBounds boundsFromLatLngList(List<LatLng> list) {
    assert(list.isNotEmpty);
    double? x0, x1, y0, y1;
    for (final latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      southwest: LatLng(x0!, y0!),
      northeast: LatLng(x1!, y1!),
    );
  }

  double zoomFromRadius(double radiusKm) {
    // crude heuristic to pick a zoom for given radius
    if (radiusKm <= 0.5) return 15;
    if (radiusKm <= 1.5) return 14;
    if (radiusKm <= 3) return 13;
    if (radiusKm <= 6) return 12;
    return 11;
  }

  // -----------------------
  // Helper: combinations generator (k-combinations)
  // -----------------------
  Iterable<List<T>> _kCombinations<T>(List<T> list, int k) sync* {
    final n = list.length;
    if (k > n) return;
    // indices approach
    List<int> indices = List.generate(k, (i) => i);
    while (true) {
      yield indices.map((i) => list[i]).toList();
      // increment
      int i = k - 1;
      while (i >= 0 && indices[i] == i + n - k) i--;
      if (i < 0) break;
      indices[i]++;
      for (int j = i + 1; j < k; j++) indices[j] = indices[j - 1] + 1;
    }
  }

  /// Simplify a polyline with Douglas–Peucker
  List<AqiPoint> douglasPeucker(List<AqiPoint> points, double toleranceMeters) {
    if (points.length < 3) return points;

    // Recursive function
    int findFarthestIndex(
      List<AqiPoint> pts,
      int start,
      int end,
      double tolerance,
    ) {
      double maxDistance = 0;
      int index = -1;

      for (int i = start + 1; i < end; i++) {
        double distance = _perpendicularDistance(
          pts[i].pos,
          pts[start].pos,
          pts[end].pos,
        );
        if (distance > maxDistance) {
          index = i;
          maxDistance = distance;
        }
      }

      if (maxDistance > tolerance) {
        return index;
      }
      return -1;
    }

    List<AqiPoint> _simplify(
      List<AqiPoint> pts,
      int start,
      int end,
      double tolerance,
    ) {
      int index = findFarthestIndex(pts, start, end, tolerance);

      if (index != -1) {
        var left = _simplify(pts, start, index, tolerance);
        var right = _simplify(pts, index, end, tolerance);

        return [...left.sublist(0, left.length - 1), ...right];
      } else {
        return [pts[start], pts[end]];
      }
    }

    return _simplify(points, 0, points.length - 1, toleranceMeters);
  }

  /// Perpendicular distance of point from line
  double _perpendicularDistance(
    LatLng point,
    LatLng lineStart,
    LatLng lineEnd,
  ) {
    double x0 = point.latitude, y0 = point.longitude;
    double x1 = lineStart.latitude, y1 = lineStart.longitude;
    double x2 = lineEnd.latitude, y2 = lineEnd.longitude;

    double num = ((y2 - y1) * x0 - (x2 - x1) * y0 + x2 * y1 - y2 * x1).abs();
    double den = sqrt(pow(y2 - y1, 2) + pow(x2 - x1, 2));

    return den == 0 ? 0 : (num / den) * 111320; // convert deg → meters approx
  }

  /// Filter points by minimum spacing
  List<AqiPoint> filterByDistance(
    List<AqiPoint> points,
    double minDistanceMeters,
  ) {
    if (points.isEmpty) return [];

    final filtered = <AqiPoint>[];
    AqiPoint? lastKept;

    for (final point in points) {
      if (lastKept == null) {
        filtered.add(point);
        lastKept = point;
      } else {
        final distance = Geolocator.distanceBetween(
          lastKept.pos.latitude,
          lastKept.pos.longitude,
          point.pos.latitude,
          point.pos.longitude,
        );
        if (distance >= minDistanceMeters) {
          filtered.add(point);
          lastKept = point;
        }
      }
    }

    // Ensure last point is included
    if (filtered.last.id != points.last.id) {
      filtered.add(points.last);
    }

    return filtered;
  }

  /// Main function: optimize path points
  List<AqiPoint> optimizeRoutePoints(
    List<AqiPoint> points, {
    double simplifyToleranceMeters = 30,
    double minSpacingMeters = 500,
  }) {
    if (points.length <= 2) return points;

    // Step 1: Simplify shape
    final simplified = douglasPeucker(points, simplifyToleranceMeters);

    // Step 2: Filter by spacing
    final filtered = filterByDistance(simplified, minSpacingMeters);

    return filtered;
  }

  int estimateTravelMinutes(double km, String mode) {
    // Average speeds in km/h
    const walkingSpeed = 5.0;
    const cyclingSpeed = 15.0;

    final speed =
        (mode.toLowerCase() == 'cycling') ? cyclingSpeed : walkingSpeed;
    return ((km / speed) * 60).round();
  }

  static String buildRouteInstruction({
    required bool isLoop,
    required double routeDistanceKm,
    required double totalDistanceKm,
    required double avgAqi,
    required String mode, // "walking" or "cycling"
  }) {
    // ---- AQI quote selection ----
    final aqiQuote = () {
      if (avgAqi <= 50) {
        return 'Air is fresh—perfect for $mode.';
      } else if (avgAqi <= 100) {
        return 'Moderate air—good for light $mode.';
      } else if (avgAqi <= 150) {
        return 'Air slightly unhealthy—pace your $mode.';
      } else if (avgAqi <= 200) {
        return 'Unhealthy air—consider a mask while $mode.';
      } else {
        return 'Very unhealthy—limit outdoor $mode time.';
      }
    }();

    // ---- Mode-friendly distance unit ----
    String distanceLabel(double km) =>
        km < 1
            ? '${(km * 1000).toStringAsFixed(0)} m'
            : '${km.toStringAsFixed(1)} km';

    // ---- Main route instruction ----
    String mainInstruction;
    if (isLoop) {
      if (routeDistanceKm < totalDistanceKm / 2) {
        final laps = (totalDistanceKm / routeDistanceKm).ceil();
        mainInstruction =
            'Complete $laps lap${laps > 1 ? 's' : ''} of this loop (${distanceLabel(routeDistanceKm)} each) to hit your ${distanceLabel(totalDistanceKm)} goal.';
      } else {
        mainInstruction =
            'One lap of this ${distanceLabel(routeDistanceKm)} loop meets your ${distanceLabel(totalDistanceKm)} target.';
      }
    } else {
      mainInstruction =
          'Follow this path to cover about ${distanceLabel(totalDistanceKm)} by $mode.';
    }

    // ---- Final pretty sentence ----
    return '$mainInstruction  (Avg AQI ${avgAqi.toStringAsFixed(0)} – $aqiQuote)';
  }

  List<AqiPoint> reduceWaypointsWithinDistance(
    List<AqiPoint> points, {
    int minPoints = 3,
    int maxPoints = 5,
    required double maxDistanceMeters,
    double minSpacingMeters =
        200, // minimum distance between consecutive kept points
  }) {
    if (points.isEmpty) return [];
    if (points.length <= minPoints) return points;

    final reduced = <AqiPoint>[points.first];
    double traveled = 0;
    AqiPoint lastKept = points.first;

    // --- Dynamic bearing threshold for significant turns ---
    final startBearing = _bearing(points.first.pos, points[1].pos);
    final endBearing = _bearing(points[points.length - 2].pos, points.last.pos);
    double routeBearingDiff = (endBearing - startBearing).abs();
    if (routeBearingDiff > 180) routeBearingDiff = 360 - routeBearingDiff;
    final turnThresholdDeg = (routeBearingDiff / 3).clamp(10, 45);

    for (int i = 1; i < points.length; i++) {
      final current = points[i];

      // Distance from previous point in the raw list
      final segDistance = Geolocator.distanceBetween(
        points[i - 1].pos.latitude,
        points[i - 1].pos.longitude,
        current.pos.latitude,
        current.pos.longitude,
      );

      if (traveled + segDistance > maxDistanceMeters) {
        // ❗ Exceeding limit: mark lastKept as final endpoint and stop
        if (reduced.last.id != lastKept.id) reduced.add(lastKept);
        break;
      }
      traveled += segDistance;

      // Distance from last *kept* point to current
      final spacing = Geolocator.distanceBetween(
        lastKept.pos.latitude,
        lastKept.pos.longitude,
        current.pos.latitude,
        current.pos.longitude,
      );

      bool isTurn = false;
      if (i > 0 && i < points.length - 1) {
        final b1 = _bearing(points[i - 1].pos, current.pos);
        final b2 = _bearing(current.pos, points[i + 1].pos);
        double diff = (b2 - b1).abs();
        if (diff > 180) diff = 360 - diff;
        isTurn = diff >= turnThresholdDeg;
      }

      if (spacing >= minSpacingMeters || isTurn) {
        reduced.add(current);
        lastKept = current;
      }
    }

    // Ensure we always have at least minPoints (duplicate midpoint if needed)
    while (reduced.length < minPoints && points.length > reduced.length) {
      final midIndex = points.length ~/ 2;
      if (!reduced.contains(points[midIndex])) {
        reduced.insert(reduced.length - 1, points[midIndex]);
      } else {
        break;
      }
    }

    // Enforce maximum number of points
    if (reduced.length > maxPoints) {
      final start = reduced.first;
      final end = reduced.last;
      final mids = reduced.sublist(1, reduced.length - 1);
      final step = (mids.length / (maxPoints - 2)).ceil();
      final sampled = <AqiPoint>[];
      for (int i = 0; i < mids.length; i += step) {
        sampled.add(mids[i]);
        if (sampled.length >= maxPoints - 2) break;
      }
      return [start, ...sampled, end];
    }

    return reduced;
  }

  /// Bearing in degrees from point A to B
  double _bearing(LatLng from, LatLng to) {
    final lat1 = _toRadians(from.latitude);
    final lon1 = _toRadians(from.longitude);
    final lat2 = _toRadians(to.latitude);
    final lon2 = _toRadians(to.longitude);
    final dLon = lon2 - lon1;

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    return (_toDegrees(atan2(y, x)) + 360) % 360;
  }

  double _toRadians(double deg) => deg * pi / 180;
  double _toDegrees(double rad) => rad * 180 / pi;
}

class RouteSummary {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;

  RouteSummary({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
  });

  @override
  String toString() =>
      'RouteSummary(distance: ${distanceKm.toStringAsFixed(2)} km, '
      'duration: $durationMinutes min)';
}
