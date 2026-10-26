import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';

import 'package:aqi_app/configs/PemissionHandler.dart';
import 'package:aqi_app/configs/navigationservices.dart';
import 'package:aqi_app/constants/color_constant.dart';
import 'package:aqi_app/data/local/HiveLDB/HiveModel/CurrentRideRoute.dart';
import 'package:aqi_app/data/local/HiveLDB/HiveModel/MainNavigationHistory.dart';
import 'package:aqi_app/data/local/HiveLDB/Hive_DataRetival.dart';
import 'package:aqi_app/data/models/aqi_circle_model.dart';
import 'package:aqi_app/data/models/aqi_responses.dart';
import 'package:aqi_app/data/models/route_option.dart';
import 'package:aqi_app/data/repository/MapScreen_repositry/MapScreen_repositary.dart';
import 'package:aqi_app/data/request/allAPIs.dart';
import 'package:aqi_app/utils/Background_services/Background_services_mtd.dart';
import 'package:aqi_app/utils/geo_utils.dart';
import 'package:aqi_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;

import '../../../constants/image_constant.dart';
import '../../../presentation/screens/auto_aqiroute_screen/aqi_routes_widgets.dart';
import '../../models/aqi_point.dart';

class AqiRouteRepository {
  final geoUtil = GeoUtils();
  StreamSubscription<loc.LocationData>? locationSubscription;
  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {};
  List<RouteOption> finalroutesDetail = [];
  final Set<Heatmap> heatmaps = {};
  List<String> sessionsavedID = [];
  Circle? circle;
  late double radiusKm;
  // Transport mode
  TransportMode tMode = TransportMode.Bicycling;
  final StreamController<double> progress =
      StreamController<double>.broadcast();
  // candidate points (excluding center at index 0)
  final List<AqiPoint> aqicandidates = [];
  // computed route options
  final List<RouteOption> routes = [];

  // tuning
  final double stepDistanceKm =
      0.4; // denser grid step (short distance for more accuracy)
  final int beamWidth = 120; // beam width to prune combinatorics
  final int topK = 5; // final number of routes to fetch full Directions for

  late AqiPoint centerPoint;
  RouteOption? selectedRoute;

  // filter mode: 'aqi' | 'distance' | 'traffic'
  final String filterMode = 'aqi';

  final Random _random = Random();

  Future<AqiResponse> fetchAqiForPoint(LatLng point) async {
    return AllAPIRequest.fetchAqiByLocationViaGoogle(
      lat: point.latitude,
      lng: point.longitude,
      detailedResponse: true,
    );
  }

  Future<List<AqiPoint>> generateAnchors(LatLng center, double radiusKm) async {
    final List<AqiPoint> anchors = [];
    double stepKm = 0.7;
    double currentDist = stepKm;
    int ringIndex = 0;
    int idCounter = 0;

    while (currentDist <= radiusKm) {
      final bearings =
          ringIndex % 2 == 0 ? [0, 90, 180, 270] : [45, 135, 225, 315];
      for (final b in bearings) {
        final pos = GeoUtils.destinationPoint(
          center,
          b.toDouble(),
          currentDist,
        );
        final aqi = await fetchAqiForPoint(pos);
        anchors.add(
          AqiPoint(
            id: 'anchor-${idCounter++}',
            pos: pos,
            aqi: aqi.aqi.toDouble(),
          ),
        );
      }
      currentDist += stepKm;
      if (currentDist > 2 && stepKm == 0.7) stepKm = 1;
      if (currentDist > 4 && stepKm == 1.4) stepKm = 1.4;
      ringIndex++;
    }
    return anchors;
  }

  double calculateAvgAqi(List<AqiPoint> pts) =>
      pts.isEmpty
          ? 0
          : pts.map((p) => p.aqi).reduce((a, b) => a + b) / pts.length;

  double estimateDistance(List<AqiPoint> pts) {
    double dist = 0;
    for (int i = 0; i < pts.length - 1; i++) {
      dist += GeoUtils.haversineKm(pts[i].pos, pts[i + 1].pos);
    }
    return dist;
  }

  Future<Marker> markerForAqiPoint(
    AqiPoint ap, {
    bool isactual = false,
    String? mycustomimage,
    Size? mysize,
  }) async {
    final h = geoUtil.aqiToHue(ap.aqi);
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

  Future<Map<String, dynamic>> generateDensePointsAndAqiMarkersHeatmap() async {
    markers.clear();
    aqicandidates.clear();
    heatmaps.clear();
    final centerpoint = centerPoint.pos;
    final aqipointcenter = AqiPoint(
      aqi: await fetchAqiForPoint(centerpoint).then((e) => e.aqi.toDouble()),
      id: 'center',
      pos: centerpoint,
    );
    centerPoint = aqipointcenter;
    aqicandidates.add(aqipointcenter);
    // === Center marker ===
    markers.add(
      await markerForAqiPoint(
        aqipointcenter,
        isactual: true,
        mycustomimage: IMAGECONST.START_POINT,
      ),
    );
    // markers.add(
    //   Marker(
    //     markerId: const MarkerId('center'),
    //     position: centerpoint,
    //     icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    //     infoWindow: const InfoWindow(title: 'Center (Start)'),
    //   ),
    // );

    // === Anchor AQI points ===
    final standarddata = await GeoUtils().generateStandardAnchors(
      centerpoint,
      radiusKm,
    ); //return  [anchors, heatmapPoints, markers]
    print("OG AQI Points: " + standarddata[0].toList().length.toString());
    // === Actual AQI Points ===
    aqicandidates.addAll(standarddata[0]);

    // === Heatmap overlay ===
    heatmaps.add(
      AQIHeatmapHelper().buildHeatmap(data: standarddata[1], radiusPixels: 50),
    );
    // === Actual AQI Marker ===
    markers.addAll(standarddata[2]);

    // === Dense candidate points ===
    final generated = await GeoUtils().generateDenseCandidatePoints(
      centerpoint,
      radiusKm,
    );

    // === Interpolate AQI ===
    final denseCandidates = await GeoUtils().assignInterpolatedAqiToCandidates(
      generated,
      aqicandidates,
    );

    aqicandidates.addAll(denseCandidates);

    aqicandidates.sort((a, b) {
      final distA = GeoUtils.haversineKm(centerpoint, a.pos);
      final distB = GeoUtils.haversineKm(centerpoint, b.pos);
      return distA.compareTo(distB); // nearest → farthest
    });
    // final aqipointsortlist = geoUtil.sortByDistanceFromCenter(
    //   aqicandidates,
    //   aqicandidates[0],
    // );
    // aqicandidates.clear();
    // aqicandidates.addAll(aqipointsortlist);
    debugPrint("Total AQI points: ${aqicandidates.length}");
    return {"markers": markers, "heatmaps": heatmaps};
  }

  // -----------------------
  // 4) Generate route candidates (dense combinations), filter & draw
  // -----------------------

  Future<List<RouteOption>> generateRouteCandidatesAndDraw({
    required LatLng center,
    required double radiusKm,
    int kTop = 4,
  }) async {
    polylines.clear();
    final List<RouteOption> planRoutesCandidates = [];

    if (aqicandidates.isEmpty) return planRoutesCandidates;
    final int maxStops = geoUtil.calculateMaxStops(
      radiusKm,
      stepDistance: stepDistanceKm,
    );
    debugPrint("My MaxStops: $maxStops");
    // clamp max stops to a safe range
    final minStops = 3;
    final maxStopsCap = maxStops.clamp(minStops, maxStops);
    final allPoints = List<AqiPoint>.from(aqicandidates);
    debugPrint("My all Points: ${allPoints.length}");
    final combos = <List<AqiPoint>>[];
    final double neededDistanceKm = radiusKm; // or another target distance
    final double minDistanceToCover = neededDistanceKm * 0.8;
    // greedy approach: build one path for each stop count
    for (int k = 0; k <= maxStopsCap; k++) {
      final greedyPath = <AqiPoint>[];
      // start at center
      AqiPoint current = centerPoint;
      greedyPath.add(current);
      double pathDistance = 0.0;
      int previuslayer = 0;
      for (int step = 0; step <= maxStops; step++) {
        // pick the next best point based on lowest AQI + closest distance
        int skipCount = ((aqicandidates.length / maxStops) * step).floor();
        int curentstart = skipCount.clamp(
          previuslayer,
          aqicandidates.length - 1,
        );
        AqiPoint? next = geoUtil.findBestNextPoint2(
          current,
          allPoints,
          greedyPath,
          combos,
          minSeparationKm: 0.6,
          startfrompoint: curentstart,
        );
        print("path distance $step $k $pathDistance $curentstart");
        if (next == null) break;
        greedyPath.setRange(
          1,
          greedyPath.length,
          (greedyPath.sublist(1)..sort((a, b) {
            final idA = int.parse(a.id.split('-').last);
            final idB = int.parse(b.id.split('-').last);
            return idA.compareTo(idB); // ascending
          })),
        );
        greedyPath.add(next);
        if (greedyPath.length >= 2) {
          pathDistance = GeoUtils.haversineKm(
            greedyPath[0].pos,
            greedyPath[greedyPath.length - 1].pos,
          );
        }

        current = next;
        // ✅ stop early if we’ve already covered 80% of needed distance
        if (pathDistance >= minDistanceToCover) break;
      }
      // if (pathDistance >= minDistanceToCover) {
      // }
      combos.add(greedyPath);
    }

    final List<RouteOption> rawRoutes = [];

    // build route variants (loop + path) from greedy combos
    for (var combo in combos) {
      if (combo.isEmpty) continue;

      var loopPoints = [
        centerPoint, //?? AqiPoint.fromLatLng(center),
        ...geoUtil.sublistUntilDistance(
          AqiPoint.fromLatLng(center),
          combo,
          0.25,
          radiusKm,
        ),
      ];

      final optimizedloop = geoUtil.reduceWaypointsWithinDistance(
        loopPoints,
        minPoints: 2,
        maxPoints: 3,
        maxDistanceMeters: radiusKm * 1000 * 1.4,
      );
      loopPoints = optimizedloop;

      var pathPoints = [centerPoint, ...combo.skip(1)];

      final optimizedpath = geoUtil.reduceWaypointsWithinDistance(
        pathPoints,
        minPoints: 3,
        maxPoints: 5,
        maxDistanceMeters: radiusKm * 1000 * 1.3,
        minSpacingMeters:
            radiusKm > 2 ? (radiusKm * 1000) / 5 : (radiusKm * 1000) / 3,
      );
      pathPoints = optimizedpath;

      // pathPoints = geoUtil.optimizeRoutePoints(
      //   pathPoints,
      //   simplifyToleranceMeters: 100,
      //   minSpacingMeters: toleranceinMeter,
      // );

      final loopRoute = RouteOption(
        id: 'loop_${combo.hashCode}',
        points: loopPoints,
        isLoop: true,
        routeColor: Colors
            .primaries[combos.indexOf(combo) % Colors.primaries.length]
            .withOpacity(0.8),
      );
      final pathRoute = RouteOption(
        id: 'path_${combo.hashCode}',
        points: pathPoints,
        isLoop: false,
        routeColor: Colors
            .primaries[combos.indexOf(combo) % Colors.primaries.length]
            .withOpacity(0.8),
      );

      // compute stats
      loopRoute.avgAqi = geoUtil.calculateAvgAqi(loopPoints);
      pathRoute.avgAqi = geoUtil.calculateAvgAqi(pathPoints);
      print(
        "my loop avragare: ${loopPoints.map((e) => e.aqi).toList().toString()} ${pathPoints.map((e) => e.aqi).toList().toString()}",
      );
      loopRoute.distanceKm = geoUtil.estimateDistance(loopPoints);
      pathRoute.distanceKm = geoUtil.estimateDistance(pathPoints);
      // debugPrint(
      //   "distance estimation: loop: ${loopRoute.points.length} ${loopRoute.distanceKm} non-loop: ${pathRoute.points.length} ${pathRoute.distanceKm} ",
      // );

      // validate against radius
      if (geoUtil.isValidRoute(loopRoute, radiusKm)) rawRoutes.add(loopRoute);
      if (geoUtil.isValidRoute(pathRoute, radiusKm)) rawRoutes.add(pathRoute);

      // beam limit safeguard
      if (rawRoutes.length > beamWidth * 2) break;
    }
    Random random = Random();
    debugPrint("before suffle: ${rawRoutes.length}");
    final List<RouteOption> uniqueRoutes =
        rawRoutes.uniqueByProperties()..shuffle(random);
    debugPrint("after suffle: ${uniqueRoutes.length}");
    // final scoring & selection
    geoUtil.scoreAndSortRoutes(uniqueRoutes, filterMode);
    debugPrint("myrowroutes: ${rawRoutes.length}");
    final balanced = geoUtil.pickBalancedTopK(uniqueRoutes, kTop);
    // draw polylines
    for (int i = 0; i < balanced.length; i++) {
      final ro = balanced[i];
      final poly = Polyline(
        polylineId: PolylineId(ro.id),
        points: ro.points.map((p) => p.pos).toList(),
        width: 4 + (6 - (i % 6)),
        color: Colors.primaries[i % Colors.primaries.length].withOpacity(0.8),
        consumeTapEvents: true,
        onTap: () => onPolylineTapped(ro),
      );
      ro.polyline = poly;
      polylines.add(poly);
    }
    return balanced;
  }

  //------------------------
  // fetch direction on routes
  //------------------------

  Future<List<RouteOption>> fetchDirectionsForRoute(
    RouteOption ro, {
    String mode = 'walking',
    double distance = 0,
  }) async {
    // Use Google Directions API to get accurate route polyline, distance & duration.
    // Note: This is optional: you'll need a billing-enabled API key that allows Directions API.

    final origin = ro.points.first.pos;
    final destination = ro.points.last.pos;
    final waypoints =
        ro.points.length > 2
            ? ro.points
                .sublist(1, ro.points.length - (ro.isLoop ? 1 : 0))
                .map((p) => '${p.pos.latitude},${p.pos.longitude}')
                .join('|')
            : null;

    final response = await AllAPIRequest.fetchDirectionByLocation(
      origin: origin,
      destination: destination,
      mode: mode,
      alternatives: true,
      waypoints: (waypoints != null) ? waypoints : '',
      departureTime: 'now',
    );
    // double distanceKm = distanceMeters / 1000.0;
    polylines.removeWhere((pl) => pl.polylineId.value == ro.id);
    for (var i = 0; i < response.polylineAllRoutes.length; i++) {
      Set<Marker> croutemarker = {};
      ro.distanceKm = (response.filterData[i].distance / 1000).toDouble();
      ro.duration = Duration(seconds: response.filterData[i].duration);
      ro.trafficInfo =
          classifyTraffic(
            (response.filterData[i].durationInTraffic ?? 0) /
                (response.filterData[i].duration ?? 0),
          )[0];

      ro.id = "${ro.id}-${response.uid}-${i.toString()}";
      // update polyline with the fetched path

      List<LatLng> mypolycorditate =
          ro.isLoop
              ? [
                ...response.polylineAllRoutes[i],
                // ...response.polylineAllRoutes[i].reversed.skip(1),
              ]
              : response.polylineAllRoutes[i];
      if (!ro.isLoop && ro.distanceKm > distance) {
        debugPrint("I am here : " + ro.toString());
        var updateddata = trimRouteByDistanceAndMode(
          route: mypolycorditate,
          maxDistanceKm: distance * 1.1,
          mode: mode,
        );
        ro.distanceKm = updateddata.distanceKm;
        ro.duration = Duration(minutes: updateddata.durationMinutes);
        mypolycorditate = updateddata.points;
      }

      final p = Polyline(
        polylineId: PolylineId(ro.id),
        points: mypolycorditate,
        width: 2 + (4 - (i % 4)),
        color: COLOR_CONST.getRandomDarkColor(),
        consumeTapEvents: true,
        onTap: () => onPolylineTapped(ro),
      );
      // debugPrint(
      //   "lenghth of routes: ${response.polylineAllRoutes[i].reversed.length}",
      // );

      croutemarker.add(
        await markerForAqiPoint(
          AqiPoint(
            id: "F-${ro.id}",
            pos:
                ro.isLoop
                    ? mypolycorditate.elementAt(mypolycorditate.length - 1)
                    : mypolycorditate.last,
            aqi: ro.avgAqi,
          ),
          isactual: true,
          mycustomimage:
              ro.distanceKm < radiusKm * 0.7 ? "assets/images/uturn.png" : null,
          mysize: Size(22, 22),
        ),
      );

      // debugPrint("myroid:  F-${ro.id}");
      final routeLength = mypolycorditate.length;

      if (routeLength <= 2) continue; // not enough points

      const maxMarkers = 4;
      final markersToPlace =
          routeLength - 2 < maxMarkers ? routeLength - 2 : maxMarkers;
      // Step size: evenly distribute inside (skip 1st & last point)
      final step = (routeLength - 2) ~/ (markersToPlace + 1);

      for (int j = 1; j <= markersToPlace; j++) {
        final index = j * step;
        croutemarker.add(
          await markerForAqiPoint(
            AqiPoint(
              id: "F-${ro.id}-${DateTime.now().microsecondsSinceEpoch}",
              pos: mypolycorditate[index],
              aqi: ro.avgAqi,
            ),
            isactual: true,
            mysize: const Size(20, 25),
            mycustomimage:
                mode.toLowerCase() == "walking"
                    ? "assets/images/walk.png"
                    : "assets/images/cycling.png",
          ),
        );
      }

      // remove old polyline if exists and add new one
      polylines.add(p);
      markers.addAll(croutemarker);
      ro.polyline = p;
      ro.marker = croutemarker;
      ro.filterData = response.filterData[i];
      ro.stepData = response.directionData['routes'][i]['legs'][0]['steps'];
      debugPrint("before add: " + ro.toString());
      finalroutesDetail.add(ro);
    }

    // // try to get traffic info (duration_in_traffic) if available
    // try {
    //   if ((route['legs'] as List).isNotEmpty) {
    //     final leg = route['legs'][0];
    //     if (leg.containsKey('duration_in_traffic')) {
    //       ro.trafficInfo = leg['duration_in_traffic']['text'];
    //     }
    //   }
    // } catch (_) {}
    return finalroutesDetail;
  }

  // -----------------------
  // polyline tap handler
  // -----------------------
  void onPolylineTapped(RouteOption ro) {
    selectedRoute = ro;
    AqiRoutesWidgets().showRouteInfoPanel(
      ro,
      NavigationService.navigatorKey.currentContext!,
      (e, ctx) {
        // ctx.read<AqiRouteBloc>().add(SelectRouteEvent(tapindex: e));
      },
    );
  }

  RouteSummary trimRouteByDistanceAndMode({
    required List<LatLng> route,
    required double maxDistanceKm,
    required String mode, // "walking" or "cycling"
  }) {
    if (route.length < 2) {
      return RouteSummary(points: route, distanceKm: 0, durationMinutes: 0);
    }

    double total = 0;
    final trimmed = <LatLng>[route.first];

    for (int i = 1; i < route.length; i++) {
      final seg = GeoUtils.haversineKm(route[i - 1], route[i]);
      if (total + seg > maxDistanceKm) break;

      total += seg;
      trimmed.add(route[i]);
    }

    final mins = geoUtil.estimateTravelMinutes(total, mode);
    return RouteSummary(
      points: trimmed,
      distanceKm: total,
      durationMinutes: mins,
    );
  }

  //------------------------
  List classifyTraffic(num ratio) {
    if (ratio <= 1.1) return ["Low", "🟢"];
    if (ratio <= 1.3) return ["Moderate", "🔵"];
    return ["Heavy", '🔴'];
  }

  onSelectRoute(routeindex) async {
    selectedRoute = finalroutesDetail[routeindex];
    Marker? startpoint = markers.cast<Marker?>().firstWhere(
      (e) => e?.markerId.value == "center",
      orElse: () => null,
    );
    Set<Marker> filteredmarker = finalroutesDetail[routeindex].marker!;
    if (startpoint == null) {
      final aqipointcenter = AqiPoint(
        aqi: await fetchAqiForPoint(
          centerPoint.pos,
        ).then((e) => e.aqi.toDouble()),
        id: 'center',
        pos: centerPoint.pos,
      );

      startpoint = await markerForAqiPoint(
        aqipointcenter,
        isactual: true,
        mycustomimage: IMAGECONST.START_POINT,
      );
    }
    filteredmarker.add(startpoint);

    debugPrint("selectedrouteid : ${selectedRoute!.id}");
    return {"marker": filteredmarker, "route": selectedRoute};
  }
  //------------------------

  // -----------------------

  void onStartLiveTracking(Function callbackresponse) async {
    final filterDetail = selectedRoute;
    // final filterrouteindex = filterDetail['route_index'];
    final List<LatLng> currentPolylinePath = filterDetail!.polyline!.points;
    if (currentPolylinePath.length < 2) {
      return;
    }
    final location = loc.Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    loc.PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }

    if (permissionGranted == loc.PermissionStatus.granted) {
      locationSubscription?.cancel(); // Cancel any existing subscription
      LatLng? lastPosition;
      location.changeSettings(
        accuracy: loc.LocationAccuracy.navigation,
        interval: 1000, // in milliseconds
        distanceFilter:
            5, // Minimum distance (in meters) the device must move horizontally for an update
      );
      bool bgpermission =
          await PermissionHandlers.requestAllTimeLocationPermission();
      if (!bgpermission && Platform.isAndroid) {
        bgpermission = await UtilDialog.showRetry2(
          title: "Allow All-Time Location Access?",
          content:
              "Have you granted the app permission to access your location at all times for accurate navigation?",
          onClose: () async {
            return await PermissionHandlers.requestAllTimeLocationPermission();
          },
        );
      }

      var notificationdata = {
        "steps": filterDetail.stepData,
        "aqis": jsonEncode([
          {
            "aqi": filterDetail.avgAqi,
            "routePoints": {
              "lat":
                  currentPolylinePath[currentPolylinePath.length ~/ 2].latitude,
              "lng":
                  currentPolylinePath[currentPolylinePath.length ~/ 2]
                      .longitude,
            },
          },
        ]),
        "eaddress": filterDetail.filterData!.startAddress,
        "mode": tMode.name,
        "avgaqi": filterDetail.avgAqi ?? "0",
        "avgdistance": filterDetail.filterData!.distance ?? "0",
        "startendlatlng": [
          currentPolylinePath[0].latitude,
          currentPolylinePath[0].longitude,
          currentPolylinePath.last.latitude,
          currentPolylinePath.last.longitude,
        ],
      };
      var routedetail = filterDetail.filterData!.toJson();
      routedetail.addAll({"avg_aqi": filterDetail.avgAqi, "route_index": 0});
      DataReterival.addCurrentRideToLocaldb(
        CurrentRideRoute(
          polylines: [
            currentPolylinePath
                .map<PolylinePoint>(
                  (LatLng e) =>
                      PolylinePoint(lat: e.latitude, lng: e.longitude),
                )
                .toList(),
          ],

          currentpont: LatLngPoint(
            lat: currentPolylinePath[0].latitude,
            lng: currentPolylinePath[0].longitude,
          ),
          startaddress: filterDetail.filterData!.startAddress,
          endaddress: filterDetail.filterData!.endAddress,
          modeOfTravel: tMode.name,
          aqiDetailList: [
            {
              "aqi": filterDetail.avgAqi,
              "routePoints": {
                "lat":
                    currentPolylinePath[currentPolylinePath.length ~/ 2]
                        .latitude,
                "lng":
                    currentPolylinePath[currentPolylinePath.length ~/ 2]
                        .longitude,
              },
            },
          ],

          routeDetail: routedetail,
        ),
      );

      // locationSubscription = location.onLocationChanged.listen((
      //   locationData,
      // )
      await AppLocationService.startTracking(notificationdata, bgpermission, false, (
        locationData,
      ) async {
        final currentRawLatLng = LatLng(
          locationData.latitude,
          locationData.longitude,
        );
        // --- Snapping Logic ---
        LatLng snappedLatLng = currentRawLatLng; // Initialize with raw location
        double minDistance = double.infinity;
        // Iterate through each segment of the polyline
        for (int i = 0; i < currentPolylinePath.length - 1; i++) {
          final LatLng p1 = currentPolylinePath[i];
          final LatLng p2 = currentPolylinePath[i + 1];
          // Calculate the closest point on the segment (p1-p2) to currentRawLatLng
          final LatLng pointOnSegment = MapScreenRepository()
              .getClosestPointOnSegment(
                LatLng(currentRawLatLng.latitude, currentRawLatLng.longitude),
                LatLng(p1.latitude, p1.longitude),
                LatLng(p2.latitude, p2.longitude),
              );
          final LatLng snappedPointOnSegment = pointOnSegment;
          // Calculate distance from raw location to the snapped point on segment
          final double distToSegment = Geolocator.distanceBetween(
            currentRawLatLng.latitude,
            currentRawLatLng.longitude,
            snappedPointOnSegment.latitude,
            snappedPointOnSegment.longitude,
          );
          // If this segment provides a closer snapped point, update
          if (distToSegment < minDistance) {
            minDistance = distToSegment;
            snappedLatLng = snappedPointOnSegment;
          }
        }

        // Optional: Add a threshold. If the user is too far off the polyline,
        // you might choose to show their actual raw location instead of snapping.
        // Adjust this threshold based on your application's needs.
        const double SNAP_THRESHOLD_METERS = 50.0; // e.g., 50 meters
        if (minDistance > SNAP_THRESHOLD_METERS) {
          snappedLatLng =
              currentRawLatLng; // Don't snap if too far off the path
          print(
            "User is off-route: ${minDistance.toStringAsFixed(2)} meters from polyline.",
          );
          // You might want to emit a state indicating "off-route" or show a warning.
        }
        debugPrint("i am outside");
        if (filterDetail.filterData!.distance / 2 <=
                (Geolocator.distanceBetween(
                  centerPoint.pos.latitude,
                  centerPoint.pos.longitude,
                  snappedLatLng.latitude,
                  snappedLatLng.longitude,
                )) &&
            !sessionsavedID.contains(filterDetail.id)) {
          addOnNavigationHistory(filterDetail.id, filterDetail);
        }
        //  type: "current_location",
        // --- End Snapping Logic ---
        if (lastPosition == null) {
          lastPosition = snappedLatLng;
          final mycurrentpointdetail = getNearestStepAQIandInstruction(
            currentLatLng: lastPosition!,
          );
          // updateMarker
          Marker mycurrentmarker = await markerForAqiPoint(
            AqiPoint(
              id: "current_location",
              pos: lastPosition!,
              aqi: mycurrentpointdetail['aqiValue'].toDouble(),
            ),
            isactual: true,
            mysize: const Size(40, 40),
            mycustomimage: IMAGECONST.NAVIGATOR_POINT,
          );
          markers.add(mycurrentmarker);
          callbackresponse(mycurrentpointdetail, mycurrentmarker);
          // add(UpdateLiveLocation(snappedLatLng, filterrouteindex));
        } else {
          // Calculate distance between the *snapped* last position and the *new snapped* position
          // This ensures updates are based on movement along the snapped path.
          final distance = Geolocator.distanceBetween(
            lastPosition!.latitude,
            lastPosition!.longitude,
            snappedLatLng.latitude,
            snappedLatLng.longitude,
          );
          if (distance >= 8) {
            // Update if moved 8 meters along the snapped path
            lastPosition = snappedLatLng;
            final mycurrentpointdetail = getNearestStepAQIandInstruction(
              currentLatLng: lastPosition!,
            );
            // updateMarker
            Marker mycurrentmarker = await markerForAqiPoint(
              AqiPoint(
                id: "current_location",
                pos: lastPosition!,
                aqi: mycurrentpointdetail['aqiValue'].toDouble(),
              ),
              isactual: true,
              mysize: const Size(40, 40),
              mycustomimage: IMAGECONST.NAVIGATOR_POINT,
            );
            markers.add(mycurrentmarker);
            callbackresponse(mycurrentpointdetail, mycurrentmarker);
            if (filterDetail.filterData!.distance / 2 <=
                    (Geolocator.distanceBetween(
                      centerPoint.pos.latitude,
                      centerPoint.pos.longitude,
                      snappedLatLng.latitude,
                      snappedLatLng.longitude,
                    )) &&
                !sessionsavedID.contains(filterDetail.id)) {
              addOnNavigationHistory(filterDetail.id, filterDetail);
            }
            // add(UpdateLiveLocation(snappedLatLng, filterrouteindex));
          }
        }
      });
    }
  }

  // Add on Navigation History
  void addOnNavigationHistory(String directionUuid, RouteOption ro) {
    String uid = directionUuid.split('-')[1];
    final history = MainNavigationHistory(
      startAddress: ro.filterData!.startAddress,
      endAddress: ro.filterData!.endAddress,
      stratEndLatLng: [
        ro.polyline!.points.first.latitude,
        ro.polyline!.points.first.longitude,
        ro.polyline!.points.last.latitude,
        ro.polyline!.points.last.longitude,
      ], // lat1, lng1, lat2, lng2
      dateOfSync: DateTime.now(),
      routeAvgAqi: ro.avgAqi,
      detailDataReferenceId: directionUuid,
    );
    // put without key → Hive assigns integer key
    DataReterival.addNavigationHistoryToLocalDataDB(
      history,
      uid,
    ).whenComplete(() => sessionsavedID.add(directionUuid));
  }

  /// NearestStepApi
  Map<String, dynamic> getNearestStepAQIandInstruction({
    required LatLng currentLatLng,
  }) {
    // if (routeindex == -1) return {};

    // final steps =
    //     finalrouteDetail['direction_Mdata']['routes'][routeindex]['legs'][0]['steps'];
    final steps = selectedRoute!.stepData;
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
      for (final point in aqicandidates.sublist(0, 20)) {
        final distance = Geolocator.distanceBetween(
          stepLat,
          stepLng,
          point.pos.latitude,
          point.pos.longitude,
        );

        if (distance < minAQIDistance) {
          minAQIDistance = distance;
          closestAQI = point.aqi.round();
        }
      }
      final filldata = {
        'aqiValue': closestAQI,
        'turnInstructionHtml': closestStep['html_instructions'] as String,
        'routeDetail':
            'Next ${closestStep['distance']['text']} · ${closestStep['duration']['text']}',
      };

      // dev.log("my fillied data : ${filldata.toString()}");
      return filldata;
    }

    return {
      'aqiValue': closestAQI,
      'turnInstructionHtml': '',
      'routeDetail': '',
    };
  }

  Future<String> getAddressFromLatLng(LatLng position) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isEmpty) return "Unknown Location";
    return formatBestAddress(placemarks);
  }

  String formatBestAddress(List<Placemark> placemarks) {
    if (placemarks.isEmpty) return "Unknown Location";

    // Filter out invalid street names (like plus codes: "PV85+FW6")
    List<Placemark> validPlacemarks =
        placemarks.where((p) {
          final street = p.street ?? '';
          return street.isNotEmpty && !_isInvalidStreet(street);
        }).toList();

    // If nothing valid, fall back to all placemarks
    final listToCheck =
        validPlacemarks.isNotEmpty ? validPlacemarks : placemarks;

    // Pick the placemark with the most complete info
    Placemark bestPlacemark = listToCheck.reduce((a, b) {
      int aScore = _placemarkScore(a);
      int bScore = _placemarkScore(b);
      return bScore > aScore ? b : a;
    });

    // Safely get details
    String street = bestPlacemark.street?.trim() ?? '';
    String subLocality = bestPlacemark.subLocality?.trim() ?? '';
    String locality = bestPlacemark.locality?.trim() ?? '';
    String country = bestPlacemark.country?.trim() ?? '';

    // Build clean address
    List<String> parts = [];
    if (street.isNotEmpty) parts.add(street);
    if (subLocality.isNotEmpty) parts.add(subLocality);
    if (locality.isNotEmpty) parts.add(locality);
    if (country.isNotEmpty) parts.add(country);

    return parts.isNotEmpty ? parts.join(", ") : "Unknown Location";
  }

  // Exclude plus codes or junk-like streets
  bool _isInvalidStreet(String street) {
    // Plus codes are usually alphanumeric with +, like "PV85+FW6"
    final plusCodePattern = RegExp(r'^[A-Z0-9\+]{4,}$');
    // Reject if matches plus code style or has no letters at all
    return plusCodePattern.hasMatch(street) ||
        !RegExp(r'[a-zA-Z]').hasMatch(street);
  }

  // Score function for choosing most complete placemark
  int _placemarkScore(Placemark p) {
    int score = 0;
    if (p.street?.isNotEmpty == true && !_isInvalidStreet(p.street!))
      score += 3;
    if (p.subLocality?.isNotEmpty == true) score += 2;
    if (p.locality?.isNotEmpty == true) score += 2;
    if (p.country?.isNotEmpty == true) score += 1;
    return score;
  }
}
