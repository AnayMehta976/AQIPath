import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:aqi_app/configs/PemissionHandler.dart';
import 'package:aqi_app/constants/image_constant.dart';
import 'package:aqi_app/data/local/HiveLDB/HiveModel/CurrentRideRoute.dart';
import 'package:aqi_app/data/local/HiveLDB/Hive_DataRetival.dart';
import 'package:aqi_app/data/repository/MapScreen_repositry/MapScreen_repositary.dart';
import 'package:aqi_app/utils/Background_services/Background_services_mtd.dart';
import 'package:aqi_app/utils/dialog.dart';
import 'package:aqi_app/utils/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<MapEvent, MapState> {
  final String apiKey;
  final repository = MapScreenRepository();
  late var filterrouteindex = -1;
  StreamSubscription<loc.LocationData>? _locationSubscription;
  RouteFilterType? current;
  LocationBloc({required this.apiKey}) : super(MapInitial()) {
    on<InitmapNfetchcLocEvent>(_onFetchCurrentLocation);
    on<PinLocation>(_pinlocationAddressDetail);
    on<SearchRoute>(_getalldirectionroute);
    on<AnalizeRoute>(_analizeroutedirection);
    on<OnFilterRuote>(_onFilterRoute);
    on<StartLiveLocationTracking>(_onStartLiveTracking);
    on<UpdateLiveLocation>(_onUpdateLiveTracking);
    on<ResumeLiveTrakingEvent>(_onResumeLiveTracking);
    on<StopLiveLocationTracking>(_onStopLiveTracking);
    on<ShowMarkercustomInfoWindow>(_trigerCustomInfoWindow);
    on<HideMarkercustomInfoWindow>(_hideCustomMarkerInfo);
    on<UpdatepinPointRouteSEEvent>(_updatepointonlocationdrag);
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    return super.close();
  }

  // -------------------------
  // ✅ Fetch current static location
  Future<void> _onFetchCurrentLocation(
    InitmapNfetchcLocEvent event,
    Emitter<MapState> emit,
  ) async {
    final LatLng current;
    emit(MapLoading());
    if (event.currentlatlng != null) {
      current = event.currentlatlng!;
    } else {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        emit(IsPermissionGranted(permission: false));
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        // forceAndroidLocationManager: true,
      );
      current = LatLng(position.latitude, position.longitude);
    }
    final useraddress = await repository.getAddressFromLatLng(current);
    await repository.updateMarker(
      type: "my_location",
      position: current,
      assetimage: IMAGECONST.MY_Loc_Icon,
      size: Size(40, 40),
      onTap:
          (type, position) => add(ShowMarkercustomInfoWindow(position, type)),
      onDragEnd: (id, position) {},
    );
    if (event.rowrunnigData != null) {
      log(
        "my detail list: ${event.rowrunnigData!.aqiDetailList.length} = ${event.rowrunnigData!.polylines.length.toString()}",
      );
      event.rowrunnigData!.aqiDetailList.map((e) async {
        repository.circles.add(repository.addAqicircleforresume(e));
      });
      log("my all cicrle" + repository.circles.length.toString());
      List<List<LatLng>> allroute = [
        event.rowrunnigData!.polylines.first
            .map((e) => LatLng(e.lat, e.lng))
            .toList(),
      ];
      log("my all routes: " + allroute.length.toString());
      await repository.buildPolylinesNMarker(
        allroute,
        event.rowrunnigData!.routeDetail!,
        event.rowrunnigData!.modeOfTravel.toLowerCase(),
        isrowbased: true,
      );
      await _addStartNEndMarker(
        [allroute[0][0], allroute[0].last],
        ["p0", 'pn'],
        [IMAGECONST.START_POINT, IMAGECONST.END_POINT],
        emit,
      );
      emit(
        MapLoaded(
          polylineCoordinates: allroute,
          aqicircle: repository.circles,
          polyline: repository.polylines,
          filterdata: [event.rowrunnigData!.routeDetail],
        ),
      );
    } else {
      emit(
        CurrentLocationState(
          currentLocation: current,
          markers: repository.markers,
          // mrkid: "my_location",
          useraddress: useraddress,
          isLoading: false,
          transportMode: TransportMode.Stop,
          initialfilter: event.initialfilter,
        ),
      );
    }
  }

  // -------------------------
  // ✅ Get route directions
  Future<void> _getalldirectionroute(
    SearchRoute event,
    Emitter<MapState> emit,
  ) async {
    emit(MapLoading());
    repository.cleardata();
    try {
      final orginlatlng = event.origin;
      final distinationlatlng = event.destination;
      if (repository.getDistancebetweentocordinate(
            orginlatlng,
            distinationlatlng,
          ) >
          50000) {
        emit(
          OutOFRangeStage(
            message:
                "Your request for AQI and traffic analysis has exceeded the 50km operational range of this application. Please ensure your location falls within the designated service area for accurate data processing.",
          ),
        );
        return;
      }
      final tmode = event.mode.name;
      // tomarrow first check distance inbetween only in 50 Km radius
      final locationDetail = await repository.fetchDirectionByLocation(
        event: event,
        mode: tmode.toLowerCase(),
      );

      final allRoutes = locationDetail['polyline_allroutes'];
      final aqicircle = await repository.getAQIImpactCricleforroutes(allRoutes);
      // start N End Point Marker
      await _addStartNEndMarker(
        [allRoutes[0][0], allRoutes[0].last],
        ["p0", 'pn'],
        [IMAGECONST.START_POINT, IMAGECONST.END_POINT],
        emit,
      );

      await repository.buildPolylinesNMarker(
        allRoutes,
        locationDetail['direction_Mdata'],
        tmode.toLowerCase(),
      );

      final filterdata = repository.finalrouteDetail["filter_data"];
      log(
        "Route matrix: ${repository.finalAnalizematrix} "
        "Overview: ${repository.finaloverviewdetail}",
      );

      emit(
        MapLoaded(
          polylineCoordinates: allRoutes,
          aqicircle: aqicircle,
          filterdata: filterdata,
        ),
      );
    } catch (e) {
      log("myjsonsourcedata: $e");
      emit(MapError('Failed to fetch directions'));
    }
  }

  ///-------------------------
  /// ✅ Get AQI Routes and traffic analysis
  Future<void> _analizeroutedirection(
    AnalizeRoute event,
    Emitter<MapState> emit,
  ) async {
    final result = await repository.generateCoordinateBucketsRandom(
      event.origin,
      event.wayRadiusKms!,
    );
    emit(MapLoaded(polylineCoordinates: [], aqicircle: Set(), filterdata: []));
  }

  //--------------------
  /// Adding Funtion for Start Point And End Point Marker
  Future<void> _addStartNEndMarker(
    List<LatLng> position,
    List<String> id,
    List<String>? image,
    Emitter<MapState> emit,
  ) async {
    for (var i = 0; i < position.length; i++) {
      await repository.updateMarker(
        type: id[i],
        position: position[i],
        assetimage: image![i],
        size: Size(45, 45),
        onTap:
            (type, position) => add(ShowMarkercustomInfoWindow(position, type)),
        onDragEnd: (id, position) async {
          String newAddress = await repository.getAddressFromLatLng(position);
          add(
            UpdatepinPointRouteSEEvent(
              updateposition: position,
              updateaddress: newAddress,
              id: id,
            ),
          );
        },
      );
    }
  }

  // -------------------------
  // ✅ Filter route
  void _onFilterRoute(OnFilterRuote event, Emitter<MapState> emit) async {
    current = event.selectedFilter;
    if (current == RouteFilterType.all) {
      await repository.buildPolylinesNMarker(
        repository.finalrouteDetail['polyline_allroutes'],
        repository.finalrouteDetail['direction_Mdata'],
        event.mode.name.toLowerCase(),
      );
      final filterdata = repository.finalrouteDetail["filter_data"];
      Set<Circle> aqicircle = {};
      for (var element in repository.circleonroute) {
        aqicircle.addAll(element);
      }
      emit(
        MapLoaded(
          polylineCoordinates:
              repository.finalrouteDetail['polyline_allroutes'],
          aqicircle: aqicircle,
          filterdata: filterdata,
        ),
      );
      return;
    }

    final filterDetail = await repository.getDirectionOnFilter(current);
    filterrouteindex = filterDetail['route_index'];
    await repository.buildPolylinesNMarker(
      [
        repository
            .finalrouteDetail['polyline_allroutes'][filterDetail['route_index']],
      ],
      repository.finalrouteDetail['direction_Mdata'],
      event.mode.name.toLowerCase(),
    );
    emit(
      MapFilterLoaded(
        polylineCoordinates: [
          repository
              .finalrouteDetail['polyline_allroutes'][filterDetail['route_index']],
        ],
        aqicircle: repository.circleonroute[filterDetail['route_index']],
        filterdata: filterDetail,
      ),
    );
  }

  // -------------------------
  Future<void> _onStartLiveTracking(
    StartLiveLocationTracking event, // Event now carries polylineCoordinates
    Emitter<MapState> emit,
  ) async {
    emit(MapLoading());
    final filterDetail = await repository.getDirectionOnFilter(current);
    final filterrouteindex = filterDetail['route_index'];
    final List<LatLng> currentPolylinePath =
        repository
            .finalrouteDetail['polyline_allroutes'][filterDetail['route_index']];
    if (currentPolylinePath.length < 2) {
      return;
    }

    bool bgpermission =
        await PermissionHandlers.requestAllTimeLocationPermission();

    if (!bgpermission) {
      await UtilDialog.showRetry2(
        title: "Allow All-Time Location Access?",
        content:
            "Have you granted the app permission to access your location at all times for accurate navigation?",
        onClose: () async {
          return await PermissionHandlers.requestAllTimeLocationPermission();
        },
        isDeny: true,
      );
    }
    // final location = loc.Location();
    // loc.PermissionStatus permissionGranted = await location.hasPermission();
    // if (permissionGranted == loc.PermissionStatus.denied) {
    //   permissionGranted = await location.requestPermission();
    //   if (permissionGranted != loc.PermissionStatus.granted) {
    //     return;
    //   }
    // }
    // if (bgpermission) {
    // _locationSubscription?.cancel(); // Cancel any existing subscription
    LatLng? lastPosition;
    final polylinepointd =
        repository
            .finalrouteDetail['polyline_allroutes'][filterDetail['route_index']];
    // add(StopLiveLocationTracking());
    // return;
    var notificationdata = {
      "steps":
          repository
              .finalrouteDetail['direction_Mdata']['routes'][filterrouteindex]['legs'][0]['steps'],
      "aqis": jsonEncode(
        repository.caqiDetailallroutes[filterrouteindex].map((point) {
          return {
            "aqi": point['aqi'],
            "routePoints": {
              "lat": point['routePoints'].latitude,
              "lng": point['routePoints'].longitude,
            },
          };
        }).toList(),
      ),
      "eaddress":
          repository
              .finaloverviewdetail[filterDetail['route_index']]['end_address'],
      "mode": event.tmode,
      "avgaqi":
          repository.finaloverviewdetail[filterDetail['route_index']]['avg_aqi']
              .toInt() ??
          "0",
      "avgdistance":
          repository
                  .finaloverviewdetail[filterDetail['route_index']]['distance']
                  .toInt() /
              1000 ??
          "0",
      "startendlatlng": [
        polylinepointd.first.latitude,
        polylinepointd.first.longitude,
        polylinepointd.last.latitude,
        polylinepointd.last.longitude,
      ],
    };
    Map myfinalfilterdetail =
        repository.finaloverviewdetail[filterDetail['route_index']];

    myfinalfilterdetail["route_index"] = filterDetail['route_index'];
    DataReterival.addCurrentRideToLocaldb(
      CurrentRideRoute(
        polylines: [
          repository
              .finalrouteDetail['polyline_allroutes'][filterDetail['route_index']]
              .map<PolylinePoint>(
                (LatLng e) => PolylinePoint(lat: e.latitude, lng: e.longitude),
              )
              .toList(),
        ],

        currentpont: LatLngPoint(
          lat: repository.currentLocation.latitude,
          lng: repository.currentLocation.longitude,
        ),
        startaddress:
            repository
                .finaloverviewdetail[filterDetail['route_index']]['start_address'],
        endaddress:
            repository
                .finaloverviewdetail[filterDetail['route_index']]['end_address'],
        modeOfTravel: event.tmode,
        aqiDetailList:
            repository.caqiDetailallroutes[filterrouteindex].map((point) {
              return {
                "aqi": point['aqi'],
                "routePoints": {
                  "lat": point['routePoints'].latitude,
                  "lng": point['routePoints'].longitude,
                },
              };
            }).toList(),
        routeDetail: myfinalfilterdetail,
      ),
    );
    await AppLocationService.startTracking(notificationdata, bgpermission, false, (
      pos,
    ) {
      final currentRawLatLng = pos;
      log("updated live location traking: $currentRawLatLng");
      // --- Snapping Logic ---
      LatLng snappedLatLng = currentRawLatLng; // Initialize with raw location
      double minDistance = double.infinity;
      // Iterate through each segment of the polyline
      for (int i = 0; i < currentPolylinePath.length - 1; i++) {
        final LatLng p1 = currentPolylinePath[i];
        final LatLng p2 = currentPolylinePath[i + 1];
        // Calculate the closest point on the segment (p1-p2) to currentRawLatLng
        final LatLng pointOnSegment = repository.getClosestPointOnSegment(
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

      const double SNAP_THRESHOLD_METERS = 50.0; // e.g., 50 meters
      if (minDistance > SNAP_THRESHOLD_METERS) {
        snappedLatLng = currentRawLatLng; // Don't snap if too far off the path
        print(
          "User is off-route: ${minDistance.toStringAsFixed(2)} meters from polyline.",
        );
        // You might want to emit a state indicating "off-route" or show a warning.
      }
      // --- End Snapping Logic ---

      if (lastPosition == null) {
        lastPosition = snappedLatLng;
        repository.addOnNavigationHistory(
          lastPosition!,
          currentPolylinePath.first,
          filterDetail['route_total_distance'],
          {
            "index_id": filterDetail['route_index'],
            "avgAqi": filterDetail['route_avg_aqi'],
            "pathpoints": currentPolylinePath,
            "saddress":
                repository
                    .finaloverviewdetail[filterDetail['route_index']]['start_address'],
            "eaddress":
                repository
                    .finaloverviewdetail[filterDetail['route_index']]['end_address'],
          },
        );
        add(UpdateLiveLocation(snappedLatLng, filterrouteindex, false));
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
          repository.addOnNavigationHistory(
            lastPosition!,
            currentPolylinePath.first,
            filterDetail['route_total_distance'],
            {
              "index_id": filterDetail['route_index'],
              "avgAqi": filterDetail['route_avg_aqi'],
              "pathpoints": currentPolylinePath,
              "saddress":
                  repository
                      .finaloverviewdetail[filterDetail['route_index']]['start_address'],
              "eaddress":
                  repository
                      .finaloverviewdetail[filterDetail['route_index']]['end_address'],
            },
          );
          add(UpdateLiveLocation(snappedLatLng, filterrouteindex, false));
        }
      }
    });
    // }
  }

  Future<void> _onResumeLiveTracking(
    ResumeLiveTrakingEvent event, // Event now carries polylineCoordinates
    Emitter<MapState> emit,
  ) async {
    emit(MapLoading());
    final filterDetail = event.rawdata.routeDetail;
    final List<LatLng> currentPolylinePath =
        event.rawdata.polylines.first.map((e) => LatLng(e.lat, e.lng)).toList();
    final List<Map> caqiDetailallroutes = event.rawdata.aqiDetailList;
    if (currentPolylinePath.length < 2) {
      return;
    }
    bool bgpermission =
        await PermissionHandlers.requestAllTimeLocationPermission();
    if (!bgpermission) {
      bgpermission = await UtilDialog.showRetry2(
        title: "Allow All-Time Location Access?",
        content:
            "Have you granted the app permission to access your location at all times for accurate navigation?",
        onClose: () async {
          return await PermissionHandlers.requestAllTimeLocationPermission();
        },
        isDeny: true
      );
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
      _locationSubscription?.cancel(); // Cancel any existing subscription
      LatLng? lastPosition;
      final polylinepointd = currentPolylinePath;

      await AppLocationService.startTracking(null, bgpermission, false, (pos) {
        final currentRawLatLng = pos;
        log("updated live location traking: $currentRawLatLng");
        // --- Snapping Logic ---
        LatLng snappedLatLng = currentRawLatLng; // Initialize with raw location
        double minDistance = double.infinity;
        // Iterate through each segment of the polyline
        for (int i = 0; i < currentPolylinePath.length - 1; i++) {
          final LatLng p1 = currentPolylinePath[i];
          final LatLng p2 = currentPolylinePath[i + 1];
          // Calculate the closest point on the segment (p1-p2) to currentRawLatLng
          final LatLng pointOnSegment = repository.getClosestPointOnSegment(
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

        const double SNAP_THRESHOLD_METERS = 50.0; // e.g., 50 meters
        if (minDistance > SNAP_THRESHOLD_METERS) {
          snappedLatLng =
              currentRawLatLng; // Don't snap if too far off the path
          print(
            "User is off-route: ${minDistance.toStringAsFixed(2)} meters from polyline.",
          );
          // You might want to emit a state indicating "off-route" or show a warning.
        }
        // --- End Snapping Logic ---

        if (lastPosition == null) {
          lastPosition = snappedLatLng;
          repository.addOnNavigationHistory(
            lastPosition!,
            currentPolylinePath.first,
            filterDetail!['distance'] ?? '',
            {
              "index_id": filterDetail['route_index'],
              "avgAqi": filterDetail['avg_aqi'],
              "pathpoints": currentPolylinePath,
              "saddress": filterDetail['start_address'],
              "eaddress": filterDetail['end_address'],
            },
          );
          filterrouteindex = filterDetail['route_index'];
          add(
            UpdateLiveLocation(
              snappedLatLng,
              (filterrouteindex is String) ? 0 : filterrouteindex,
              true,
            ),
          );
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
            repository.addOnNavigationHistory(
              lastPosition!,
              currentPolylinePath.first,
              int.tryParse(filterDetail!['distance']) ?? 0,
              {
                "index_id": filterDetail['route_index'],
                "avgAqi": filterDetail['avg_aqi'],
                "pathpoints": currentPolylinePath,
                "saddress": filterDetail['start_address'],
                "eaddress": filterDetail['end_address'],
              },
            );
            add(UpdateLiveLocation(snappedLatLng, filterrouteindex, true));
          }
        }
      });
    }
  }

  // -------------------------
  // ✅ Update live tracking state
  Future<void> _onUpdateLiveTracking(
    UpdateLiveLocation event,
    Emitter<MapState> emit,
  ) async {
    log("i am in update : ${event.isperRide}");
    await getCurrentLocationmarker(event.latLng, IMAGECONST.NAVIGATOR_POINT);
    final nearestData = await repository.getNearestStepAQI(
      currentLatLng: event.latLng,
      routeindex: event.routeindex,
      islastride: event.isperRide,
    );
    emit(
      CurrentLocationState(
        currentLocation: event.latLng,
        useraddress: 'Fetching...', // Or reverse geocode if needed
        transportMode: TransportMode.Driving,
        markers: repository.markers,
        initialfilter: -1,
        nearestdetail: nearestData,
      ),
    );
  }

  // -------------------------
  // ✅ Stop live tracking
  Future<void> _onStopLiveTracking(
    StopLiveLocationTracking event,
    Emitter<MapState> emit,
  ) async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    debugPrint('🚫 Live tracking stopped');
    DataReterival.deleteCurrentRide();
    await AppLocationService.stopTracking();

    // await AppLocationService().stopBackgroundTracking();
    final markerId = MarkerId('current_location');
    repository.markers.removeWhere((element) => element.markerId == markerId);
    emit(StopLiveLocationTrackingState()); // Or a custom stopped state
  }

  // -------------------------
  // ✅ Create current location marker
  Future<void> getCurrentLocationmarker(LatLng current, iconString) async {
    await repository.updateMarker(
      type: "current_location",
      position: current,
      assetimage: iconString,
      size: Size(43, 43),
      onTap:
          (type, position) => add(ShowMarkercustomInfoWindow(position, type)),
      onDragEnd: (id, position) {},
    );
    // final Marker marker = Marker(
    //   markerId: markid,
    //   position: current,
    //   infoWindow: const InfoWindow(title: 'My Location'),
    //   icon: iconString, // repository.customMapIcon["my_location"],
    // );
    // return {"markid": markid, 'marker': marker};
  }

  // -------------------------
  // ✅ Pin Location Adrees Detail
  Future<void> _pinlocationAddressDetail(
    PinLocation event,
    Emitter<MapState> emit,
  ) async {
    emit(MapLoading());
    final clatlng = await repository.getCurrentPosition();
    final result = await repository.fetchAddressFromLatLngGAPi(
      clatlng.latitude,
      clatlng.longitude,
    );

    if (result['status']) {
      await getCurrentLocationmarker(
        result['latlng'],
        IMAGECONST.NAVIGATOR_POINT,
      );
      emit(
        CurrentLocationState(
          currentLocation: result['latlng'],
          markers: repository.markers,
          // mrkid: cmarker['markid'],
          useraddress: result['detail'],
          isLoading: false,
          transportMode: TransportMode.Stop,
          initialfilter: -1,
        ),
      );
    } else {
      emit(OutOFRangeStage(message: result['detail']));
    }
  }

  FutureOr<void> _trigerCustomInfoWindow(
    ShowMarkercustomInfoWindow event,
    Emitter<MapState> emit,
  ) async {
    log("i am here on tap custom");
    final address = await repository.getAddressFromLatLng(event.latLng);
    emit(
      ShowOnTapMarkerWindorInfoState(
        address: address,
        type: event.markid,
        position: event.latLng,
      ),
    );
  }

  FutureOr<void> _hideCustomMarkerInfo(
    HideMarkercustomInfoWindow event,
    Emitter<MapState> emit,
  ) {
    emit(HideOnTapMarkerWindorInfoState());
  }

  Future<void> _updatepointonlocationdrag(
    UpdatepinPointRouteSEEvent event,
    Emitter<MapState> emit,
  ) async {
    emit(
      OnDragPinPointSEState(
        address: event.updateaddress,
        id: event.id,
        position: event.updateposition,
      ),
    );
  }
}
