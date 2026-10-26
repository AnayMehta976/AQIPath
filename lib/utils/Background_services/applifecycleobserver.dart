import 'package:aqi_app/utils/Background_services/Background_services_mtd.dart';
import 'package:flutter/material.dart';

class AppLifecycleObserver extends WidgetsBindingObserver {
  final AppLocationService _locationService = AppLocationService();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // if (!_locationService.isTracking) return; // only if tracking active

    try {
      switch (state) {
        case AppLifecycleState.resumed:
          // _locationService.startForegroundTracking((LatLng pos) {
          print("Foreground Location: $state");
          // });
          break;

        case AppLifecycleState.paused:
          if (isStarttraking) {
            AppLocationService.isBackgroundServiceRunning();
          }

          // _locationService.startBackgroundTracking((data) {
          print("Background Location: $state");
          // });
          break;

        case AppLifecycleState.inactive:
          print("App inactive (lock screen). Ignored.");
          if (isStarttraking) {
            AppLocationService.isBackgroundServiceRunning();
          }

          break;

        case AppLifecycleState.detached:
          // _locationService.stopForegroundTracking();
          // _locationService.stopBackgroundTracking();
          break;

        case AppLifecycleState.hidden: // 👈 new one
          if (isStarttraking) {
            AppLocationService.isBackgroundServiceRunning();
          }
          print("App hidden (Android only). Ignored.");

          break;
      }
    } catch (e, st) {
      print("Lifecycle tracking error: $e\n$st");
    }
  }
}
