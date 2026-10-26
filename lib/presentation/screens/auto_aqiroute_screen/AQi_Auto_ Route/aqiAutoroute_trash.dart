// aqi_route_map.dart
// Flutter sample: generate candidate points inside a radius, draw circle,
// zoom to fit, add markers (normal + AQI-colored), generate route candidates,
// draw polylines for each candidate, and show tappable details (AQI, distance, duration, traffic).

// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';
// import 'dart:math' as math;
// import 'package:aqi_app/configs/size_config.dart';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;

// // -----------------------
// // Data models
// // -----------------------
// class AqiPoint {
//   final Sid;
//   final LatLng pos;
//   final double aqi;

//   AqiPoint({required this.id, required this.pos, required this.aqi});
// }

// class RouteOption {
//   final String id;
//   final List<AqiPoint> points; // ordered points (start may be center)
//   final bool isLoop; // whether route returns to start

//   // these are filled after calling Directions API (optional)
//   Polyline? polyline;
//   double? distanceKm; // total distance in km
//   Duration? duration; // travel time
//   double avgAqi;
//   String? trafficInfo; // optional

//   RouteOption({
//     required this.id,
//     required this.points,
//     required this.isLoop,
//     this.avgAqi = 0,
//   });

//   @override
//   String toString() {
//     return 'RouteOption('
//         'id: $id, '
//         'isLoop: $isLoop, '
//         'points: ${points.map((p) => p.toString()).toList()}, '
//         'avgAqi: $avgAqi, '
//         'distanceKm: ${distanceKm?.toStringAsFixed(2)}, '
//         'duration: ${duration?.inMinutes} min, '
//         'trafficInfo: $trafficInfo)';
//   }
// }

// // -----------------------
// // Main widget
// // -----------------------
// class AqiRouteMap extends StatefulWidget {
//   final LatLng center;
//   final double radiusKm;
//   final String googleApiKey; // required if you want to fetch Directions

//   const AqiRouteMap({
//     Key? key,
//     required this.center,
//     required this.radiusKm,
//     required this.googleApiKey,
//   }) : super(key: key);

//   @override
//   _AqiRouteMapState createState() => _AqiRouteMapState();
// }

// class _AqiRouteMapState extends State<AqiRouteMap> {
//   final Completer<GoogleMapController> _controller = Completer();

//   final Set<Marker> _markers = {};
//   final Set<Polyline> _polylines = {};
//   final Set<Polyline> _allpolylines = {};
//   Circle? _circle;

//   final StreamController<double> _progress =
//       StreamController<double>.broadcast();

//   // candidate points (excluding center at index 0)
//   final List<AqiPoint> _candidates = [];

//   // computed route options
//   final List<RouteOption> _routes = [];

//   // tuning
//   final double _stepDistanceKm = 0.2; // used to compute maxStops
//   final int _beamWidth = 70; // beam width to prune combinatorics
//   final int _topK = 4; // final number of routes to fetch full Directions for

//   late AqiPoint _centerPoint;

//   @override
//   void initState() {
//     super.initState();
//     _centerPoint = AqiPoint(id: 'center', pos: widget.center, aqi: 0);
//     _startPipeline();
//   }

//   @override
//   void dispose() {
//     _progress.close();
//     super.dispose();
//   }

//   // -----------------------
//   // Top-level pipeline (emits progress)
//   // -----------------------
//   Future<void> _startPipeline() async {
//     try {
//       _progress.add(0.02);

//       _addCircleOnMap();
//       _progress.add(0.08);

//       await Future.delayed(Duration(milliseconds: 150));
//       await _zoomToFitCircle();
//       _progress.add(0.12);

//       await _generatePointsAndMarkers();
//       _progress.add(0.45);

//       await _generateRouteCandidatesAndDraw();
//       _progress.add(0.95);

//       _progress.add(1.0);
//     } catch (e) {
//       _progress.add(0.0);
//       rethrow;
//     }
//   }

//   // -----------------------
//   // 1) Add circle on map
//   // -----------------------
//   void _addCircleOnMap() {
//     final circle = Circle(
//       circleId: CircleId('searchRadius'),
//       center: widget.center,
//       radius: widget.radiusKm * 1000, // meters
//       fillColor: Colors.blue.withOpacity(0.06),
//       strokeColor: Colors.blue.withOpacity(0.42),
//       strokeWidth: 1,
//     );
//     setState(() => _circle = circle);
//   }

//   // -----------------------
//   // 2) Camera controller zoom out to show whole circle
//   // -----------------------
//   Future<void> _zoomToFitCircle() async {
//     final GoogleMapController controller = await _controller.future;

//     // compute bounds by sampling 8 directions on circle
//     final List<LatLng> samplePoints = [];
//     for (var bearing in [0, 45, 90, 135, 180, 225, 270, 315]) {
//       samplePoints.add(
//         _destinationPoint(widget.center, bearing.toDouble(), widget.radiusKm),
//       );
//     }

//     final LatLngBounds bounds = _boundsFromLatLngList(
//       samplePoints + [widget.center],
//     );

//     // animate camera to bounds
//     try {
//       await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
//     } catch (e) {
//       // sometimes newLatLngBounds throws if map hasn't laid out yet; fallback to center & zoom out
//       await controller.animateCamera(
//         CameraUpdate.newLatLngZoom(widget.center, 12 - (widget.radiusKm / 2)),
//       );
//     }
//   }

//   LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
//     assert(list.isNotEmpty);
//     double? x0, x1, y0, y1;
//     for (final latLng in list) {
//       if (x0 == null) {
//         x0 = x1 = latLng.latitude;
//         y0 = y1 = latLng.longitude;
//       } else {
//         if (latLng.latitude > x1!) x1 = latLng.latitude;
//         if (latLng.latitude < x0) x0 = latLng.latitude;
//         if (latLng.longitude > y1!) y1 = latLng.longitude;
//         if (latLng.longitude < y0!) y0 = latLng.longitude;
//       }
//     }
//     return LatLngBounds(
//       southwest: LatLng(x0!, y0!),
//       northeast: LatLng(x1!, y1!),
//     );
//   }

//   // -----------------------
//   // 3) Create points and add markers (normal + AQI markers differ by hue)
//   // -----------------------
//   Future<void> _generatePointsAndMarkers() async {
//     _markers.clear();
//     _candidates.clear();
//     // Add center marker
//     _markers.add(
//       Marker(
//         markerId: MarkerId('center'),
//         position: widget.center,
//         infoWindow: InfoWindow(title: 'You are here'),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
//       ),
//     );

//     // generate candidate points similar to your previous approach
//     double step =
//         widget.radiusKm < 1
//             ? 0.5
//             : widget.radiusKm < 5
//             ? 1
//             : 2;

//     int idCounter = 0;
//     final rand = math.Random();

//     for (double r = step; r <= widget.radiusKm; r += step) {
//       // cardinal points
//       for (var bearing in [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0]) {
//         final pos = _destinationPoint(widget.center, bearing, r);
//         final aqi = await _fetchAqiForPoint(pos);
//         final ap = AqiPoint(id: 'p-${idCounter++}', pos: pos, aqi: aqi);
//         _candidates.add(ap);
//         _markers.add(_markerForAqiPoint(ap));
//       }

//       // 4 random mid angles (one per quadrant) inside the angle ranges you specified
//       final angleRanges = [
//         [20.0, 65.0],
//         [115.0, 165.0],
//         [200.0, 245.0],
//         [290.0, 340.0],
//       ];

//       for (var rrange in angleRanges) {
//         double randomAngle =
//             rrange[0] + rand.nextDouble() * (rrange[1] - rrange[0]);
//         final pos = _destinationPoint(widget.center, randomAngle, r);
//         final aqi = await _fetchAqiForPoint(pos);
//         final ap = AqiPoint(id: 'p-${idCounter++}', pos: pos, aqi: aqi);
//         _candidates.add(ap);
//         _markers.add(_markerForAqiPoint(ap));
//       }
//     }
//     log("mymarker: ${_markers.length} and ${_candidates.length}");
//     setState(() {
//       // apply markers and the circle
//       if (_circle != null) {
//         // nothing extra
//       }
//     });
//   }

//   Marker _markerForAqiPoint(AqiPoint ap) {
//     // color by AQI band (green -> red)
//     final h = _aqiToHue(ap.aqi);
//     log("mymarker id: ${ap.id}");
//     return Marker(
//       markerId: MarkerId(ap.id),
//       position: ap.pos,
//       icon: BitmapDescriptor.defaultMarkerWithHue(h),
//       infoWindow: InfoWindow(title: 'AQI: ${ap.aqi.toStringAsFixed(0)}'),
//       onTap: () {
//         // optionally show details for that point
//         showModalBottomSheet(
//           context: context,
//           builder: (_) => _aqiPointDetailsSheet(ap),
//         );
//       },
//     );
//   }

//   double _aqiToHue(double aqi) {
//     // map AQI (0..500) to hue (green->red)
//     // 0..50 green (~120), 51..100 yellow (~60), 101..200 orange (~30), 201+ red (~0)
//     if (aqi <= 50) return 120.0; // green
//     if (aqi <= 100) return 60.0; // yellow
//     if (aqi <= 200) return 30.0; // orange
//     return 0.0; // red
//   }

//   Widget _aqiPointDetailsSheet(AqiPoint ap) {
//     return Container(
//       constraints: BoxConstraints(minWidth: SizeConfig.screenWidth),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'AQI Point',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black12,
//               ),
//             ),
//             SizedBox(height: 8),
//             Text(
//               'AQI: ${ap.aqi.toStringAsFixed(0)}',
//               style: TextStyle(color: Colors.black),
//             ),
//             Text(
//               'Lat: ${ap.pos.latitude.toStringAsFixed(6)}',
//               style: TextStyle(color: Colors.black),
//             ),
//             Text(
//               'Lng: ${ap.pos.longitude.toStringAsFixed(6)}',
//               style: TextStyle(color: Colors.black),
//             ),
//             SizedBox(height: 12),
//             ElevatedButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: Text('Close', style: TextStyle(color: Colors.black)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // -----------------------
//   // 4) Generate route candidates (beam search), draw polylines, tappable
//   // -----------------------
//   Future<void> _generateRouteCandidatesAndDraw() async {
//     _polylines.clear();
//     _routes.clear();

//     if (_candidates.isEmpty) return;

//     final int maxStops = _calculateMaxStops(
//       widget.radiusKm,
//       stepDistance: _stepDistanceKm,
//     );

//     // beam search: maintain a list of partial paths, expand by adding one unused candidate.
//     List<List<AqiPoint>> beam = [
//       [_centerPoint],
//     ];

//     final List<RouteOption> results = [];

//     for (int depth = 1; depth <= maxStops; depth++) {
//       final List<List<AqiPoint>> nextBeam = [];

//       for (final path in beam) {
//         for (final candidate in _candidates) {
//           if (path.any((p) => p.id == candidate.id)) continue; // no repetition

//           final newPath = List<AqiPoint>.from(path)..add(candidate);

//           // Option A: keep as one-way (not returned to center)
//           results.add(
//             RouteOption(
//               id: 'r-${results.length}',
//               points: newPath,
//               isLoop: false,
//             ),
//           );

//           // Option B: also consider closed loop (return to center)
//           final loopPath = List<AqiPoint>.from(newPath)..add(_centerPoint);
//           results.add(
//             RouteOption(
//               id: 'r-loop-${results.length}',
//               points: loopPath,
//               isLoop: true,
//             ),
//           );

//           nextBeam.add(newPath);
//         }
//       }

//       // score partial paths quickly and keep top _beamWidth
//       nextBeam.sort((a, b) => _quickScorePath(a).compareTo(_quickScorePath(b)));
//       log("total bheem" + nextBeam.length.toString());
//       beam = nextBeam.take(_beamWidth).toList();

//       // small progress update
//       _progress.add(0.45 + (depth / maxStops) * 0.4);
//     }

//     // At this point we have many candidate RouteOption elements in results.
//     // Score them more accurately (avgAQI + distance heuristic) and take top _topK.
//     log("My AQI Detail: ${results.length}");
//     for (final r in results) {
//       r.avgAqi =
//           r.points.map((p) => p.aqi).reduce((a, b) => a + b) / r.points.length;
//       r.distanceKm = _approxPathDistanceKm(r.points);
//     }

//     results.sort((a, b) {
//       final scoreA = a.avgAqi + 0.12 * (a.distanceKm ?? 0);
//       final scoreB = b.avgAqi + 0.12 * (b.distanceKm ?? 0);
//       return scoreA.compareTo(scoreB);
//     });

//     final topResults = results.take((_topK * 3)).toList();

//     // For the top few results, optionally fetch real route polyline & duration from Google Directions.
//     // To keep API calls low, do it only for top _topK.

//     for (int i = 0; i < topResults.length; i++) {
//       final ro = topResults[i];
//       // create a simple straight-line polyline for immediate visualization
//       log("before aqi path id : ${ro.id}");
//       log("before result: ${ro.toString()}");
//       final polyId = PolylineId(ro.id);
//       final poly = Polyline(
//         polylineId: polyId,
//         points: ro.points.map((p) => p.pos).toList(),
//         width: 4 + (6 - (i % 6)),
//         color: Colors.primaries[i % Colors.primaries.length].withOpacity(0.8),
//         consumeTapEvents: true,
//         onTap: () => _onPolylineTapped(ro),
//       );
//       ro.polyline = poly;
//       _allpolylines.add(poly);
//       _routes.add(ro);
//     }
//     setState(() {});
//     // Now fetch full details (Directions) for final top-K (expensive) and update polylines
//     final fetchCount = math.min(_topK, topResults.length);
//     log("my Initial polyline list: ${_polylines.length}");
//     log("jk top result: $fetchCount");
//     for (int i = 0; i < fetchCount; i++) {
//       final ro = topResults[i];
//       log("top result: ${ro.toString()}");
//       try {
//         // await _fetchDirectionsForRoute(ro);
//       } catch (e) {
//         // ignore; we still have straight-line polyline
//       }
//     }
//     // update polylines after fetching directions
//     setState(() {});
//   }

//   double _quickScorePath(List<AqiPoint> path) {
//     // simple heuristic: avg AQI + small penalty for length
//     final avg = path.map((p) => p.aqi).reduce((a, b) => a + b) / path.length;
//     final dist = _approxPathDistanceKm(path);
//     return avg + 0.2 * dist;
//   }

//   int _calculateMaxStops(double radiusKm, {double stepDistance = 0.5}) {
//     final routeLen = 0.8 * radiusKm; // desired route length
//     final stops = (routeLen / stepDistance).floor();
//     return stops < 2 ? 2 : stops;
//   }

//   double _approxPathDistanceKm(List<AqiPoint> p) {
//     double sum = 0;
//     for (int i = 0; i < p.length - 1; i++) {
//       sum += _haversineKm(p[i].pos, p[i + 1].pos);
//     }
//     return sum;
//   }

//   Future<void> _fetchDirectionsForRoute(
//     RouteOption ro, {
//     String mode = 'walking',
//   }) async {
//     // Use Google Directions API to get accurate route polyline, distance & duration.
//     // Note: This is optional: you'll need a billing-enabled API key that allows Directions API.

//     final origin = ro.points.first.pos;
//     final destination = ro.points.last.pos;
//     final waypoints =
//         ro.points.length > 2
//             ? ro.points
//                 .sublist(1, ro.points.length - (ro.isLoop ? 1 : 0))
//                 .map((p) => '${p.pos.latitude},${p.pos.longitude}')
//                 .join('|')
//             : null;

//     final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
//       'origin': '${origin.latitude},${origin.longitude}',
//       'destination': '${destination.latitude},${destination.longitude}',
//       if (waypoints != null) 'waypoints': waypoints,
//       'mode': mode, // walking | bicycling | driving
//       'key': widget.googleApiKey,
//       // 'alternatives': 'true',
//       'departure_time': 'now', // allows duration_in_traffic for driving
//     });
//     log("mode to find direction: $mode");
//     // final url =
//     //     'https://maps.googleapis.com/maps/api/directions/json?origin=${event.origin.latitude},${event.origin.longitude}'
//     //     '&destination=${event.destination.latitude},${event.destination.longitude}'
//     //     '&alternatives=true'
//     //     '&departure_time=now'
//     //     '&mode=${mode == "bicycling" ? "driving" : mode}'
//     //     '&traffic_model=best_guess'
//     //     '&key=$apiKey';

//     final resp = await http.get(uri);
//     if (resp.statusCode != 200)
//       throw Exception('Directions API error: ${resp.statusCode}');

//     final Map<String, dynamic> body = jsonDecode(resp.body);
//     if ((body['routes'] as List).isEmpty) throw Exception('No route returned');

//     final route = body['routes'][0];
//     final overview = route['overview_polyline']['points'];
//     final polyPoints = _decodePolyline(overview);

//     final distanceMeters = (route['legs'] as List).fold<int>(
//       0,
//       (sum, l) => sum + (l['distance']['value'] as int),
//     );
//     final durationSec = (route['legs'] as List).fold<int>(
//       0,
//       (sum, l) => sum + (l['duration']['value'] as int),
//     );

//     double distanceKm = distanceMeters / 1000.0;

//     ro.distanceKm = distanceKm;
//     ro.duration = Duration(seconds: durationSec);
//     log("updated polyline: ${ro.id}");
//     // update polyline with the fetched path
//     final p = Polyline(
//       polylineId: PolylineId(ro.id),
//       points: polyPoints,
//       width: 4,
//       color: Colors.blue.withOpacity(0.9),
//       consumeTapEvents: true,
//       onTap: () => _onPolylineTapped(ro),
//     );

//     // remove old polyline if exists and add new one
//     _polylines.removeWhere((pl) => pl.polylineId.value == ro.id);
//     _polylines.add(p);
//     ro.polyline = p;

//     // try to get traffic info (duration_in_traffic) if available
//     try {
//       if ((route['legs'] as List).isNotEmpty) {
//         final leg = route['legs'][0];
//         if (leg.containsKey('duration_in_traffic')) {
//           ro.trafficInfo = leg['duration_in_traffic']['text'];
//         }
//       }
//     } catch (_) {}

//     setState(() {});
//   }

//   // -----------------------
//   // Polyline tap handler -> show detail bottom sheet
//   // -----------------------
//   void _onPolylineTapped(RouteOption ro) {
//     showModalBottomSheet(
//       context: context,
//       builder: (_) => _routeDetailsSheet(ro),
//     );
//   }

//   Widget _routeDetailsSheet(RouteOption ro) {
//     return Container(
//       constraints: BoxConstraints(minWidth: SizeConfig.screenWidth),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Route Details',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),
//             SizedBox(height: 8),
//             Text(
//               'Avg AQI: ${ro.avgAqi.toStringAsFixed(1)}',
//               style: TextStyle(color: Colors.black87),
//             ),
//             Text(
//               'Distance: ${(ro.distanceKm ?? _approxPathDistanceKm(ro.points)).toStringAsFixed(2)} km',
//               style: TextStyle(color: Colors.black87),
//             ),
//             Text(
//               'Duration: ${ro.duration?.inMinutes ?? (ro.distanceKm != null ? (ro.distanceKm! / 5 * 60).round() : "-")} '
//               ' mins',
//               style: TextStyle(color: Colors.black87),
//             ),
//             if (ro.trafficInfo != null)
//               Text(
//                 'Traffic: ${ro.trafficInfo}',
//                 style: TextStyle(color: Colors.black87),
//               ),
//             SizedBox(height: 12),
//             ElevatedButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: Text('Close', style: TextStyle(color: Colors.black87)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // -----------------------
//   // Helper functions
//   // -----------------------
//   Future<double> _fetchAqiForPoint(LatLng p) async {
//     // TODO: integrate your AQI data source here (HTTP/API/local DB).
//     // For demo, return a pseudo-random AQI based on position.
//     // Replace with real API call to fetch AQI for the given lat/lng.
//     final r = (p.latitude.abs() * 1000 + p.longitude.abs() * 1000) % 200;
//     await Future.delayed(Duration(milliseconds: 40));
//     return 30 + (r % 200); // value in [30, 229]
//   }

//   LatLng _destinationPoint(LatLng start, double bearingDeg, double distanceKm) {
//     const R = 6371.0; // Earth radius in km
//     final bearing = _degreesToRadians(bearingDeg);
//     final lat1 = _degreesToRadians(start.latitude);
//     final lon1 = _degreesToRadians(start.longitude);

//     final lat2 = math.asin(
//       math.sin(lat1) * math.cos(distanceKm / R) +
//           math.cos(lat1) * math.sin(distanceKm / R) * math.cos(bearing),
//     );
//     final lon2 =
//         lon1 +
//         math.atan2(
//           math.sin(bearing) * math.sin(distanceKm / R) * math.cos(lat1),
//           math.cos(distanceKm / R) - math.sin(lat1) * math.sin(lat2),
//         );

//     return LatLng(_radiansToDegrees(lat2), _radiansToDegrees(lon2));
//   }

//   double _degreesToRadians(double d) => d * (math.pi / 180);
//   double _radiansToDegrees(double r) => r * (180 / math.pi);

//   double _haversineKm(LatLng p1, LatLng p2) {
//     const R = 6371.0; // km
//     final dLat = _degreesToRadians(p2.latitude - p1.latitude);
//     final dLon = _degreesToRadians(p2.longitude - p1.longitude);
//     final a =
//         math.sin(dLat / 2) * math.sin(dLat / 2) +
//         math.cos(_degreesToRadians(p1.latitude)) *
//             math.cos(_degreesToRadians(p2.latitude)) *
//             math.sin(dLon / 2) *
//             math.sin(dLon / 2);
//     return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
//   }

//   List<LatLng> _decodePolyline(String poly) {
//     // standard polyline decode implementation
//     final List<LatLng> points = [];
//     int index = 0, len = poly.length;
//     int lat = 0, lng = 0;

//     while (index < len) {
//       int b, shift = 0, result = 0;
//       do {
//         b = poly.codeUnitAt(index++) - 63;
//         result |= (b & 0x1F) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
//       lat += dlat;

//       shift = 0;
//       result = 0;
//       do {
//         b = poly.codeUnitAt(index++) - 63;
//         result |= (b & 0x1F) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
//       lng += dlng;

//       points.add(LatLng(lat / 1E5, lng / 1E5));
//     }
//     return points;
//   }

//   // -----------------------
//   // UI
//   // -----------------------
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('AQI Route Finder', style: TextStyle(color: Colors.black)),
//       ),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition: CameraPosition(
//               target: widget.center,
//               zoom: 14,
//             ),
//             markers: _markers,
//             polylines: _polylines,
//             circles: _circle != null ? {_circle!} : {},
//             onMapCreated: (GoogleMapController controller) {
//               if (!_controller.isCompleted) _controller.complete(controller);
//             },
//             // onPolylineTapped: (PolylineId id) {
//             //   final ro = _routes.firstWhere((r) => r.id == id.value, orElse: () => RouteOption(id: 'x', points: [], isLoop: false));
//             //   if (ro.id != 'x') _onPolylineTapped(ro);
//             // },
//           ),

//           // progress bar stream
//           Positioned(
//             top: 8,
//             left: 12,
//             right: 12,
//             child: StreamBuilder<double>(
//               stream: _progress.stream,
//               initialData: 0.0,
//               builder: (context, snap) {
//                 final v = snap.data ?? 0.0;
//                 return v <= 0 || v >= 1
//                     ? SizedBox.shrink()
//                     : LinearProgressIndicator(value: v, minHeight: 6);
//               },
//             ),
//           ),

//           // small legend
//           Positioned(
//             bottom: 16,
//             left: 12,
//             child: Card(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 8,
//                 ),
//                 child: Row(
//                   children: [
//                     _legendDot(Colors.green, 'Good'),
//                     SizedBox(width: 8),
//                     _legendDot(Colors.orange, 'Moderate'),
//                     SizedBox(width: 8),
//                     _legendDot(Colors.red, 'Unhealthy'),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),

//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () async {
//           // re-run pipeline
//           await _startPipeline();
//         },
//         label: Text('Recompute'),
//         icon: Icon(Icons.refresh),
//       ),
//     );
//   }

//   Widget _legendDot(Color c, String text) {
//     return Row(
//       children: [
//         Container(
//           width: 10,
//           height: 10,
//           decoration: BoxDecoration(color: c, shape: BoxShape.circle),
//         ),
//         SizedBox(width: 6),
//         Text(text, style: TextStyle(color: Colors.black)),
//       ],
//     );
//   }
// }
