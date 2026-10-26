import 'dart:developer' as dev;
import 'dart:math';
import 'package:aqi_app/constants/color_constant.dart';
import 'package:aqi_app/data/local/HiveLDB/HiveModel/AQIBulkDataHistory.dart';
import 'package:aqi_app/data/models/comman_aqi_model.dart';
import 'package:aqi_app/data/repository/MapScreen_repositry/MapScreen_repositary.dart';
import 'package:aqi_app/data/repository/MapScreen_repositry/aqi_channel.dart';
import 'package:aqi_app/data/request/allAPIs.dart';
import 'package:aqi_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import '../../../constants/image_constant.dart';
import '../../models/aqi_circle_model.dart';

class CheckAqiRepo {
  // --- Configuration ---
  final MapScreenRepository _mapScreenRepository = MapScreenRepository();

  final TextEditingController startCtrl = TextEditingController();
  static const double totalRadiusInMeters = 5000.0; // 5 km total radius
  static const double samplePointRadius = 2500.0; // 2.5 km for sample points

  static const LatLng _defaultLocation = LatLng(22.7196, 75.8577);
  final AQIHeatmapHelper heatmapHelper = AQIHeatmapHelper();
  final List<WeightedLatLng> heatmapPoints = [];
  LatLng centerLocation = _defaultLocation;
  final Set<Marker> markers = {};
  final Set<Circle> circles = {};
  // Add a state variable for the heatmap
  final Set<Heatmap> heatmaps = {};
  String statusMessage = "Initializing...";

  Map<String, dynamic> datastate = {};
  bool ispointloading = false;
  bool pointsGenerated = false;
  List<CommanDetailAqiModel> tempAqistorage = [];
  List<Map> pinpointdetail = [];
  final ValueNotifier<int> curIndexHorList = ValueNotifier<int>(0);
  final List<LatLng> samplePoints = [];

  /// Dispose Perivious data;
  disposemyTempData() {
    markers.removeAll;
    circles.removeAll;
    heatmaps.removeAll;
    statusMessage = "Initializing...";
    datastate.remove;
    samplePoints.clear();
    ispointloading = false;
    pointsGenerated = false;
    tempAqistorage.clear();
    pinpointdetail.clear();
    curIndexHorList.value = 0;
  }

  /// Fetches the user's current GPS location.
  Future<void> checkpermissionNgetUserLocation() async {
    try {
      // setState(() {
      //   statusMessage = "Fetching location...";
      // });

      final position = await _mapScreenRepository.getCurrentPosition();
      centerLocation = LatLng(position.latitude, position.longitude);
      startCtrl.text = await _mapScreenRepository.getAddressFromLatLng(
        centerLocation,
      );
      statusMessage = "Location found. Ready to generate AQI Status";
      // _setupMapWithCenter();
    } catch (e) {
      statusMessage = "Could not get location. Using default.";
      centerLocation = _defaultLocation;
      startCtrl.text = await _mapScreenRepository.getAddressFromLatLng(
        centerLocation,
      );
      // _setupMapWithCenter();
    }
  }

  /// Generates the n strategic points and creates a heatmap from their simulated AQI values.
  Future<void> generatePointsAndHeatmap(centerLocation) async {
    // Clear any previously generated points and heatmaps
    markers.clear();
    heatmaps.clear();
    heatmapPoints.clear();
    dev.log("checking central location: $centerLocation");
    this.centerLocation = centerLocation;
    // --- Point 1: Center ---
    samplePoints.add(centerLocation);

    // --- Points 2-5: Cardinal Directions ---
    samplePoints.add(
      _calculateDestinationPoint(centerLocation, samplePointRadius, 0),
    ); // North
    samplePoints.add(
      _calculateDestinationPoint(centerLocation, samplePointRadius, 90),
    ); // East
    samplePoints.add(
      _calculateDestinationPoint(centerLocation, samplePointRadius, 180),
    ); // South
    samplePoints.add(
      _calculateDestinationPoint(centerLocation, samplePointRadius, 270),
    ); // West
    // predicted Points
    /// point on 60 degree intersection
    samplePoints.add(
      calculateEquilateralTriangleP3(samplePoints[1], samplePoints[2])[1],
    );

    /// point on 60 degree intersection
    samplePoints.add(
      calculateEquilateralTriangleP3(samplePoints[2], samplePoints[3])[1],
    );

    /// point on 60 degree intersection
    samplePoints.add(
      calculateEquilateralTriangleP3(samplePoints[3], samplePoints[4])[1],
    );

    /// point on 60 degree intersection
    samplePoints.add(
      calculateEquilateralTriangleP3(samplePoints[4], samplePoints[1])[1],
    );

    // --- Simulate AQI and create markers and heatmap data ---
    dev.log("my markers: ${markers.length} $markers ${samplePoints[0]}");
    await removeMarkerByIndex(0);
    _addMarkerForPoint(
      samplePoints.first,
      await _getSimulatedAqiForPointNew(samplePoints.first),
      0,
      title: "Search Point",
    );
    dev.log(
      "after my markers: ${markers.length} $markers ${samplePoints.length}",
    );
    num aqitotal = 0;
    for (int i = 0; i < samplePoints.length; i++) {
      final point = samplePoints[i];
      final aqi = await _getSimulatedAqiForPointNew(point);
      aqitotal += aqi;
      dev.log("$i my aqi$aqi");
      heatmapPoints.add(WeightedLatLng(point, weight: aqi.toDouble()));
      // Add a marker for the sample point
      // _addMarkerForPoint(point, aqi, i);
    }

    // --- Create and add the heatmap layer ---
    heatmaps.add(
      heatmapHelper.buildHeatmap(data: heatmapPoints, radiusPixels: 45),
    );
    statusMessage = "Generated AQI And sampling heatmap";
    pointsGenerated = true;
    ispointloading = false;
    var aireccondation = await AQIChannel().getfullRecommendationsForAQI(
      aqitotal ~/ samplePoints.length,
    );
    dev.log("jkdate res: $aireccondation");
    datastate = {
      "aqi": aqitotal / samplePoints.length,
      "dominent_pollutent": tempAqistorage[0].dominantPollutant,
      "recomandation": aireccondation['recommendations'],
      "category": aireccondation['category'],
      "tips":
          "Just tap the circle to check the air quality and breathe safer wherever you are.",
    };
  }

  onTapMapPoint(LatLng mytap, context) async {
    // create marker

    _addMarkerForPoint(
      mytap,
      tempAqistorage[0].aqi!,
      -1,
      image: 'assets/images/transprentmarker.gif',
      title: "loading..",
    );
    // dev.log("distinbetween: $distinbetween");
    // checkdistance from centriod
    final distinbetween = Geolocator.distanceBetween(
      mytap.latitude,
      mytap.longitude,
      centerLocation.latitude,
      centerLocation.longitude,
    );
    dev.log("distinbetween: $distinbetween");
    if (distinbetween < 5000) {
      // check nearest point
      final int index = findClosestLatLngIndex(mytap, samplePoints);
      dev.log("closed index: $index");
      // showdetail of check point
      final newLat = (mytap.latitude * 100).round() / 10; // 28.61
      final newLng = (mytap.longitude * 100).round() / 10; // 77.21

      pinpointdetail.add({
        "$newLat,$newLng": {
          "fulladdress": await _mapScreenRepository.getAddressFromLatLng(mytap),
          "distancebtwn": distinbetween,
          "aqidetail": tempAqistorage[index],

          // "custom_category":
        },
      });
      removeMarkerByIndex(-1);
      _addMarkerForPoint(
        mytap,
        tempAqistorage[index].aqi!,
        100 + index,
        image: 'assets/images/pin.png',
        title: "Tap Point",
      );
      ispointloading = false;
      curIndexHorList.value = pinpointdetail.length;
    } else {
      curIndexHorList.value = 0;
      ispointloading = false;
      removeMarkerByIndex(-1);
      UtilDialog.showInformation(
        context,
        title: "Point Out of range",
        content: "please tap under the circle boundry",
      );
    }
  }

  /// Find a closest distance between two points
  int findClosestLatLngIndex(LatLng source, List<LatLng> points) {
    double minDistance = double.infinity;
    int minIndex = -1;

    for (int i = 0; i < points.length; i++) {
      final distance = _calculateHaversineDistance(
        source.latitude,
        source.longitude,
        points[i].latitude,
        points[i].longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        minIndex = i;
      }
    }

    return minIndex;
  }

  /// Helper: Haversine formula in kilometers
  double _calculateHaversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371.0; // in km

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degree) {
    return degree * pi / 180;
  }

  /// Adds a single marker to the map with its AQI value in the info window.
  void _addMarkerForPoint(
    LatLng point,
    num aqi,
    int index, {
    String? image,
    String? title,
  }) async {
    bool added = markers.add(
      Marker(
        markerId: MarkerId('point_$index'),
        position: point,
        icon:
            index == 0
                ? await BitmapDescriptor.asset(
                  ImageConfiguration(size: Size(48, 48)),
                  IMAGECONST.START_POINT,
                  width: 48,
                  height: 48,
                )
                : image != null
                ? await BitmapDescriptor.asset(
                  ImageConfiguration(size: Size(48, 48)),
                  image,
                  width: 45,
                  height: 45,
                )
                : BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
        onTap: () => updatecurrentIndexvalue(point),
        infoWindow: InfoWindow(
          title: title,
          snippet: 'Accumulated AQI: ${aqi.toStringAsFixed(2)}',
        ),
      ),
    );
    dev.log("added: $added $point");
  }

  Future<void> removeMarkerByIndex(int index) async {
    final markerId = MarkerId('point_$index');
    markers.removeWhere((marker) => marker.markerId == markerId);
    // Trigger rebuild if you want immediate UI update
  }

  updatecurrentIndexvalue(LatLng mytap) {
    final newLat = (mytap.latitude * 100).round() / 10; // 28.61
    final newLng = (mytap.longitude * 100).round() / 10; // 77.21
    final index = pinpointdetail.indexWhere(
      (map) => map.containsKey('$newLat,$newLng'),
    );
    curIndexHorList.value = index + 1; // Notifies listeners!
  }

  /// **Placeholder Method:** Simulates getting an AQI value for a point.
  /// In a real app, you would replace this with your actual data fetching logic.
  // Future<num> _getSimulatedAqiForPoint(LatLng point) async {
  //   // Returns a random value between 20 and 180 for demonstration.
  //   try {
  //     Aqibulkdatahistory? checkdata = await getNCheckOldAqiDataforGoogle(point);
  //     if (checkdata == null) {
  //       var data = await _mapScreenRepository.fetchAqiByLocation(
  //         lat: point.latitude,
  //         lng: point.longitude,
  //       );
  //       final aqistatusrec = await AQIChannel().getfullRecommendationsForAQI(
  //         data['aqi'],
  //       );
  //       data["extand_data"] = aqistatusrec;
  //       _mapScreenRepository.addAqiDataToLocalHiveDataDB(data, point, 1);
  //       final aqidata = CommanDetailAqiModel.fromWAQI(data);
  //       tempAqistorage.add(aqidata);
  //       return data['aqi'].toDouble();
  //     } else {
  //       if (checkdata.apiType == 0) {
  //         var aqifdata = checkdata.aqidetailjsondata;
  //         var forcastdata = await _mapScreenRepository.fetchAqiByLocation(
  //           lat: point.latitude,
  //           lng: point.longitude,
  //         );
  //         // await _getSimulatedAqiForPoint(forcastdata['forecast']['daily']);
  //         aqifdata['extand_data'] = forcastdata['forecast']['daily'];
  //         final aqidata = CommanDetailAqiModel.fromGoogle(aqifdata);
  //         tempAqistorage.add(aqidata);
  //         return aqidata.aqi!;
  //       } else {
  //         final aqidata = CommanDetailAqiModel.fromWAQI(
  //           checkdata.aqidetailjsondata,
  //         );
  //         tempAqistorage.add(aqidata);
  //         return aqidata.aqi!;
  //       }
  //     }
  //   } on Exception catch (e) {
  //     dev.log("expe:$e");
  //     return 0.0;
  //   }
  // }

  Future<num> _getSimulatedAqiForPointNew(LatLng point) async {
    // Returns a random value between 20 and 180 for demonstration.
    try {
      final aqi = await AllAPIRequest.fetchAqiByLocationViaGoogle(
        lat: point.latitude,
        lng: point.longitude,
        detailedResponse: true,
      );
      final aqidata = CommanDetailAqiModel.fromGoogleNew(aqi);
      tempAqistorage.add(aqidata);
      return aqi.aqi;
    } on Exception catch (e) {
      dev.log("expe:$e");
      return 0.0;
    }
  }

  /// Calculates a destination point given a start point, distance, and bearing.
  LatLng _calculateDestinationPoint(
    LatLng startPoint,
    double distanceMeters,
    double bearingDegrees,
  ) {
    const double earthRadius = 6371000; // in meters
    final double lat1 = vector.radians(startPoint.latitude);
    final double lon1 = vector.radians(startPoint.longitude);
    final double brng = vector.radians(bearingDegrees);
    final double d = distanceMeters / earthRadius;
    dev.log("initvalue: $lat1 $lon1 $brng $d");
    final double lat2 = asin(
      sin(lat1) * cos(d) + cos(lat1) * sin(d) * cos(brng),
    );

    final double lon2 =
        lon1 +
        atan2(sin(brng) * sin(d) * cos(lat1), cos(d) - sin(lat1) * sin(lat2));
    dev.log(
      "calc. : ${sin(lat1)} $lat2 $lon2 ${atan2(sin(brng) * sin(d) * cos(lat1), cos(d) - sin(lat1) * sin(lat2)).toString()}",
    );
    return LatLng(vector.degrees(lat2), vector.degrees(lon2));
  }

  double degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  double radiansToDegrees(double radians) {
    return radians * 180.0 / pi;
  }

  LatLng calculateDestinationPointviatwopoints(
    LatLng startPoint,
    double bearingDegrees,
    double distanceMeters,
  ) {
    const double earthRadius = 6371000; // meters
    final double bearing = bearingDegrees * pi / 180;

    final double lat1 = startPoint.latitude * pi / 180;
    final double lon1 = startPoint.longitude * pi / 180;

    final double lat2 = asin(
      sin(lat1) * cos(distanceMeters / earthRadius) +
          cos(lat1) * sin(distanceMeters / earthRadius) * cos(bearing),
    );

    final double lon2 =
        lon1 +
        atan2(
          sin(bearing) * sin(distanceMeters / earthRadius) * cos(lat1),
          cos(distanceMeters / earthRadius) - sin(lat1) * sin(lat2),
        );

    return LatLng(lat2 * 180 / pi, lon2 * 180 / pi);
  }

  /// Calculate both possible P3 points for an equilateral triangle.
  List<LatLng> calculateEquilateralTriangleP3(LatLng p1, LatLng p2) {
    // 1. Compute side length
    final double sideLength = Geolocator.distanceBetween(
      p1.latitude,
      p1.longitude,
      p2.latitude,
      p2.longitude,
    );

    if (sideLength == 0) {
      throw Exception('P1 and P2 are the same point.');
    }

    // 2. Compute base bearing P1 -> P2
    final double bearingP1P2 = Geolocator.bearingBetween(
      p1.latitude,
      p1.longitude,
      p2.latitude,
      p2.longitude,
    );

    // 3. Compute ±60° offsets
    final double bearingOption1 = (bearingP1P2 + 60) % 360;
    final double bearingOption2 = (bearingP1P2 - 60 + 360) % 360;

    // 4. Compute the two possible P3 points
    final LatLng p3Option1 = calculateDestinationPointviatwopoints(
      p1,
      bearingOption1,
      sideLength,
    );
    final LatLng p3Option2 = calculateDestinationPointviatwopoints(
      p1,
      bearingOption2,
      sideLength,
    );

    return [p3Option1, p3Option2];
  }

  int calculateHeatmapRadiusPixels({
    required double latitude,
    required double zoomLevel,
    required double desiredMeters,
  }) {
    final metersPerPixel =
        156543.03392 * cos(latitude * pi / 180) / pow(2, zoomLevel);

    final radiusInPixels = desiredMeters / metersPerPixel;

    return radiusInPixels.round();
  }

  double calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    // Simple haversine
    const R = 6371000;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double estimateAQI(AQIPoint target, List<AQIPoint> knownPoints, {int k = 3}) {
    final distances =
        knownPoints.where((p) => p.aqi != null).map((p) {
            final d =
                calculateDistanceMeters(target.lat, target.lng, p.lat, p.lng)
                    as num;
            return {'point': p, 'distance': d};
          }).toList()
          ..sort(
            (a, b) => (a['distance'] as num).compareTo(b['distance']! as num),
          );

    final nearest = distances.take(k);

    double weightedSum = 0;
    double totalWeight = 0;

    for (var entry in nearest) {
      final p = entry['point'] as AQIPoint;
      final Object d = entry['distance']!;

      if (d == 0) {
        return p.aqi!; // Exact same point
      }

      final weight = 1 / ((d as double) * d); // IDW with squared distance
      weightedSum += weight * p.aqi!;
      totalWeight += weight;
    }

    return weightedSum / totalWeight;
  }

  Future getNCheckOldAqiDataforGoogle(latlng) async {
    try {
      final aqibox = Hive.box<Aqibulkdatahistory>('aqi_bulk_history');
      final newLat = (latlng.latitude * 100).round() / 100; // 28.61
      final newLng = (latlng.longitude * 100).round() / 100; // 77.21
      final curenttime = DateTime.now();
      final onlyDate = DateFormat("dd/MM/yyyy").format(curenttime);
      final hour = DateFormat('hh').format(curenttime);
      final key = '$newLat,${newLng}_${onlyDate}_$hour';
      dev.log("myKey to fetch: $key");
      if (aqibox.containsKey(key)) {
        dev.log("yes contain");
        return aqibox.get(key);
      } else {
        dev.log("No direction data found for key: $key");
        return null;
      }
    } catch (e) {
      dev.log("Error in getNCheckOldDataDirection: $e");
      return null;
    }
  }

  /// Pridict aqi as per forest report

  List<Map<String, dynamic>> generateUpcomingAqiForecast(input) {
    final pm10List = input['pm10'] as List<dynamic>;
    final pm25List = input['pm25'] as List<dynamic>;
    final uviList = input['uvi'] as List<dynamic>;

    final List<Map<String, dynamic>> results = [];

    final today = DateTime.now().add(Duration(days: 1));

    for (var i = 0; i < pm10List.length; i++) {
      final dayStr = pm10List[i]['day'] as String;
      final date = DateTime.parse(dayStr);

      // Only today or future
      if (date.isBefore(DateTime(today.year, today.month, today.day))) {
        continue;
      }

      final pm10 = pm10List[i]['avg'] as num;
      final pm25 = pm25List.length > i ? pm25List[i]['avg'] as num : 0;
      final uvi = uviList.length > i ? uviList[i]['avg'] as num : 0;

      // Basic: normalize UVI to scale of 0-100 (max UVI ~ 10-11)
      final normalizedUvi = (uvi * 10).clamp(0, 100);

      // Weighted AQI
      final estimatedAqi = (pm25 * 0.6) + (pm10 * 0.3) + (normalizedUvi * 0.1);

      final dayOfWeek = DateFormat('EEE').format(date);

      results.add({
        'date': dayStr,
        'day': dayOfWeek,
        'aqi': estimatedAqi.round(),
        'bgcolor': aqicolor(estimatedAqi.round()),
      });
    }

    return results;
  }

  Color aqicolor(aqivalue) {
    if (aqivalue < 50) {
      return COLOR_CONST.aqiheatcolors[0];
    } else if (aqivalue < 100) {
      return COLOR_CONST.aqiheatcolors[1];
    } else if (aqivalue < 200) {
      return COLOR_CONST.aqiheatcolors[2];
    } else if (aqivalue < 300) {
      return COLOR_CONST.aqiheatcolors[3];
    } else {
      return COLOR_CONST.aqiheatcolors[4];
    }
  }

  /// this code for auto generation
  ///
}

class BucketPointsResult {
  final List<LatLng> allCoordinates;
  final List<LatLng> aqiCoordinates;

  BucketPointsResult(this.allCoordinates, this.aqiCoordinates);
}
