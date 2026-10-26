class RouteOverview {
  final int distance; // in meters
  final int duration; // in seconds
  final int durationInTraffic; // in seconds
  final String startAddress;
  final String endAddress;

  RouteOverview({
    required this.distance,
    required this.duration,
    required this.durationInTraffic,
    required this.startAddress,
    required this.endAddress,
  });

  factory RouteOverview.fromLeg(Map<String, dynamic> leg) {
    return RouteOverview(
      distance: leg["distance"]['value'],
      duration: leg["duration"]['value'],
      durationInTraffic:
          leg["duration_in_traffic"] != null
              ? leg["duration_in_traffic"]['value']
              : leg["duration"]['value'],
      startAddress: leg["start_address"],
      endAddress: leg["end_address"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "distance": distance,
      "duration": duration,
      "duration_in_traffic": durationInTraffic,
      "start_address": startAddress,
      "end_address": endAddress,
    };
  }
}
