import 'dart:developer';
import 'dart:io' show Platform;

import 'package:aqi_app/configs/navigationservices.dart';
import 'package:aqi_app/utils/all_timepermission_dialog.dart';
import 'package:aqi_app/utils/dialog.dart';
import 'package:aqi_app/utils/toast.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';

class PermissionHandlers {
  static Future<bool> requestAllTimeLocationPermission() async {
    final location = loc.Location();
    final context = NavigationService.navigatorKey.currentContext!;

    // Step 1: Check if the location service is enabled.
    bool serviceEnabled = await _checkLocationService(location, context);
    if (!serviceEnabled) {
      return await UtilDialog.showRetry(
        title: "Location Disabled",
        content:
            "❌ Location service disabled. Please enable it in your phone settings.",
        onClose: () async {
          return await requestAllTimeLocationPermission();
        },
      );
    }

    // Step 2: Request basic "when-in-use" location permission.
    bool basicPermissionGranted = await _requestBasicPermission(
      location,
      context,
    );
    if (!basicPermissionGranted) {
      return await UtilDialog.showRetry(
        title: "Location Permission Denied",
        content: "❌ Location permission denied.",
        onClose: () async {
          return await requestAllTimeLocationPermission();
        },
      );
    }

    // Step 3: Request background ("Always") permission.
    bool allTimePermissionGranted = await _requestBackgroundPermission(
      location,
      context,
    );
    if (!allTimePermissionGranted) {
      // return await UtilDialog.showRetry(
      //   title: "Background Location Permission Needed",
      //   content:
      //       "❌ Background location permission is required. Please allow 'Always' access in app settings.",
      //   onClose: () async {
      //     return await requestAllTimeLocationPermission();
      //   },
      //   // openSettings: true,
      // );
      return false;
    }
    return true;
  }

  static Future<bool> _checkLocationService(
    loc.Location location,
    BuildContext context,
  ) async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        UtilToast.showMessageForUser(
          context,
          "❌ Location service disabled. Please enable it in your phone settings.",
        );
        return false;
      }
    }
    return true;
  }

  static Future<bool> _requestBasicPermission(
    loc.Location location,
    BuildContext context,
  ) async {
    loc.PermissionStatus permissionStatus = await location.hasPermission();

    if (permissionStatus == loc.PermissionStatus.denied) {
      permissionStatus = await location.requestPermission();
    }

    if (permissionStatus == loc.PermissionStatus.deniedForever) {
      UtilToast.showMessageForUser(
        context,
        "❌ Location permission permanently denied. Please enable it in app settings.",
      );
      await openAppSettings();
      return false;
    }

    if (permissionStatus == loc.PermissionStatus.denied) {
      UtilToast.showMessageForUser(context, "❌ Location permission denied.");
      return false;
    }

    log("Current location permission: $permissionStatus");

    return permissionStatus == loc.PermissionStatus.granted ||
        permissionStatus == loc.PermissionStatus.grantedLimited;
  }

  static Future<bool> _requestBackgroundPermission(
    loc.Location location,
    BuildContext context,
  ) async {
    // Android: request notification permission for foreground service
    if (Platform.isAndroid && await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    if (Platform.isIOS) {
      // ✅ First check "whenInUse" permission
      var whenInUseStatus = await Permission.locationWhenInUse.status;
      if (whenInUseStatus.isDenied || whenInUseStatus.isRestricted) {
        await Permission.locationWhenInUse.request();
        whenInUseStatus = await Permission.locationWhenInUse.status;
      }
      if (whenInUseStatus.isGranted) {
        bool alwaysGranted = await Permission.locationAlways.isGranted;

        if (!alwaysGranted) {
          await showLocationPermissionDialog(
            context,
            onAllow: () async {
              await Permission.locationAlways.request().then((v) async {
                print("Requested locationAlways permission result: $v ");
              });
              alwaysGranted = await Permission.locationAlways.isGranted;
              if (!alwaysGranted) {
                UtilToast.showMessageForUser(
                  context,
                  "❌ Background location access denied. Please allow 'Always' access in settings.",
                );
                await openAppSettings();
                return Navigator.pop(context, false);
              } else {
                return Navigator.pop(context, true);
              }
            },
            onSkip: () {
              return Navigator.pop(context, false);
            },
          );
        }
        return true;
      } else {
        UtilToast.showMessageForUser(
          context,
          "⚠️ Please allow location access while using the app first.",
        );
        await openAppSettings();
        return false;
      }
    }

    if (Platform.isAndroid) {
      // bool bgEnabled = await location.isBackgroundModeEnabled();
      // bool alwaysGranted = await Permission.locationAlways.isGranted;
      // log(
      //   "Background mode enabled: $bgEnabled, Always granted: $alwaysGranted",
      // );

      if (await location.isBackgroundModeEnabled() == false &&
          !(await Permission.locationAlways.isGranted)) {
        await showLocationPermissionDialog(
          context,
          onAllow: () async {
             await openAppSettings().then((e) async {
              if (await location.isBackgroundModeEnabled() == true &&
                  (await Permission.locationAlways.isGranted)) {
                return true;
              }
            });
            UtilToast.showMessageForUser(
              context,
              "❌ Background location access denied. Please allow 'All the time'.",
            );
            // return false;

            // await Permission.locationAlways.request().then((v) async {
            //   print("Requested locationAlways permission result: $v ");
            // });
           final  alwaysGranted = await Permission.locationAlways.isGranted;
            if (!alwaysGranted) {
              UtilToast.showMessageForUser(
                context,
                "❌ Background location access denied. Please allow 'Always' access in settings.",
              );
              await openAppSettings();
              return Navigator.pop(context, false);
            } else {
              return Navigator.pop(context, true);
            }
          },
          onSkip: () {
            return Navigator.pop(context, false);
          },
        );
        // await Permission.locationAlways.request();
        // await openAppSettings();

        bool bgRecheck = await location.isBackgroundModeEnabled();
        bool alwaysRecheck = await Permission.locationAlways.isGranted;

        if (bgRecheck && alwaysRecheck) {
          return true;
        }

        UtilToast.showMessageForUser(
          context,
          "❌ Background location access denied. Please allow 'All the time'.",
        );
        return false;
      }

      return true;
    }

    return false;
  }
}
