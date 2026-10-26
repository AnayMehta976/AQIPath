// import 'dart:async';
// import 'package:aqi_app/utils/Background_services/Background_services_mtd.dart';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:location/location.dart' as loc;

// class LocationTrackingService with WidgetsBindingObserver {
//   // Singleton setup (optional, can also use DI in Bloc)
//   static final LocationTrackingService _instance =
//       LocationTrackingService._internal();
//   factory LocationTrackingService() => _instance;
//   LocationTrackingService._internal();

//   final loc.Location _location = loc.Location();
//   StreamSubscription<loc.LocationData>? _locationSubscription;

//   /// Initialize observer
//   void init() {
//     WidgetsBinding.instance.addObserver(this);
//   }

//   /// Foreground tracking
//   Future<void> startForegroundTracking(
//     Function(LatLng) onLocationUpdate,
//   ) async {
//     bool serviceEnabled = await _location.serviceEnabled();
//     if (!serviceEnabled) {
//       serviceEnabled = await _location.requestService();
//       if (!serviceEnabled) return;
//     }

//     loc.PermissionStatus permissionGranted = await _location.hasPermission();
//     if (permissionGranted == loc.PermissionStatus.denied) {
//       permissionGranted = await _location.requestPermission();
//       if (permissionGranted != loc.PermissionStatus.granted) return;
//     }

//     if (permissionGranted == loc.PermissionStatus.granted) {
//       await _locationSubscription?.cancel();

//       _location.changeSettings(
//         accuracy: loc.LocationAccuracy.navigation,
//         interval: 1000, // ms
//         distanceFilter: 5, // meters
//       );

//       _locationSubscription = _location.onLocationChanged.listen((
//         locationData,
//       ) {
//         if (locationData.latitude == null || locationData.longitude == null)
//           return;
//         final latLng = LatLng(locationData.latitude!, locationData.longitude!);
//         onLocationUpdate(latLng);
//       });
//     }
//   }

//   /// Background tracking
//   Future<void> startBackgroundTracking(
//     Function(LatLng) onLocationUpdate,
//   ) async {
//     await BackgroundLocation.setAndroidNotification(
//       title: "AQI Live Tracking",
//       message: "Tracking your route in background",
//       icon: "@mipmap/ic_launcher",
//     );

//     await Backgroundlocationservices.startBackGroundLocationService(
     
//     );

//     BackgroundLocation.getLocationUpdates((location) {
//       if (location.latitude == null || location.longitude == null) return;
//       final latLng = LatLng(location.latitude!, location.longitude!);
//       onLocationUpdate(latLng);
//     });
//   }

//   /// Stop all tracking
//   Future<void> stopTracking() async {
//     await _locationSubscription?.cancel();
//     await BackgroundLocation.stopLocationService();
//   }

//   /// Lifecycle observer
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.paused) {
//       // Switch to background tracking
//       startBackgroundTracking((latLng) {
//         debugPrint("Background location: $latLng");
//       });
//     } else if (state == AppLifecycleState.resumed) {
//       // Stop background & switch back to foreground
//       stopTracking();
//       startForegroundTracking((latLng) {
//         debugPrint("Foreground location: $latLng");
//       });
//     }
//   }
// }
