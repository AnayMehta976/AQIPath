import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';

import 'package:aqi_app/data/repository/MapScreen_repositry/MapScreen_repositary.dart';

abstract class MapState {}

class MapInitial extends MapState {}

class MapLoading extends MapState {}

class IsPermissionGranted extends MapState {
  final bool permission;

  IsPermissionGranted({required this.permission});
}

class CurrentLocationState extends MapState {
  final LatLng? currentLocation;
  final Set<Marker> markers;
  // String? mrkid;
  final String useraddress;
  final bool isLoading;
  final int initialfilter;
  final TransportMode transportMode;

  Map? nearestdetail;
  CurrentLocationState({
    required this.initialfilter,
    required this.transportMode,
    this.currentLocation,
    // this.mrkid,
    required this.useraddress,
    required this.markers,
    this.isLoading = false,
    this.nearestdetail,
  });
}

class MapLoaded extends MapState {
  final List<List<LatLng>> polylineCoordinates;
  final Set<Polyline>? polyline;
  // final Set<Heatmap> heatmap;
  final Set<Circle> aqicircle;
  final Marker? marker;
  final filterdata;

  MapLoaded({
    required this.polylineCoordinates,
    required this.aqicircle,
    this.polyline,
    this.marker,
    this.filterdata,
  });
  List<Object?> get props => [polylineCoordinates, polyline];
}

class MapAnalizeLoaded extends MapState {
  final List<List<LatLng>> polylineCoordinates;
  final Set<Polyline>? polyline;
  // final Set<Heatmap> heatmap;
  final Set<Circle> aqicircle;
  final Marker? marker;
  // final filterdata;

  MapAnalizeLoaded({
    required this.polylineCoordinates,
    required this.aqicircle,
    this.polyline,
    this.marker,
    // this.filterdata,
  });
}

class MapFilterLoaded extends MapState {
  final List<List<LatLng>> polylineCoordinates;
  // final Set<Heatmap> heatmap;
  final Set<Circle> aqicircle;
  final Map filterdata;
  final Set<Marker>? marker;
  final Set<Polyline>? polylines;

  MapFilterLoaded({
    required this.polylineCoordinates,
    required this.aqicircle,
    required this.filterdata,
    this.marker,
    this.polylines,
  });
}

class MapError extends MapState {
  final String message;

  MapError(this.message);
}

class MapLoadingState extends MapState {
  MapLoadingState();

  @override
  List<Object?> get props => [];
}

class SearchingPlacesState extends MapState {
  bool searchingOn;
  List<Prediction> prediction;
  SearchingPlacesState({required this.searchingOn, required this.prediction});
  @override
  List<Object?> get props => [searchingOn];
}

class UpdateCurrentLocationAddressState extends MapState {
  final address;
  final LatLng latlng;
  UpdateCurrentLocationAddressState({
    required this.address,
    required this.latlng,
  });
}

class StopLiveLocationTrackingState extends MapState {}

class OutOFRangeStage extends MapState {
  final message;
  OutOFRangeStage({required this.message});
  @override
  List<Object> get Props => [message];
}

class OnDragPinPointSEState extends MapState {
  final id;
  final LatLng position;
  final String address;
  OnDragPinPointSEState({
    this.id,
    required this.position,
    required this.address,
  });
}

class ShowOnTapMarkerWindorInfoState extends MapState {
  final LatLng position;
  final type;
  final String address;
  ShowOnTapMarkerWindorInfoState({
    required this.position,
    required this.address,
    this.type,
  });
}

class HideOnTapMarkerWindorInfoState extends MapState {}
