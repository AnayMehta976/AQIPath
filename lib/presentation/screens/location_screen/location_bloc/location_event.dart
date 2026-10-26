import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';

import 'package:aqi_app/data/local/HiveLDB/HiveModel/CurrentRideRoute.dart';
import 'package:aqi_app/data/repository/MapScreen_repositry/MapScreen_repositary.dart';

enum RouteFilterType { all, lowAqi, averageAqi, fastest }

abstract class MapEvent {}

class InitmapNfetchcLocEvent extends MapEvent {
  LatLng? currentlatlng;
  final int initialfilter;
  final TransportMode mode;
  final int wayModepreferance;
  final double? wayRadiusKms;
  CurrentRideRoute? rowrunnigData;
  InitmapNfetchcLocEvent({
    required this.mode,
    required this.wayModepreferance,
    required this.initialfilter,
    this.currentlatlng,
    this.wayRadiusKms,
    this.rowrunnigData,
  });

  @override
  List<Object?> get props => [
    mode,
    currentlatlng,
    initialfilter,
    wayModepreferance,
    wayRadiusKms,
    rowrunnigData,
  ];
}

class PinLocation extends MapEvent {
  PinLocation();
}

class SearchRoute extends MapEvent {
  final LatLng origin;
  final LatLng destination;
  final TransportMode mode;
  SearchRoute(this.origin, this.destination, this.mode);
}

class AnalizeRoute extends MapEvent {
  final LatLng origin;
  final TransportMode mode;
  final int wayModepreferance;
  final double? wayRadiusKms;

  AnalizeRoute({
    required this.origin,
    required this.mode,
    required this.wayModepreferance,
    required this.wayRadiusKms,
  });

  List<Object?> get props => [origin, mode, wayModepreferance, wayRadiusKms];
}

class UpdatepinPointRouteSEEvent extends MapEvent {
  final String id;
  final LatLng updateposition;
  final String updateaddress;

  UpdatepinPointRouteSEEvent({
    required this.id,
    required this.updateposition,
    required this.updateaddress,
  });
}

class OnFilterRuote extends MapEvent {
  final RouteFilterType selectedFilter;
  final TransportMode mode;
  OnFilterRuote({required this.selectedFilter, required this.mode});
}

class SearchingPlacesEvent extends MapEvent {
  bool searchingOn;
  List<Prediction> prediction;
  SearchingPlacesEvent({required this.searchingOn, required this.prediction});
  List<Object?> get props => [searchingOn, prediction];
}

class StartLiveLocationTracking extends MapEvent {
  final String tmode;
  StartLiveLocationTracking({required this.tmode});

  StartLiveLocationTracking copyWith({String? tmode}) {
    return StartLiveLocationTracking(tmode: tmode ?? this.tmode);
  }

  Map<String, dynamic> toMap() {
    return {'tmode': tmode};
  }

  factory StartLiveLocationTracking.fromMap(Map<String, dynamic> map) {
    return StartLiveLocationTracking(tmode: map['tmode'] ?? '');
  }

  String toJson() => json.encode(toMap());

  factory StartLiveLocationTracking.fromJson(String source) =>
      StartLiveLocationTracking.fromMap(json.decode(source));

  @override
  String toString() => 'StartLiveLocationTracking(tmode: $tmode)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StartLiveLocationTracking && other.tmode == tmode;
  }

  @override
  int get hashCode => tmode.hashCode;
}

class ResumeLiveTrakingEvent extends MapEvent {
  final CurrentRideRoute rawdata;
  ResumeLiveTrakingEvent({required this.rawdata});
}

class StopLiveLocationTracking extends MapEvent {
  final bool ispreviousride;
  StopLiveLocationTracking({required this.ispreviousride});
}

class UpdateLiveLocation extends MapEvent {
  final LatLng latLng;
  final int routeindex;
  final bool isperRide;

  UpdateLiveLocation(this.latLng, this.routeindex, this.isperRide);
}

class ShowMarkercustomInfoWindow extends MapEvent {
  final LatLng latLng;
  final markid;

  ShowMarkercustomInfoWindow(this.latLng, this.markid);
}

class HideMarkercustomInfoWindow extends MapEvent {}
