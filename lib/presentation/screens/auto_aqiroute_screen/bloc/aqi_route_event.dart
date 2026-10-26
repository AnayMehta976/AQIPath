part of 'aqi_route_bloc.dart';

sealed class AqiRouteEvent extends Equatable {
  const AqiRouteEvent();

  @override
  List<Object> get props => [];
}

class LoadAqiRoute extends AqiRouteEvent {
  final LatLng center;
  final double radiusKm;
  final int kTop;
  LoadAqiRoute({required this.center, required this.radiusKm, this.kTop = 5});
}

class StartPipeline extends AqiRouteEvent {
  final LatLng center;
  final double radiusKm;
  final TransportMode tMode;
  const StartPipeline({
    required this.center,
    required this.radiusKm,
    required this.tMode,
  });
}

class AddCircle extends AqiRouteEvent {}

class ZoomToFitCircle extends AqiRouteEvent {}

class GenerateDensePoints extends AqiRouteEvent {}

class GenerateRoutes extends AqiRouteEvent {}

class FetchDirections extends AqiRouteEvent {
  final List<RouteOption> route;
  final TransportMode mode;
  final double distance;
  const FetchDirections(this.route, this.mode, {required this.distance});
}

class PolylineTapped extends AqiRouteEvent {
  final RouteOption route;
  const PolylineTapped(this.route);
}

class OnTapActionbtn extends AqiRouteEvent {
  final int tapindex;
  final bool svalue;
  const OnTapActionbtn({required this.tapindex, required this.svalue});
}

class SelectRouteEvent extends AqiRouteEvent {
  final int tapindex;
  const SelectRouteEvent({required this.tapindex});
}

class StartLiveLocationTracking extends AqiRouteEvent {}

class StopLiveLocationTracking extends AqiRouteEvent {}

class UpdateLiveLocation extends AqiRouteEvent {
  final LatLng? currentLocation;
  final Marker markers;
  // String? mrkid;
  final String useraddress;
  final bool isLoading;
  // final int initialfilter;
  final TransportMode transportMode;

  Map? nearestdetail;
  UpdateLiveLocation({
    // required this.initialfilter,
    required this.transportMode,
    this.currentLocation,
    // this.mrkid,
    required this.useraddress,
    required this.markers,
    this.isLoading = false,
    this.nearestdetail,
  });
}
