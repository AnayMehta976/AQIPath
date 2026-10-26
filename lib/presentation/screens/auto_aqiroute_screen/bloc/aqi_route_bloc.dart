import 'dart:async';
import 'dart:developer';
import 'package:aqi_app/data/local/HiveLDB/Hive_DataRetival.dart';
import 'package:aqi_app/data/repository/MapScreen_repositry/MapScreen_repositary.dart';
import 'package:aqi_app/utils/Background_services/Background_services_mtd.dart';
import 'package:aqi_app/utils/geo_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../data/models/aqi_point.dart';
import '../../../../data/models/route_option.dart';
import '../../../../data/repository/aqi_route_repository/aqi_route_repo.dart';

part 'aqi_route_event.dart';
part 'aqi_route_state.dart';

class AqiRouteBloc extends Bloc<AqiRouteEvent, AqiRouteState> {
  AqiRouteRepository repository = AqiRouteRepository();
  GeoUtils geoUtils = GeoUtils();

  // this.repository
  AqiRouteBloc() : super(AqiRouteInitial()) {
    on<StartPipeline>(_onStartPipeline);
    on<AddCircle>(_onAddCircle);
    on<GenerateDensePoints>(_onGenerateDensePoints);
    on<GenerateRoutes>(_onGenerateRoutes);
    on<FetchDirections>(_onFetchDirections);
    on<PolylineTapped>(_onPolylineTapped);
    on<OnTapActionbtn>(_onTapactionbtn);
    on<SelectRouteEvent>(_onSelectRoute);
    on<StartLiveLocationTracking>(_onStartLiveTracking);
    on<UpdateLiveLocation>(_onUpdateLiveTracking);
    on<StopLiveLocationTracking>(_onStopLiveTracking);
  }

  // Future<void> _initlizedDetail(
  //   LoadAqiRoute event,
  //   Emitter<AqiRouteState> emit,
  // ) async {
  //   repository.centerPoint = event.center;

  // }
  @override
  Future<void> close() {
    repository.locationSubscription?.cancel();
    return super.close();
  }

  Future<void> _onStartPipeline(
    StartPipeline event,
    Emitter<AqiRouteState> emit,
  ) async {
    try {
      repository.centerPoint = AqiPoint(
        id: "center",
        pos: event.center,
        aqi: 0.0,
      );
      repository.radiusKm = event.radiusKm;
      repository.tMode = event.tMode;
      log("initlized Circle....");
      emit(AqiRouteLoading(0.02));
      add(AddCircle());
    } catch (e) {
      emit(AqiRouteError(e.toString()));
    }
  }

  void _onAddCircle(AddCircle event, Emitter<AqiRouteState> emit) async {
    log("Adding Circle....");
    repository.circle = Circle(
      circleId: CircleId('searchRadius'),
      center: repository.centerPoint.pos,
      radius: repository.radiusKm * 1000,
      fillColor: Colors.blue.withOpacity(0.06),
      strokeColor: Colors.blue.withOpacity(0.5),
      strokeWidth: 1,
    );

    await Future.delayed(const Duration(milliseconds: 150));
    emit(AqiRouteCircleAdded(repository.circle!));
  }

  Future<void> _onGenerateDensePoints(
    GenerateDensePoints event,
    Emitter<AqiRouteState> emit,
  ) async {
    emit(AqiRouteLoading(0.45));
    log("fetching markers....");
    final data = await repository.generateDensePointsAndAqiMarkersHeatmap();
    emit(AqiRouteLoading(0.8));
    await Future.delayed(const Duration(milliseconds: 150));
    emit(AqiRoutePointsGenerated(data['markers'], data["heatmaps"]));
    // take your _generateDensePointsAndMarkers logic and emit AqiRoutePointsGenerated
  }

  Future<void> _onGenerateRoutes(
    GenerateRoutes event,
    Emitter<AqiRouteState> emit,
  ) async {
    log("Generate Routes....");
    final allrowroutes = await repository.generateRouteCandidatesAndDraw(
      center: repository.centerPoint.pos,
      radiusKm: repository.radiusKm,
    );

    emit(
      AqiRouteGenerated(allrowroutes, repository.polylines, repository.tMode),
    );
  }

  Future<void> _onFetchDirections(
    FetchDirections event,
    Emitter<AqiRouteState> emit,
  ) async {
    // log("jkk-${event.route.length.toString()}");
    // log("my routes: ${event.route}");
    List<RouteOption> myfinalallroutes = [];
    for (var i = 0; i < event.route.length; i++) {
      final progress = 0.8 + ((i + 1) / event.route.length) * 0.2;
      
      List<RouteOption> rolist = await repository.fetchDirectionsForRoute(
        event.route[i],
        mode: event.mode.name,
        distance: event.distance,
      );
      emit(AqiRouteLoading(progress));
      // final myfinalmarker = repository.markers;
      // log("My lenght before: ${myfinalmarker.length}");
      // myfinalmarker.retainWhere(
      //   (e) =>
      //       e.markerId.value.startsWith("center") ||
      //       e.markerId.value.startsWith("F-"),
      // );
      myfinalallroutes.addAll(rolist);
      // log("My final Marker: ${myfinalmarker.length}");
    }
    emit(AqiRouteLoading(1));
    await Future.delayed(Duration(seconds: 1));
    print("all routes Info: "+myfinalallroutes.toString());
    emit(
      AqiRouteWithDirections(
        myfinalallroutes,
        repository.polylines,
        repository.markers,
      ),
    );
  }

  void _onPolylineTapped(PolylineTapped event, Emitter<AqiRouteState> emit) {
    // emit something like SelectedRouteState
  }

  Future<void> _onTapactionbtn(
    OnTapActionbtn event,
    Emitter<AqiRouteState> emit,
  ) async {
    if (event.tapindex == 1) {
      List<RouteOption> allroutes = repository.finalroutesDetail;
      emit(
        ActionTapResponse(
          svalue: !event.svalue,
          index: event.tapindex,
          routes: allroutes,
          otherdata: null,
        ),
      );
    }
  }

  // -------------------------
  // ✅ Stop live tracking
  Future<void> _onStopLiveTracking(
    StopLiveLocationTracking event,
    Emitter<AqiRouteState> emit,
  ) async {
    await repository.locationSubscription?.cancel();
    repository.locationSubscription = null;
    debugPrint('🚫 Live tracking stopped.');
    final markerId = MarkerId('current_location');
    repository.markers.removeWhere((element) => element.markerId == markerId);
    debugPrint('🚫 Live tracking stopped');
    DataReterival.deleteCurrentRide();
    await AppLocationService.stopTracking();
    emit(StopLiveLocationTrackingState()); // Or a custom stopped state
  }

  // -------------------------
  // ✅ Update live tracking state
  Future<void> _onUpdateLiveTracking(
    UpdateLiveLocation event,
    Emitter<AqiRouteState> emit,
  ) async {
    emit(
      UpdateLiveLocationState(
        currentLocation: event.currentLocation,
        markers: event.markers,
        transportMode: repository.tMode,
        useraddress: event.useraddress,
        nearestdetail: event.nearestdetail,
      ),
    );
  }

  Future<void> _onSelectRoute(
    SelectRouteEvent event,
    Emitter<AqiRouteState> emit,
  ) async {
    final filterdetail = await repository.onSelectRoute(event.tapindex);
    emit(
      SelectrouteTapResponse(
        marker: filterdetail['marker'],
        routes: filterdetail['route'],
        isrouteindex: event.tapindex,
      ),
    );
  }

  Future<void> _onStartLiveTracking(
    StartLiveLocationTracking event,
    Emitter<AqiRouteState> emit,
  ) async {
    // -------------------------
    emit(AqiRouteInitial());
    repository.onStartLiveTracking((e, Marker m) async {
      String caddress = await repository.getAddressFromLatLng(m.position);
      add(
        UpdateLiveLocation(
          currentLocation: m.position,
          markers: m,
          transportMode: repository.tMode,
          useraddress: caddress,
          nearestdetail: e,
        ),
      );
    });

    // UpdateLiveLocationState
  }
}
