import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:aqi_app/configs/network.dart';
import 'package:aqi_app/constants/constants.dart';
import 'package:aqi_app/constants/key_constant.dart';

import 'package:aqi_app/data/local/pref.dart';
import 'package:aqi_app/main.dart';
import 'package:aqi_app/utils/Background_services/location_callback_handler.dart';
import 'package:background_locator_2/background_locator.dart';
import 'package:background_locator_2/location_dto.dart';
import 'package:background_locator_2/settings/android_settings.dart';
import 'package:background_locator_2/settings/ios_settings.dart';
import 'package:background_locator_2/settings/locator_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:shared_preferences/shared_preferences.dart';

const String _isolateName = "location_port";
bool isStarttraking = false;

@pragma('vm:entry-point')
class AppLocationService {
  static SendPort? _sendPort;
  static ReceivePort? _receivePort;
  static StreamSubscription<loc.LocationData>? _locationSubscription;
  static final loc.Location _location = loc.Location();
  String inst = "";

  /// Background isolate callback
  @pragma('vm:entry-point')
  static void callback(LocationDto dto) async {
    // 🔄 Update the notification text
    try {
      Map mynotifydata = await getNearestStepAQI(
        currentLatLng: LatLng(dto.latitude, dto.longitude),
      );
      print("updating mynotifydata: " + mynotifydata.toString());
      if (Platform.isAndroid) {
        BackgroundLocator.updateNotificationText(
          title: "AQI Tracker 🚀",
          msg:
              "🔆 AQI ${mynotifydata['aqiValue']} • ${mynotifydata["turnInstructionHtml"]}",
          bigMsg:
              "🚩 ${mynotifydata["turnInstructionHtml"]}\n🚧 ${mynotifydata["routeDetail"]}",
        );
      } else {
        localNotificationService.updateNotification(
          title: "AQI Tracker 🚀",
          body:
              "🔆 AQI ${mynotifydata['aqiValue']} • ${mynotifydata["turnInstructionHtml"]}",
        );
      }

      final SendPort? send = IsolateNameServer.lookupPortByName(_isolateName);
      if (send != null) {
        send.send([dto.latitude, dto.longitude]);
      }
    } catch (e) {
      print("Error From Reciver:- $e");
    }
  }

  @pragma('vm:entry-point')
  static void notificationCallback() {
    // mandatory for plugin
  }

  /// ✅ Start both foreground + background tracking
  @pragma('vm:entry-point')
  static Future<void> startTracking(
    Map? mydatanotify,
    bool isbgpermission,
    bool frombg,
    Function(LatLng) onLocationUpdate,
  ) async {
    if (Platform.isAndroid) {
      isStarttraking = true;
      // mydataroute = mydatanotify;
      if (mydatanotify != null) {
        LocalPref.setString(SavedKey.STREAM_BG_DATA, jsonEncode(mydatanotify));
      } else {
        var preferences = await SharedPreferences.getInstance();
        final String? lastFetch = preferences.getString(
          SavedKey.STREAM_BG_DATA,
        );
        Map? mydata;
        // int distancebreak = preferences.getInt("distancebreakpoint") ?? 0;
        if (lastFetch != null) {
          mydata = jsonDecode(lastFetch);
          if (mydata!['aqis'] is String) {
            mydata['aqis'] = jsonDecode(mydata['aqis']);
          }
        }
        mydatanotify = mydata;
      }

      // Register port for background messages
      if (!frombg) {
        _receivePort = ReceivePort();
        IsolateNameServer.removePortNameMapping(_isolateName);
        IsolateNameServer.registerPortWithName(
          _receivePort!.sendPort,
          _isolateName,
        );
        _receivePort!.listen((dynamic data) {
          final lat = data[0] as double;
          final lng = data[1] as double;
          onLocationUpdate(LatLng(lat, lng));
        });

        // Foreground location subscription
        bool serviceEnabled = await _location.serviceEnabled();
        if (!serviceEnabled) {
          serviceEnabled = await _location.requestService();
          if (!serviceEnabled) return;
        }

        var permission = await _location.hasPermission();
        if (permission == loc.PermissionStatus.denied) {
          permission = await _location.requestPermission();
          if (permission != loc.PermissionStatus.granted) return;
        }
        _location.changeSettings(
          accuracy: loc.LocationAccuracy.navigation,
          interval: 100,
          distanceFilter: 20,
        );
        _locationSubscription = _location.onLocationChanged.listen((data) {
          if (data.latitude != null && data.longitude != null) {
            final mylatlng = LatLng(data.latitude!, data.longitude!);
            onLocationUpdate(mylatlng);
          }
        });
      }
    } else {
      isStarttraking = true;
      // mydataroute = mydatanotify;
      if (mydatanotify != null) {
        LocalPref.setString(SavedKey.STREAM_BG_DATA, jsonEncode(mydatanotify));
      } else {
        var preferences = await SharedPreferences.getInstance();
        final String? lastFetch = preferences.getString(
          SavedKey.STREAM_BG_DATA,
        );
        Map? mydata;
        // int distancebreak = preferences.getInt("distancebreakpoint") ?? 0;
        if (lastFetch != null) {
          mydata = jsonDecode(lastFetch);
          if (mydata!['aqis'] is String) {
            mydata['aqis'] = jsonDecode(mydata['aqis']);
          }
        }
        mydatanotify = mydata;
      }
      // await enableBackgroundMode();
      // Register port for background messages

      if (isbgpermission) {
        _receivePort = ReceivePort();
        IsolateNameServer.removePortNameMapping(_isolateName);
        IsolateNameServer.registerPortWithName(
          _receivePort!.sendPort,
          _isolateName,
        );
        _receivePort!.listen((dynamic data) {
          final lat = data[0] as double;
          final lng = data[1] as double;
          onLocationUpdate(LatLng(lat, lng));
        });
      }

      if (!isbgpermission) {
        // Foreground location subscription
        bool serviceEnabled = await _location.serviceEnabled();
        if (!serviceEnabled) {
          serviceEnabled = await _location.requestService();
          if (!serviceEnabled) return;
        }
        var permission = await _location.hasPermission();
        if (permission == loc.PermissionStatus.denied) {
          permission = await _location.requestPermission();
          if (permission != loc.PermissionStatus.granted) return;
        }

        _location.changeSettings(
          accuracy: loc.LocationAccuracy.navigation,
          interval: 1000,
          distanceFilter: 20,
        );
        _locationSubscription = _location.onLocationChanged.listen((data) {
          if (data.latitude != null && data.longitude != null) {
            final mylatlng = LatLng(data.latitude!, data.longitude!);
            debugPrint(
              "Foreground location update: ${data.latitude}, ${data.longitude}",
            );
            if (Platform.isIOS) {
              localNotificationService.showNotification(
                title: "AQI Path Tracker 🚀",
                body: "🔆 AQI Initializing...",
              );
            }

            onLocationUpdate(mylatlng);
          }
        });
      }

      // await BackgroundLocator.initialize();
      if (isbgpermission) {
        // Background locator
        final initialized = await BackgroundLocator.isServiceRunning();
        if (!initialized) {
          await BackgroundLocator.initialize();
        }
        // Prevent double-registration
        await BackgroundLocator.unRegisterLocationUpdate();
        Network.init();
        await BackgroundLocator.registerLocationUpdate(
          callback,
          iosSettings: IOSSettings(
            accuracy: LocationAccuracy.NAVIGATION,
            distanceFilter: 30,
            showsBackgroundLocationIndicator: true,
            stopWithTerminate: true,
          ),
          androidSettings: AndroidSettings(
            accuracy: LocationAccuracy.NAVIGATION,
            interval: 30, // every 10 sec
            distanceFilter: 30,
            client:
                Network.connected
                    ? LocationClient.google
                    : LocationClient.android,
            androidNotificationSettings: AndroidNotificationSettings(
              notificationChannelName: 'Location tracking',
              notificationTitle: 'Let\'s Start ${mydatanotify!['mode']}',
              notificationMsg:
                  'Way to 👉 ${mydatanotify["eaddress"].toString().substring(0, 50)}...',
              notificationBigMsg:
                  'Way to 👉 ${mydatanotify["eaddress"].toString()}\n '
                  '🔆 Avg AQI ${mydatanotify['avgaqi'].round()} ● Distance ${mydatanotify["avgdistance"]}',
              notificationIcon: '@drawable/ic_launcher',
              notificationIconColor:
                  COLOR_CONST
                      .backgroundColor, // <-- Make sure this icon exists!
            ),
          ),
        );
      }
    }
  }

  /// ⛔ Stop tracking and cleanup
  @pragma('vm:entry-point')
  static Future<void> stopTracking() async {
    isStarttraking = false;
    await _locationSubscription?.cancel();
    _locationSubscription = null;

    if (await BackgroundLocator.isServiceRunning()) {
      await BackgroundLocator.unRegisterLocationUpdate();
    }

    if (_receivePort != null) {
      IsolateNameServer.removePortNameMapping(_isolateName);
      _receivePort!.close();
      _receivePort = null;
    }
  }

  /// NearestStepApi
  static Future<Map<String, dynamic>> getNearestStepAQI({
    required LatLng currentLatLng,
  }) async {
    print("I am in getNearestStepAQI");
    var mydata;
    // if (routeindex == -1) return {};
    // STREAM_BG_DATA
    var preferences = await SharedPreferences.getInstance();
    final String? lastFetch = preferences.getString(SavedKey.STREAM_BG_DATA);
    int distancebreak = preferences.getInt("distancebreakpoint") ?? 0;
    print("I am in $lastFetch $distancebreak");
    if (lastFetch != null) {
      mydata = jsonDecode(lastFetch);
    } else {
      return {};
    }

    print("i am called in: $mydata");
    final steps =
        // finalrouteDetail['direction_Mdata']['routes'][routeindex]['legs'][0]['steps'];
        mydata['steps'];

    double minDistance = double.infinity;
    Map closestStep = {};
    print("i am called in step: $steps");
    for (final step in steps) {
      final stepLat = step['start_location']['lat'] as double;
      final stepLng = step['start_location']['lng'] as double;

      final distance = geo.Geolocator.distanceBetween(
        currentLatLng.latitude,
        currentLatLng.longitude,
        stepLat,
        stepLng,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestStep = step;
      }
    }

    int closestAQI = 0;

    if (closestStep != null) {
      final stepLat = closestStep['start_location']['lat'] as double;
      final stepLng = closestStep['start_location']['lng'] as double;

      double minAQIDistance = double.infinity;
      log("i am called in aqi: ${mydata['aqis']}");
      if (mydata['aqis'] is String) {
        mydata['aqis'] = jsonDecode(mydata['aqis']);
      }
      for (final point in mydata['aqis']) {
        print("i am called in jk1");
        final aqi = point['aqi'].round();
        print("i am called in jk2");
        final LatLng coords;
        if (point['routePoints'] is LatLng) {
          coords = point['routePoints'];
        } else if (point['routePoints'] is Map) {
          coords = LatLng(
            (point['routePoints']['lat'] as num).toDouble(),
            (point['routePoints']['lng'] as num).toDouble(),
          );
        } else {
          continue;
        }
        final distance = geo.Geolocator.distanceBetween(
          stepLat,
          stepLng,
          coords.latitude,
          coords.longitude,
        );

        if (distance < minAQIDistance) {
          minAQIDistance = distance;
          closestAQI = aqi;
        }
      }

      final distancecover = geo.Geolocator.distanceBetween(
        mydata['startendlatlng'][0],
        mydata['startendlatlng'][1],
        currentLatLng.latitude,
        currentLatLng.longitude,
      );

      double remaindistance = (mydata['avgdistance']) - distancecover;

      if (distancecover >= distancebreak) {
        // DataReterival.updateCenter(
        //   LatLngPoint(
        //     lat: currentLatLng.latitude,
        //     lng: currentLatLng.longitude,
        //   ),
        // );
        preferences.setInt("distancebreakpoint", distancebreak + 100);
      }
      if (remaindistance < 100) {
        stopTracking();
      }

      final filldata = {
        'aqiValue': closestAQI,
        'turnInstructionHtml': stripHtmlTags(
          closestStep['html_instructions'] as String,
        ),
        'routeDetail':
            'Next ${(closestStep['distance']['text'])} · ${closestStep['duration']['text']} · AQI $closestAQI  · Dist Cover ${formatDistance(distancecover)} · Remain Dist ${formatDistance(remaindistance)} · ${mydata['mode']}',
        'distancecover': remaindistance.round() / 1000,
      };

      // log("my fillied data : $filldata");
      return filldata;
    }

    return {
      'aqiValue': closestAQI,
      'turnInstructionHtml': '',
      'routeDetail': '',
    };
  }

  static String formatDistance(double distanceInMeters) {
    debugPrint("Distance in Meter: $distanceInMeters");
    if (distanceInMeters < 1000) {
      // less than 1 km → show in meters
      return "${distanceInMeters.toStringAsFixed(0)} m";
    } else {
      // 1 km or more → show in km with 2 decimals
      double km = distanceInMeters / 1000;
      return "${km.toStringAsFixed(2)} km";
    }
  }

  static String stripHtmlTags(String htmlText) {
    final regex = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    String cleanText = htmlText.replaceAll(regex, "").trim();

    // Add emojis based on common navigation keywords
    String lower = cleanText.toLowerCase();
    if (lower.contains("left")) {
      cleanText = "⬅️ $cleanText";
    } else if (lower.contains("right")) {
      cleanText = "➡️ $cleanText";
    } else if (lower.contains("straight")) {
      cleanText = "⬆️ $cleanText";
    } else if (lower.contains("slight left")) {
      cleanText = "↖️ $cleanText";
    } else if (lower.contains("slight right")) {
      cleanText = "↗️ $cleanText";
    } else if (lower.contains("u-turn")) {
      cleanText = "🔄 $cleanText";
    } else if (lower.contains("merge")) {
      cleanText = "🛣️ $cleanText";
    } else if (lower.contains("roundabout")) {
      cleanText = "⚪ $cleanText";
    }

    return cleanText;
  }

  /// Check if background tracking service is active
  static Future<void> isBackgroundServiceRunning() async {
    try {
      final isRunning = await BackgroundLocator.isServiceRunning();
      log("📡 Background service running: $isRunning");
      if (!isRunning) {
        var preferences = await SharedPreferences.getInstance();
        final String? lastFetch = preferences.getString(
          SavedKey.STREAM_BG_DATA,
        );
        Map? mydata;
        // int distancebreak = preferences.getInt("distancebreakpoint") ?? 0;
        if (lastFetch != null) {
          mydata = jsonDecode(lastFetch);
          if (mydata!['aqis'] is String) {
            mydata['aqis'] = jsonDecode(mydata['aqis']);
          }
        }
        if (mydata != null) {
          startTracking(mydata, true, true, (n) {});
        }
      }
    } catch (e, st) {
      log("❌ Error checking background service: $e\n$st");
    }
  }

  /// 🧩 Background mode enable
  static Future<void> enableBackgroundMode() async {
    bool enabled = await _location.isBackgroundModeEnabled();
    if (!enabled) {
      enabled = await _location.enableBackgroundMode(enable: true);
    }
    print("🟢 Background mode: $enabled");
  }
}
