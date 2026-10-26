part of 'aqi_route_bloc.dart';

sealed class AqiRouteState extends Equatable {
  const AqiRouteState();

  @override
  List<Object> get props => [];
}

class AqiRouteInitial extends AqiRouteState {}

class AqiRouteLoading extends AqiRouteState {
  final double progress;
  const AqiRouteLoading(this.progress);
}

class AqiRouteLoaded extends AqiRouteState {
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final List<RouteOption> routes;
  final Circle circle;

  AqiRouteLoaded({
    required this.markers,
    required this.polylines,
    required this.routes,
    required this.circle,
  });
}

class AqiRouteError extends AqiRouteState {
  final String message;
  AqiRouteError(this.message);
}

class AqiRouteCircleAdded extends AqiRouteState {
  final Circle circle;
  const AqiRouteCircleAdded(this.circle);
}

class AqiRoutePointsGenerated extends AqiRouteState {
  final Set<Heatmap> heatmap;
  final Set<Marker> markers;

  const AqiRoutePointsGenerated(this.markers, this.heatmap);
}

class AqiRouteGenerated extends AqiRouteState {
  final List<RouteOption> routes;
  final Set<Polyline> polyline;
  final TransportMode mode;
  const AqiRouteGenerated(this.routes, this.polyline, this.mode);
}

class AqiRouteWithDirections extends AqiRouteState {
  final List<RouteOption> routes;
  final Set<Polyline> mypolyline;
  final Set<Marker> myMarker;
  const AqiRouteWithDirections(this.routes, this.mypolyline, this.myMarker);
}

class ActionTapResponse extends AqiRouteState {
  final List<RouteOption>? routes;
  final int index;
  final bool svalue;
  final Object? otherdata;

  const ActionTapResponse({
    required this.svalue,
    this.routes,
    required this.index,
    required this.otherdata,
  });

  @override
  List<Object> get props => [svalue, index];
}

class SelectrouteTapResponse extends AqiRouteState {
  final RouteOption routes;
  final Set<Marker> marker;
  int isrouteindex;

  SelectrouteTapResponse({
    required this.routes,
    required this.marker,
    required this.isrouteindex,
  });

  @override
  List<Object> get props => [marker, routes, isrouteindex];
}

class StopLiveLocationTrackingState extends AqiRouteState {}

class UpdateLiveLocationState extends AqiRouteState {
  final LatLng? currentLocation;
  final Marker markers;
  // String? mrkid;
  final String useraddress;
  final bool isLoading;
  // final int initialfilter;
  final TransportMode transportMode;

  Map? nearestdetail;
  UpdateLiveLocationState({
    // required this.initialfilter,
    required this.transportMode,
    this.currentLocation,
    // this.mrkid,
    required this.useraddress,
    required this.markers,
    this.isLoading = false,
    this.nearestdetail,
  });
  @override
  List<Object> get props => [currentLocation!];
}
