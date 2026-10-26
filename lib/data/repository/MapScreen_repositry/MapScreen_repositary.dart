// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:developer';

import 'dart:math' as rd;
import 'package:aqi_app/constants/constants.dart';
import 'package:aqi_app/constants/key_constant.dart';
import 'package:aqi_app/data/local/HiveLDB/HiveModel/LoadSearchHistory.dart';
import 'package:aqi_app/data/local/HiveLDB/HiveModel/MainNavigationHistory.dart';
import 'package:aqi_app/data/local/HiveLDB/Hive_DataRetival.dart';
import 'package:aqi_app/data/models/aqi_circle_model.dart';
import 'package:aqi_app/data/models/aqi_responses.dart';
import 'package:aqi_app/data/repository/MapScreen_repositry/check_Aqi_repo.dart';
import 'package:aqi_app/data/request/allAPIs.dart';
import 'package:aqi_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:geodesy/geodesy.dart' as gs;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../presentation/screens/location_screen/location_bloc/location_event.dart';
import '../../local/HiveLDB/HiveModel/AQIBulkDataHistory.dart';

enum TransportMode { Driving, Walking, Bicycling, Stop }

class MapScreenRepository {
  //----------------------------------------
  // initlized comman Varivale
  //----------------------------------------
  static const LatLng _defaultLocation = LatLng(22.7196, 75.8577);
  final AQIHeatmapHelper heatmapHelper = AQIHeatmapHelper();
  final List<WeightedLatLng> heatmapPoints = [];
  LatLng currentLocation = _defaultLocation;
  final Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  final Set<Circle> circles = {};
  // Add a state variable for the heatmap
  final Set<Heatmap> heatmaps = {};
  String statusMessage = "Initializing...";

  var suid;
  final Dio _dio = Dio();
  List<LatLng>? myfirstrouteList;
  List<Set<Circle>> circleonroute = [];
  Map finalrouteDetail = {};
  Loadsearchhistory? recentdirectiondetail;
  List<List<double>> finalAnalizematrix = [];
  List<Map> finaloverviewdetail = [];
  final aqibox = Hive.box<Aqibulkdatahistory>('aqi_bulk_history');
  final directionbox = Hive.box<Loadsearchhistory>('direction_api_history');
  Map<String, dynamic> customMapIcon = {};
  List<int> routepriorityarray = [];
  List<List> caqiDetailallroutes = [];

  ///-----------------------------
  /// Dispose/clear all data     |
  /// ----------------------------
  cleardata() {
    markers.clear();
    polylines.clear();
    myfirstrouteList = null;
    circleonroute.clear();
    finalrouteDetail = {};
    finalAnalizematrix.clear();
    finaloverviewdetail.clear();
  }

  ///-----------------------------------------------
  ///Check N Get current position (latitude and longitude)
  /// -----------------------------------------------
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions are permanently denied.");
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        throw Exception("Location permission denied.");
      }
    }

    return await Geolocator.getCurrentPosition(
      // ignore: deprecated_member_use
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  ///--------------------------------
  /// Get readable address from coordinates
  ///--------------------------------
  Future<String> getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) return "Unknown Location";
      final placemark = placemarks.first;
      return "${placemark.subLocality} ${placemark.street}, ${placemark.locality}, ${placemark.country}";
    } catch (e) {
      return "Unknown Location";
      // TODO
    }
  }

  /// -------------------------------------------
  /// Get and Check weather direction polyline isSaved or not->model Loadsearchhistory
  /// -------------------------------------------
  Future getNCheckOldDataDirection(LatLng csLatlng, LatLng celatlng) async {
    try {
      final now = DateTime.now();
      final dateKey =
          "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${DateFormat('hh').format(now)}";
      String generateKey(LatLng start, LatLng end) {
        String sLat = start.latitude.toStringAsFixed(5);
        String sLng = start.longitude.toStringAsFixed(5);
        String eLat = end.latitude.toStringAsFixed(5);
        String eLng = end.longitude.toStringAsFixed(5);
        return "direction_${sLat}_${sLng}_${eLat}_${eLng}_$dateKey";
      }

      // for direction key expire in hour
      final key = generateKey(csLatlng, celatlng);
      if (directionbox.containsKey(key)) {
        return directionbox.get(key);
      } else {
        log("No direction data found for key: $key");
        return null;
      }
    } catch (e) {
      log("Error in getNCheckOldDataDirection: $e");
      return null;
    }
  }

  /// ----------------------------------
  ///Decode Ploylines co-ordinate Poly
  ///-----------------------------------
  List<LatLng> _decodePolyline(String poly) {
    List<LatLng> points = [];
    int index = 0, len = poly.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  // Define the helper functions here or in a separate utility file
  // Helper function to calculate dot product
  double _dot(double ux, double uy, double vx, double vy) {
    return ux * vx + uy * vy;
  }

  // Helper function to calculate squared length of a vector
  double _lengthSq(double x, double y) {
    return x * x + y * y;
  }

  /// Calculates the closest point on a line segment (p1-p2) to a given point (point).
  /// Returns a LatLng representing the closest point.
  LatLng getClosestPointOnSegment(LatLng point, LatLng p1, LatLng p2) {
    final double px = point.latitude;
    final double py = point.longitude;
    final double p1x = p1.latitude;
    final double p1y = p1.longitude;
    final double p2x = p2.latitude;
    final double p2y = p2.longitude;

    final double dx = p2x - p1x;
    final double dy = p2y - p1y;

    if ((dx == 0) && (dy == 0)) {
      // p1 and p2 are the same point
      return p1;
    }

    // Calculate the t value that projects point onto the line defined by p1 and p2
    // t = ((Px-P1x)*(P2x-P1x) + (Py-P1y)*(P2y-P1y)) / ((P2x-P1x)^2 + (P2y-P1y)^2)
    final double t = _dot(px - p1x, py - p1y, dx, dy) / _lengthSq(dx, dy);

    if (t < 0) {
      // Closest point is p1 (outside segment, on p1 side)
      return p1;
    } else if (t > 1) {
      // Closest point is p2 (outside segment, on p2 side)
      return p2;
    } else {
      // Closest point is on the segment
      final double closestX = p1x + t * dx;
      final double closestY = p1y + t * dy;
      return LatLng(closestX, closestY);
    }
  }

  ///-----------------------------------
  /// Get AQI Imaicat As Circle
  /// Optimized AQI Circle Generation for Multiple Routes
  /// ----------------------------------
  Future<Set<Circle>> getAQIImpactCricleforroutes(
    List<List<LatLng>> allRoutes,
  ) async {
    Set<Circle> aqicircle = {};
    List<Set<Circle>> aqisetcirclelist = [];
    final Map<String, dynamic> globalAqiCache = {};
    // Pre-fetch origin and destination AQI to avoid redundant calls
    final origin = allRoutes.first.first;
    final destination = allRoutes.first.last;
    final originAqi = await _fetchAqiCached(origin, globalAqiCache);
    final destinationAqi = await _fetchAqiCached(destination, globalAqiCache);
    for (var i = 0; i < allRoutes.length; i++) {
      final aqidetailData = await getsinglerouteAQIImpactCircles(
        allRoutes[i],
        "heatmaproute$i",
        i,
        origin,
        destination,
        originAqi,
        destinationAqi,
        globalAqiCache,
      );

      aqisetcirclelist.add(aqidetailData["aqiCircles"]);
      caqiDetailallroutes.add(aqidetailData["aqicircledetail"]);
      num avgaqi =
          caqiDetailallroutes[i].fold(0, (sum, e) => sum + (e['aqi'] as int)) /
          caqiDetailallroutes[i].length;
      finaloverviewdetail[i].addAll({'avg_aqi': avgaqi});
      aqicircle.addAll(aqisetcirclelist[i]);
      // circleonroute.add(a);
    }
    circleonroute = aqisetcirclelist;
    return aqicircle;
  }

  ///-----------------------------------
  /// Get Aqi of particular route Itrate all Routes
  /// ----------------------------------
  Future<Map<String, dynamic>> getsinglerouteAQIImpactCircles(
    List<LatLng> routePoints,
    String heatmapId,
    int index,
    LatLng origin,
    LatLng destination,
    AqiResponse originAqi,
    AqiResponse destinationAqi,
    Map<String, dynamic> globalCache,
  ) async {
    Set<Circle> aqiCircles = {};
    List<Map<String, dynamic>> aqiCircleDetailsList = [];
    final Set<LatLng> placedPoints = {};
    int circleIdCounter = 0;

    final routeData =
        finalrouteDetail['direction_Mdata']['routes'][index]['legs'][0];
    final double routeDistance = routeData['distance']['value'].toDouble();

    if (routePoints.length < 2) return {};

    final double sampleInterval = calculateOptimizedInterval(
      totalMeters: routeDistance,
    );
    final sampledPoints = getSampledPointsAlongRoute(
      routePoints,
      sampleInterval,
    );

    for (LatLng point in sampledPoints) {
      if (_isNear(point, origin)) {
        _addAQICircle(
          aqiCircles,
          aqiCircleDetailsList,
          point,
          originAqi,
          index,
          heatmapId,
          circleIdCounter++,
        );
        continue;
      }
      if (_isNear(point, destination)) {
        _addAQICircle(
          aqiCircles,
          aqiCircleDetailsList,
          point,
          destinationAqi,
          index,
          heatmapId,
          circleIdCounter++,
        );
        continue;
      }

      final isOverlapping = placedPoints.any(
        (p) => getDistancebetweentocordinate(p, point) < 300,
      );
      if (isOverlapping) continue;

      final cachedAqi = await _fetchAqiCached(point, globalCache);
      if (cachedAqi.aqi > 0) {
        _addAQICircle(
          aqiCircles,
          aqiCircleDetailsList,
          point,
          cachedAqi,
          index,
          heatmapId,
          circleIdCounter++,
        );
        placedPoints.add(point);
        // addAqiDataToLocalHiveDataDB(cachedAqi, point, 1);
      }
    }

    return {"aqiCircles": aqiCircles, "aqicircledetail": aqiCircleDetailsList};
  }

  bool _isNear(LatLng a, LatLng b, {double thresholdMeters = 30}) {
    return getDistancebetweentocordinate(a, b) < thresholdMeters;
  }

  Future<AqiResponse> _fetchAqiCached(LatLng point, cache) async {
    final key = '${point.latitude},${point.longitude}';
    if (cache.containsKey(key)) return cache[key];

    final aqi = await AllAPIRequest.fetchAqiByLocationViaGoogle(
      lat: point.latitude,
      lng: point.longitude,
      detailedResponse: true,
    );
    //    fetchAqiByLocation(
    //   lat: point.latitude,
    //   lng: point.longitude,
    // );
    log("fetch aqi: bai api $key");
    cache[key] = aqi;
    return aqi;
  }

  double calculateOptimizedInterval({required double totalMeters}) {
    if (totalMeters < 5000) {
      return 1500;
    } else if (totalMeters < 10000) {
      return 2500;
    } else if (totalMeters < 20000) {
      return 5000;
    } else {
      return 10000;
    }
  }

  double calculateDynamicInterval(double totalMeters) {
    const int minSamples = 3;
    const int maxSamples = 6;

    if (totalMeters < 2000) return totalMeters / minSamples;

    double interval = totalMeters / maxSamples;
    return interval.clamp(1500, 4000);
  }

  List<LatLng> getSampledPointsAlongRoute(
    List<LatLng> polylinePoints,
    double intervalMeters,
  ) {
    List<LatLng> result = [];
    double remaining = intervalMeters;
    LatLng? lastPoint = polylinePoints[0];
    result.add(lastPoint); // include starting point

    for (int i = 1; i < polylinePoints.length; i++) {
      LatLng current = polylinePoints[i];
      num segmentDistance = getDistancebetweentocordinate(lastPoint!, current);

      while (segmentDistance >= remaining) {
        double ratio = remaining / segmentDistance;
        double lat =
            lastPoint!.latitude +
            (current.latitude - lastPoint.latitude) * ratio;
        double lng =
            lastPoint.longitude +
            (current.longitude - lastPoint.longitude) * ratio;

        LatLng interpolated = LatLng(lat, lng);
        result.add(interpolated);

        // Reset for the next segment
        lastPoint = interpolated;
        segmentDistance -= remaining;
        remaining = intervalMeters;
      }

      remaining -= segmentDistance;
      lastPoint = current;
    }

    return result;
  }

  void _addAQICircle(
    Set<Circle> aqiCircles,
    List aqiCircleDetailsList,
    LatLng point,
    AqiResponse aqi,
    int index,
    String heatmapId,
    int circleIdCounter,
  ) {
    log("circle added at:$heatmapId  $index");
    aqiCircles.add(
      Circle(
        zIndex: -1,
        circleId: CircleId('$heatmapId-$circleIdCounter'),
        center: point,
        radius: 300.0,
        fillColor: COLOR_CONST.getAQIColor(aqi.aqi).withOpacity(0.4),
        strokeColor: Colors.transparent,
      ),
    );
    routepriorityarray = evaluateRoutesPriority(finaloverviewdetail);
    aqiCircleDetailsList.add({
      "primary_route": index,
      "circle_id": "$heatmapId-$circleIdCounter",
      "routePoints": point,
      "is_comman": true,
      "comman_in": "none",
      "aqi": aqi.aqi,
      "metaData_aqi": aqi,
    });
  }

  double scaledurationondist(double dist) {
    return dist <= 3000
        ? 1000.0
        : dist < 10000
        ? 3000.0
        : 10000.0;
  }

  Circle addAqicircleforresume(data) {
    return Circle(
      zIndex: 1,
      circleId: CircleId(data['id'] ?? Uuid()),
      center: LatLng(data['routePoints'].lat, data['routePoints'].lng),
      radius: 300.0,
      fillColor: COLOR_CONST.getAQIColor(data['aqi']).withOpacity(0.4),
      strokeColor: Colors.transparent,
    );
  }

  /// get filterize direction
  Future<Map> getDirectionOnFilter(current) async {
    final result = analyzeRoutes(finaloverviewdetail);
    // print("Matrix: ${result['matrix']}");
    // print("Lowest AQI Index: ${result['lowestAQIIndex']}");
    // print("Fastest Route Index: ${result['fastestDurationIndex']}");
    // print("Best Balanced Route Index: ${result['bestCaseIndex']}");
    switch (current) {
      case RouteFilterType.lowAqi:
        List<List> data = result['matrix'];
        log(data.toString());

        return {
          "route_index": result['lowestAQIIndex'],
          "route_avg_aqi": data[result['lowestAQIIndex']][3],
          "route_total_distance": data[result['lowestAQIIndex']].first,
          "route_duration": data[result['lowestAQIIndex']][1],
          "traffic_route_duration": data[result['lowestAQIIndex']][2],
          "traffic_duration_weight": data[result['lowestAQIIndex']][2],
        };
      case RouteFilterType.averageAqi:
        // 🟨 Closest to Average AQI
        return {
          "route_index": result['bestCaseIndex'],
          "route_avg_aqi": result['matrix'][result['bestCaseIndex']][3],
          "route_total_distance":
              result['matrix'][result['bestCaseIndex']].first,
          "route_duration": result['matrix'][result['bestCaseIndex']][1],
          "traffic_route_duration":
              result['matrix'][result['bestCaseIndex']][2],
          "traffic_duration_weight":
              result['matrix'][result['bestCaseIndex']][2],
        };

      case RouteFilterType.fastest:
        return {
          "route_index": result['fastestDurationIndex'],
          "route_avg_aqi": result['matrix'][result['fastestDurationIndex']][3],
          "route_total_distance":
              result['matrix'][result['fastestDurationIndex']].first,
          "route_duration": result['matrix'][result['fastestDurationIndex']][1],
          "traffic_route_duration":
              result['matrix'][result['fastestDurationIndex']][2],
          "traffic_duration_weight":
              result['matrix'][result['fastestDurationIndex']][2],
        };

      default:
        throw Exception('Invalid route filter case');
    }
  }

  /// normalize waight of AQI  scale 1-3
  double getAqiNormalizedWeight(double aqi, i) {
    finaloverviewdetail[i].addAll({'avg_aqi': aqi});
    if (aqi <= 50) {
      return 1.0;
    } else if (aqi <= 100) {
      return 1.5;
    } else if (aqi <= 150) {
      return 2.0;
    } else if (aqi <= 200) {
      return 2.5;
    } else {
      return 3.0;
    }
  }

  /// normalize waight of route {duration and direction}  scale 1-3
  List<Map<String, double>> computeNormalizedRouteWeights(
    List<Map> filterData,
  ) {
    // Parse distance values
    final distances =
        filterData
            .map(
              (e) =>
                  double.tryParse(
                    e['distance']['text'].toString().split(" ").first,
                  ) ??
                  0.0,
            )
            .toList();

    // Parse duration values (without traffic)
    final durations =
        filterData
            .map(
              (e) =>
                  double.tryParse(
                    e['duration']['text'].toString().split(" ").first,
                  ) ??
                  0.0,
            )
            .toList();

    // Parse duration_in_traffic values
    final trafficDurations =
        filterData
            .map(
              (e) =>
                  double.tryParse(
                    e['duration_in_traffic']?['text']
                            .toString()
                            .split(" ")
                            .first ??
                        '',
                  ) ??
                  0.0,
            )
            .toList();

    // Find min/max for normalization
    final minDist = distances.reduce((a, b) => a < b ? a : b);
    final maxDist = distances.reduce((a, b) => a > b ? a : b);

    final minDur = durations.reduce((a, b) => a < b ? a : b);
    final maxDur = durations.reduce((a, b) => a > b ? a : b);

    final minTraffic = trafficDurations.reduce((a, b) => a < b ? a : b);
    final maxTraffic = trafficDurations.reduce((a, b) => a > b ? a : b);

    return List.generate(filterData.length, (i) {
      final dist = distances[i];
      final dur = durations[i];
      final trafficDur = trafficDurations[i];

      final distanceWeight =
          1.0 +
          2.0 *
              ((dist - minDist) /
                  ((maxDist - minDist) == 0 ? 1 : (maxDist - minDist)));
      final durationWeight =
          1.0 +
          2.0 *
              ((dur - minDur) /
                  ((maxDur - minDur) == 0 ? 1 : (maxDur - minDur)));
      final trafficWeight =
          1.0 +
          2.0 *
              ((trafficDur - minTraffic) /
                  ((maxTraffic - minTraffic) == 0
                      ? 1
                      : (maxTraffic - minTraffic)));

      return {
        "distanceWeight": double.parse(distanceWeight.toStringAsFixed(2)),
        "durationWeight": double.parse(durationWeight.toStringAsFixed(2)),
        "trafficWeight": double.parse(trafficWeight.toStringAsFixed(2)),
        "dist": dist,
        "dur": dur,
        "trafficDur": trafficDur,
      };
    });
  }

  /// normalize to scale of 1-3
  List<double?> normalizeToScale(
    List<double> scores, {
    double minScale = 1.0,
    double maxScale = 3.0,
  }) {
    final minVal = scores.reduce((a, b) => a < b ? a : b);
    final maxVal = scores.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal == 0) ? 1 : (maxVal - minVal);
    return scores.map((score) {
      return minScale + ((score - minVal) / range) * (maxScale - minScale);
    }).toList();
  }

  /// final distance between twopoint
  num getDistancebetweentocordinate(LatLng l1, LatLng l2) {
    final geodesy = gs.Geodesy();
    gs.LatLng point1 = gs.LatLng(l1.latitude, l1.longitude);
    gs.LatLng point2 = gs.LatLng(l2.latitude, l2.longitude);
    num distance = geodesy.distanceBetweenTwoGeoPoints(point1, point2);

    return distance;
  }

  /// Get Image From Weight
  String getImageForWeight(double weight) {
    if (weight <= 50) {
      return IMAGECONST.LOW_AQI;
    } else if (weight <= 150) {
      return IMAGECONST.AVERAGE_AQI;
    } else {
      return IMAGECONST.HIGH_AQI;
    }
  }

  /// NearestStepApi
  Future<Map<String, dynamic>> getNearestStepAQI({
    required LatLng currentLatLng,
    required int routeindex,
    bool? islastride,
  }) async {
    if (routeindex == -1) return {};
    Map? mydatanotify = {};
    log("i am here in nearest $islastride");
    if (islastride ?? false) {
      log("inside true");
      var preferences = await SharedPreferences.getInstance();
      final String? lastFetch = preferences.getString(SavedKey.STREAM_BG_DATA);
      Map? mydata;
      // int distancebreak = preferences.getInt("distancebreakpoint") ?? 0;
      if (lastFetch != null) {
        mydata = jsonDecode(lastFetch);
        if (mydata!['aqis'] is String) {
          mydata['aqis'] = jsonDecode(mydata['aqis']);
        }
      }
      mydatanotify = mydata!;
    }
    log("outside true");
    final steps =
        islastride ?? false
            ? mydatanotify['steps']
            : finalrouteDetail['direction_Mdata']['routes'][routeindex]['legs'][0]['steps'];

    double minDistance = double.infinity;
    Map closestStep = {};

    for (final step in steps) {
      final stepLat = step['start_location']['lat'] as double;
      final stepLng = step['start_location']['lng'] as double;

      final distance = Geolocator.distanceBetween(
        currentLatLng.latitude,
        currentLatLng.longitude,
        stepLat,
        stepLng,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestStep = step;
      }
    }

    int closestAQI = 0;

    if (closestStep != null) {
      final stepLat = closestStep['start_location']['lat'] as double;
      final stepLng = closestStep['start_location']['lng'] as double;

      double minAQIDistance = double.infinity;
      var aqiPoints =
          (islastride ?? false)
              ? mydatanotify['aqis']
              : caqiDetailallroutes[routeindex];
      for (final point in aqiPoints) {
        final LatLng coords;
        if (point['routePoints'] is LatLng) {
          coords = point['routePoints'];
        } else if (point['routePoints'] is Map) {
          coords = LatLng(
            (point['routePoints']['lat'] as num).toDouble(),
            (point['routePoints']['lng'] as num).toDouble(),
          );
        } else {
          continue;
        }
        final distance = Geolocator.distanceBetween(
          stepLat,
          stepLng,
          coords.latitude,
          coords.longitude,
        );

        if (distance < minAQIDistance) {
          minAQIDistance = distance;
          closestAQI = point['aqi'].round();
        }
      }

      final filldata = {
        'aqiValue': closestAQI,
        'turnInstructionHtml': closestStep['html_instructions'] as String,
        'routeDetail':
            'Next ${closestStep['distance']['text']} · ${closestStep['duration']['text']}',
      };

      log("my fillied data : $filldata");
      return filldata;
    }

    return {
      'aqiValue': closestAQI ?? 0,
      'turnInstructionHtml': '',
      'routeDetail': '',
    };
  }

  /// initilized all Custom LOcation Icon
  Future<void> makeCustomIcon() async {
    var startPinPoint = await BitmapDescriptor.asset(
      ImageConfiguration(size: Size(48, 48)),
      IMAGECONST.START_POINT,
      width: 60,
      height: 60,
    );
    var endPinPoint = await BitmapDescriptor.asset(
      ImageConfiguration(size: Size(48, 48)),
      IMAGECONST.END_POINT,
      width: 60,
      height: 60,
    );
    var mYLocationPoint = await BitmapDescriptor.asset(
      ImageConfiguration(size: Size(50, 50)),
      IMAGECONST.MY_Loc_Icon,
      width: 50,
      height: 50,
    );
    var currentPoint = await BitmapDescriptor.asset(
      ImageConfiguration(size: Size(40, 40)),
      IMAGECONST.NAVIGATOR_POINT,
      width: 40,
      height: 40,
    );
    var carIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(45, 48)),
      IMAGECONST.Driving_Icon,
      width: 40,
      height: 50,
    );
    Map<String, dynamic> customIcon = {
      "start_point": startPinPoint,
      "end_Point": endPinPoint,
      "car_icon": carIcon,
      "my_location": mYLocationPoint,
      "current_location": currentPoint,
    };
    customMapIcon = customIcon;
  }

  /// Route Analize Accorcting to weight propotion
  Map<String, dynamic> analyzeRoutes(List<Map<dynamic, dynamic>> routes) {
    List<List<num>> matrix = [];

    num minAqi = double.infinity;
    int lowestAQIIndex = -1;

    num minDuration = double.infinity;
    int fastestDurationIndex = -1;

    List<num> aqiList = [];
    List<num> durationList = [];

    for (int i = 0; i < routes.length; i++) {
      final route = routes[i];
      num distance = route['distance'] ?? 0;
      num duration = route['duration'] ?? 0;
      num durationInTraffic = route['duration_in_traffic'] ?? 0;
      num avgAqi = route['avg_aqi'] ?? 0;

      matrix.add([distance, duration, durationInTraffic, avgAqi]);

      // Store separately for normalization
      durationList.add(duration);
      aqiList.add(avgAqi);

      if (avgAqi < minAqi) {
        minAqi = avgAqi;
        lowestAQIIndex = i;
      }

      if (duration < minDuration) {
        minDuration = duration;
        fastestDurationIndex = i;
      }
    }

    // Normalize duration and aqi to [0, 1]
    num minDur = durationList.reduce((a, b) => a < b ? a : b);
    num maxDur = durationList.reduce((a, b) => a > b ? a : b);
    num minA = aqiList.reduce((a, b) => a < b ? a : b);
    num maxA = aqiList.reduce((a, b) => a > b ? a : b);

    List<num> weightedScores = [];

    for (int i = 0; i < matrix.length; i++) {
      num normDur =
          (durationList[i] - minDur) /
          ((maxDur - minDur) == 0 ? 1 : (maxDur - minDur));
      num normAqi =
          (aqiList[i] - minA) / ((maxA - minA) == 0 ? 1 : (maxA - minA));

      // Weight: duration = 0.6, aqi = 0.4 (you can adjust this)
      num score = normDur * 0.6 + normAqi * 0.4;
      weightedScores.add(score);
    }

    int bestCaseIndex = weightedScores.indexOf(
      weightedScores.reduce((a, b) => a < b ? a : b),
    );

    return {
      "matrix": matrix,
      "lowestAQIIndex": lowestAQIIndex,
      "fastestDurationIndex": fastestDurationIndex,
      "bestCaseIndex": bestCaseIndex,
    };
  }

  /// Evaluate Route Property
  List<int> evaluateRoutesPriority(List<Map<dynamic, dynamic>> routes) {
    int n = routes.length;
    if (n == 0) return [];

    // Extract values
    List<int> distances =
        routes.map((e) => (e['distance'] ?? 0) as int).toList();
    List<int> durations =
        routes.map((e) => (e['duration'] ?? 0) as int).toList();
    List<double> trafficRatios =
        routes.map((e) {
          final int dur = e['duration'] ?? 1;
          final int traffic = e['duration_in_traffic'] ?? dur;
          return dur == 0
              ? 1.0
              : _roundToPrecision(traffic / dur, precision: 2);
        }).toList();

    List<double> aqis =
        routes.map((e) => e['avg_aqi'] ?? 500.0).cast<double>().toList();
    log("all data: $aqis$distances$durations$trafficRatios");
    // Ranking helper
    List<int> indices = List.generate(aqis.length, (i) => i);

    indices.sort((a, b) {
      if (aqis[a] != aqis[b]) {
        return aqis[a].compareTo(aqis[b]);
      } else if (distances[a] != distances[b]) {
        return distances[a].compareTo(distances[b]);
      } else {
        return trafficRatios[a].compareTo(trafficRatios[b]);
      }
    });
    indices.map((index) => index).toList();
    return indices;
  }

  /// Evaluate on Precise Scale
  double _roundToPrecision(final double value, {required final int precision}) {
    final int upscalingFactor = rd.pow(10, precision).toInt();
    final double upscaledValue =
        value.toPrecision(precision + 1) * upscalingFactor;
    return upscaledValue.round() / upscalingFactor;
  }

  ///=============================================================
  ///------------------------------------
  /// Create method for polyline and Markers
  /// -----------------------------------
  /// create polyline on map
  Future<void> buildPolylinesNMarker(
    List<List<LatLng>> routes,
    directionmetadata,
    mode, {
    bool? isrowbased,
  }) async {
    polylines.clear();
    markers.removeWhere((e) => e.markerId.value.contains("pm"));
    log("In marker points: $isrowbased");
    for (int i = routes.length - 1; i >= 0; i--) {
      final int aqivalue =
          isrowbased ?? false
              ? directionmetadata['avg_aqi'].round()
              : finaloverviewdetail[routepriorityarray[i]]['avg_aqi'].round();
      polylines.add(
        buildAqiPolyline(
          index: i,
          routePoints: routes[i],
          aqi: aqivalue.round(),
          mode: mode,
          isPrimary: i == 0,
        ),
      );
      int pointid = rd.Random().nextInt(routes[i].length - 6) + 5;
      await updateMarker(
        type: 'pm$i',
        position: routes[i][pointid],
        assetimage: getImageForWeight(
          isrowbased ?? false
              ? directionmetadata['avg_aqi'].toDouble()
              : finaloverviewdetail[routepriorityarray[i]]['avg_aqi'],
        ),
        size: Size(70, 38),
        onTap: (type, position) {
          log("from repo: $type $position");
          // onpressed!(type, position);
          // CommonBloc.locationBloc.add(
          //   ShowMarkercustomInfoWindow(position, type),
          // );
        },
        onDragEnd: (id, position) {},
      );
    }
  }

  /// build Polyline
  Polyline buildAqiPolyline({
    required int index,
    required List<LatLng> routePoints,
    required int aqi,
    required String mode,
    required bool isPrimary, // true for main route
  }) {
    return Polyline(
      polylineId: PolylineId('route_$index'),
      zIndex: isPrimary ? 10 : 5,
      color: getColorForAqi(aqi),
      width: getWidthForMode(mode),
      patterns: getPatternForMode(mode),
      points: routePoints,
    );
  }

  /// Get Patter as per Mode
  List<PatternItem> getPatternForMode(String? mode) {
    switch (mode) {
      case 'walking':
        return [PatternItem.dot, PatternItem.gap(10)];
      case 'bicycling':
        return [PatternItem.dash(20), PatternItem.gap(10)];
      case 'driving':
        return []; // Return an empty list for a solid line (no pattern)
      default:
        return []; // Return an empty list for any other mode (solid line)
    }
  }

  /// get Width of polyline
  int getWidthForMode(String mode) {
    switch (mode) {
      case 'walking':
        return 4;
      case 'bicycling':
        return 6;
      case 'driving':
      default:
        return 8;
    }
  }

  /// Get Color From Weight
  Color getColorForAqi(int aqi) {
    if (aqi <= 50) {
      return Colors.green;
    } else if (aqi <= 100)
      return Colors.lightGreen;
    else if (aqi <= 200)
      return Colors.orange;
    else if (aqi <= 300)
      return Colors.red;
    else if (aqi <= 400)
      return Colors.purple;
    else
      return Colors.brown;
  }

  ///=============================================================
  ///------------------------------------
  /// Marker Initilization and Create,update And Delate Methods
  /// -----------------------------------

  ///------------------------------------
  /// Update or Create Marker
  /// -----------------------------------
  Future<void> updateMarker({
    required String type, // "start_point", "end_point", or "current_point"
    required LatLng position,
    String? assetimage,
    Size? size,
    required void Function(String type, LatLng position) onTap,
    required void Function(String id, LatLng position) onDragEnd,
  }) async {
    final BitmapDescriptor icon;
    if (assetimage != null) {
      icon = await BitmapDescriptor.asset(
        ImageConfiguration(size: size),
        assetimage,
        width: size!.width,
        height: size.height,
      );
    } else {
      icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
    MarkerId markerId = MarkerId(type); // unique id per type
    Marker newMarker = Marker(
      markerId: markerId,
      position: position,
      icon: icon,
      onTap: () => onTap(type, position),
      draggable: (type == 'p0' || type == 'pn'),
      onDragEnd: (newPosition) => onDragEnd(type, newPosition),
    );
    markers.add(newMarker);
  }

  /// ----------------------------
  /// Delete Marker by Type
  /// ----------------------------
  void deleteMarker(String type) {
    MarkerId markerId = MarkerId(type);
    markers.remove(markerId);
  }

  ///=====================================================================
  ///------------------------------
  /// Add Detail on Local Hive    |
  /// -----------------------------

  ///-----------------------------------
  ///Save A Google Direction Detail on local Database
  ///-----------------------------------
  void addDirectionToLocalDataDB(
    Map<String, dynamic> data,
    LatLng clatlng,
    LatLng dlatlng,
    suid,
  ) async {
    try {
      final now = DateTime.now();
      final hour = DateFormat('hh').format(now);
      final dateKey =
          "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}$hour";
      String generateKey(LatLng start, LatLng end) {
        String sLat = start.latitude.toStringAsFixed(5);
        String sLng = start.longitude.toStringAsFixed(5);
        String eLat = end.latitude.toStringAsFixed(5);
        String eLng = end.longitude.toStringAsFixed(5);
        return "direction_${sLat}_${sLng}_${eLat}_${eLng}_$dateKey";
      }

      final key = generateKey(clatlng, dlatlng);
      Loadsearchhistory entry = Loadsearchhistory(
        directionjsondata: data,
        uid: suid,
        startlatlng: [clatlng.latitude, clatlng.longitude],
        endlatlng: [dlatlng.latitude, dlatlng.longitude],
        synctime: DateTime.now(),
      );
      final directionbox = Hive.box<Loadsearchhistory>('direction_api_history');
      await directionbox.put(key, entry);
      log("✅ Direction data added to local Hive DB");
    } catch (e, st) {
      log("❌ Error adding to local DB: $e");
      log("📌 StackTrace: $st");
    }
  }

  ///-------------------------------------
  ///Save Navigation History with referance
  ///-------------------------------------
  // Add on Navigation History
  List<String> sessionsavedID = [];
  void addOnNavigationHistory(
    LatLng cpoint,
    LatLng spoint,
    int routedistance,
    Map ro,
  ) {
    int routeid = ro["index_id"];
    String myuuid = "$suid-${routeid.toString()}";
    if (routedistance / 2 <=
            (Geolocator.distanceBetween(
              spoint.latitude,
              spoint.longitude,
              cpoint.latitude,
              cpoint.longitude,
            )) &&
        !sessionsavedID.contains(myuuid)) {
      debugPrint("here in adding");
      String uid = myuuid.toString().split('-').first;
      final history = MainNavigationHistory(
        startAddress: ro['saddress'],
        endAddress: ro['eaddress'],
        stratEndLatLng: [
          ro["pathpoints"].first.latitude,
          ro["pathpoints"].first.longitude,
          ro["pathpoints"].last.latitude,
          ro["pathpoints"].last.longitude,
        ], // lat1, lng1, lat2, lng2
        dateOfSync: DateTime.now(),
        routeAvgAqi: ro['avgAqi'],
        detailDataReferenceId: suid,
      );
      // put without key → Hive assigns integer key
      DataReterival.addNavigationHistoryToLocalDataDB(
        history,
        uid,
      ).whenComplete(() => sessionsavedID.add(myuuid));
    }
  }

  ///-----------------------------------
  ///Save A Multiple Aqi point Detail on local Database
  ///-----------------------------------
  void addAqiDataToLocalHiveDataDB(data, LatLng clatlng, int aqitype) {
    final aqibox = Hive.box<Aqibulkdatahistory>('aqi_bulk_history');
    final box = aqibox;
    final newLat = (clatlng.latitude * 100).round() / 100; // 28.61
    final newLng = (clatlng.longitude * 100).round() / 100; // 77.21
    final curenttime = DateTime.now();
    final _onlyDate = DateFormat("dd/MM/yyyy").format(curenttime);
    final hour = DateFormat('hh').format(curenttime);
    final key = '$newLat,${newLng}_${_onlyDate}_$hour';
    if (!box.containsKey(key)) {
      try {
        Aqibulkdatahistory entry = Aqibulkdatahistory(
          aqidetailjsondata: data,
          uid: Uuid().v7(),
          synctime: DateTime.now(),
          direction_uid: suid ?? Uuid().v7(),
          pointlatlng: [clatlng.latitude, clatlng.longitude],
          apiType: aqitype,
        );
        box.put(key, entry);
        log("✅ AQI data added to local Hive DB");
      } catch (e, st) {
        log("❌ Error adding to local DB: $e");
        log("📌 StackTrace: $st");
      }
    }
  }

  ///=====================================================================
  ///Logic to get point on map
  List<LatLng> generateCoordinateBucketsRandom(LatLng center, double radiusKm) {
    final List<LatLng> points = [];
    final List<LatLng> aqipoints = [];
    points.add(center);
    updateMarker(
      position: center,
      type: "c-0",
      onTap: (String type, LatLng position) {},
      onDragEnd: (String id, LatLng position) {},
    );
    int iteater = 1;
    double startval =
        radiusKm < 1
            ? 0.2
            : radiusKm < 3
            ? 0.5
            : radiusKm < 5
            ? 1
            : 2;
    for (double j = startval; j <= radiusKm; j = j + startval) {
      // if (j == startval && iteater != 1) break;
      // Step 1: N, E, S, W
      points.add(
        _destinationPoint(center, 0, j.toDouble(), points.length),
      ); // North
      points.add(
        _destinationPoint(center, 90, j.toDouble(), points.length),
      ); // East
      points.add(
        _destinationPoint(center, 180, j.toDouble(), points.length),
      ); // South
      points.add(
        _destinationPoint(center, 270, j.toDouble(), points.length),
      ); // West

      // Step 2: Random mid angles at half radius
      final random = rd.Random();
      final List<List<double>> angleRanges = [
        [25, 75], // Between North and East
        [105, 165], // Between East and South
        [210, 255], // Between South and West
        [280, 345], // Between West and North
      ];
      for (var range in angleRanges) {
        double randomAngle =
            range[0] + random.nextDouble() * (range[1] - range[0]);
        LatLng mypoints = _destinationPoint(
          center,
          randomAngle,
          j.toDouble(),
          points.length,
        );
        points.add(mypoints);
      }

      iteater++; // increment iteater
    }
    log("all point: ${points.length} ${aqipoints.length}");
    findexectpointonradiusforaqis(center, radiusKm);
    return points;
  }

  findexectpointonradiusforaqis(LatLng centerpoint, double radiusKm) {
    final List<LatLng> allaqipoints = [];
    final List<LatLng> checkaqipoints = [];
    allaqipoints.add(centerpoint);
    int iteater = 1;
    double startval =
        radiusKm < 2
            ? 1
            : radiusKm < 3
            ? 1.5
            : 2;
    for (double j = startval; j <= radiusKm; j = j + startval) {
      // Step 1: N, E, S, W
      // 1-> j=1.5, i=1 | 2-> j=3, i=2;
      List<double> angleofPoint = [0, 45, 90, 135, 180, 235, 270, 315];

      for (var angle in angleofPoint) {
        LatLng mypoints = _destinationPoint(
          centerpoint,
          angle,
          j.toDouble(),
          "a-${allaqipoints.length}",
        );
        allaqipoints.add(mypoints);
        if (iteater.isOdd && allaqipoints.length.isOdd) {
          checkaqipoints.add(mypoints);
        }
        if (iteater.isEven && allaqipoints.length.isEven) {
          checkaqipoints.add(mypoints);
        }
      }
      iteater++;
      log("Run time : $iteater");
      // increment iteater
    }
    log("allAqiPoints: ${allaqipoints.length} : ${checkaqipoints.length}");
  }

  LatLng _destinationPoint(
    LatLng start,
    double bearingDeg,
    double distanceKm,
    id,
  ) {
    const R = 6371.0; // Earth radius in km
    final bearing = CheckAqiRepo().degreesToRadians(bearingDeg);
    final lat1 = CheckAqiRepo().degreesToRadians(start.latitude);
    final lon1 = CheckAqiRepo().degreesToRadians(start.longitude);

    final lat2 = rd.asin(
      rd.sin(lat1) * rd.cos(distanceKm / R) +
          rd.cos(lat1) * rd.sin(distanceKm / R) * rd.cos(bearing),
    );
    final lon2 =
        lon1 +
        rd.atan2(
          rd.sin(bearing) * rd.sin(distanceKm / R) * rd.cos(lat1),
          rd.cos(distanceKm / R) - rd.sin(lat1) * rd.sin(lat2),
        );
    LatLng mydispoint = LatLng(
      CheckAqiRepo().radiansToDegrees(lat2),
      CheckAqiRepo().radiansToDegrees(lon2),
    );

    updateMarker(
      position: mydispoint,
      type: "c-$id",
      assetimage: id.toString().contains("a") ? 'assets/images/pin.png' : null,
      size: Size(48, 48),
      onTap: (String type, LatLng position) {},
      onDragEnd: (String id, LatLng position) {},
    );
    return mydispoint;
  }

  ///=====================================================================
  ///----------------------------
  /// All API Called here       |
  ///----------------------------

  ///------------------------------------
  /// Fetch Direction Google API between points
  /// -----------------------------------
  Future<Map<dynamic, dynamic>> fetchDirectionByLocation({event, mode}) async {
    const String apiKey = Constantkey.GOOGLE_MAP_API_KEY;
    log("mode to find direction: $mode");
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${event.origin.latitude},${event.origin.longitude}'
        '&destination=${event.destination.latitude},${event.destination.longitude}'
        '&alternatives=true'
        '&departure_time=now'
        '&mode=${mode == "bicycling" ? "driving" : mode}'
        '&traffic_model=best_guess'
        '&key=$apiKey';
    try {
      recentdirectiondetail = await getNCheckOldDataDirection(
        event.origin,
        event.destination,
      );
      log("loggerdata: $recentdirectiondetail");
      var response =
          recentdirectiondetail == null
              ? await _dio.get(url)
              : Response(
                requestOptions: RequestOptions(),
                data: recentdirectiondetail!.directionjsondata,
                statusCode: 200,
              );
      log("response data: $response");
      List<List<LatLng>> allRoutes = [];
      if (response.data['status'] != 'OK') {
        throw Exception('Failed to fetch directions');
      }
      if (recentdirectiondetail == null) {
        suid = Uuid().v4();
        addDirectionToLocalDataDB(
          response.data,
          event.origin,
          event.destination,
          suid,
        );
      } else {
        suid = recentdirectiondetail!.uid;
      }

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        log("location rsponse:- ${response.data}");
        for (var route in response.data['routes']) {
          final polyline = _decodePolyline(
            route['overview_polyline']['points'],
          );
          allRoutes.add(polyline);
          final durationtraffic =
              route['legs'][0]["duration_in_traffic"] ?? null;
          finaloverviewdetail.add({
            "distance": route['legs'][0]["distance"]['value'],
            "duration": route['legs'][0]["duration"]['value'],
            "duration_in_traffic":
                durationtraffic != null
                    ? durationtraffic['value']
                    : route['legs'][0]["duration"]['value'],
            "start_address": route['legs'][0]["start_address"], // start address
            "end_address": route['legs'][0]["end_address"], //end address
          });
        }
        finalrouteDetail = {
          "direction_Mdata": response.data,
          "polyline_allroutes": allRoutes,
          "filter_data": finaloverviewdetail,
        };
        return finalrouteDetail;
      } else {
        throw Exception("Failed to fetch Direction data.");
      }
    } catch (e) {
      throw Exception("Direction API Error: $e");
    }
  }

  ///------------------------------------
  /// Call AQI API using Dio via WAQI
  /// -----------------------------------

  ///------------------------------------
  /// Call AQI API using Dio via Google Api
  /// -----------------------------------
  Future<Map<String, dynamic>> fetchAqiByLocationViaGoogle({
    required double lat,
    required double lng,
  }) async {
    const String apiKey =
        Constantkey.GOOGLE_MAP_API_KEY; // Replace with your key
    final String url =
        "https://airquality.googleapis.com/v1/currentConditions:lookup?key=$apiKey";

    try {
      final response = await _dio.post(
        url,
        data: {
          "universalAqi": true,
          "location": {"latitude": lat, "longitude": lng},
          "extraComputations": [
            "HEALTH_RECOMMENDATIONS",
            "DOMINANT_POLLUTANT_CONCENTRATION",
            "POLLUTANT_CONCENTRATION",
            // "LOCAL_AQI",
            // "POLLUTANT_ADDITIONAL_INFO",
          ],
          "languageCode": "en",
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['indexes'] != null && data['indexes'].isNotEmpty) {
          return {
            'aqi': data['indexes'][0]['aqi'],
            'color': data['indexes'][0]['color'],
            'category': data['indexes'][0]['category'],
            'dominantPollutant': data['indexes'][0]['dominantPollutant'],
            'pollutants': data['pollutants'],
            'healthRecommendations': data['healthRecommendations'],
          };
        } else {
          throw Exception("AQI data is empty or malformed.");
        }
      } else {
        throw Exception(
          "Google AQI API returned error: ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Google AQI API Error: $e");
    }
  }

  ///------------------------------------
  /// Fetch More Predise Address Detail From lat-Lng  Using Google Address Api
  /// -----------------------------------
  Future<Map> fetchAddressFromLatLngGAPi(double lat, double lng) async {
    const String apiKey = Constantkey.GOOGLE_MAP_API_KEY; // Validate API Key
    if (apiKey.isEmpty) {
      return {
        "status": false,

        "detail":
            "Error: Please replace 'YOUR_API_KEY' with your actual Google Maps API Key.",
      };
    }
    // Construct the API URL
    final String apiUrl =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey';

    try {
      // Make the HTTP GET request
      final response = await _dio.get(apiUrl);

      // Check if the request was successful (status code 200)
      if (response.statusCode == 200) {
        // Parse the JSON response
        final Map<String, dynamic> data = response.data;

        // Check the status from the API response
        if (data['status'] == 'OK' &&
            data['results'] != null &&
            data['results'].isNotEmpty) {
          // Return the formatted address
          return {
            "status": true,
            "detail": data['results'][0]['formatted_address'],
            'latlng': LatLng(lat, lng),
          };
        } else if (data['status'] == 'ZERO_RESULTS') {
          return {
            "status": false,
            "detail": "No address found for these coordinates.",
          };
        } else {
          // Handle other API statuses or errors
          String errorMessage = data['error_message'] ?? 'Unknown error';
          print(
            "Geocoding API error: $errorMessage (Status: ${data['status']})",
          );
          getAddressFromLatLng(LatLng(lat, lng));
          return {
            "status": true,
            "detail": await getAddressFromLatLng(LatLng(lat, lng)),
            'latlng': LatLng(lat, lng),
          };
        }
      } else {
        // Handle non-200 HTTP responses
        print("HTTP Error: ${response.statusCode} ");
        return {
          "status": false,
          "detail":
              "HTTP Error: ${response.statusCode}. Could not connect to the geocoding service.",
        };
      }
    } catch (e) {
      // Handle network errors or other exceptions
      print("Network or API call error: $e");
      return {
        "status": false,
        "detail": "Network error: $e. Please check your internet connection.",
      };
    }
  }
}
