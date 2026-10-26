import 'dart:async';
import 'dart:developer';
import 'dart:ui';
import 'package:aqi_app/configs/navigationservices.dart';
import 'package:aqi_app/configs/router.dart';
import 'package:aqi_app/constants/key_constant.dart';
import 'package:aqi_app/data/local/HiveLDB/HiveModel/AQIBulkDataHistory.dart';
import 'package:aqi_app/data/local/HiveLDB/HiveModel/AQiDetailHistory.dart';
import 'package:aqi_app/data/local/HiveLDB/HiveModel/CurrentRideRoute.dart';
import 'package:aqi_app/data/local/HiveLDB/Hive_DataRetival.dart';
import 'package:aqi_app/data/models/aqi_responses.dart';
import 'package:aqi_app/data/repository/MapScreen_repositry/MapScreen_repositary.dart';
import 'package:aqi_app/presentation/screens/home_page/widgets/Runningridedialog.dart';
import 'package:aqi_app/presentation/screens/location_screen/direction_Aqi_Screen.dart';
import 'package:aqi_app/utils/Background_services/Background_services_mtd.dart';
import 'package:aqi_app/utils/toast.dart';
import 'package:flutter/material.dart';
import 'package:geodesy/geodesy.dart' as gd;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart' as loca;

class HomeRepository {
  final Dio _dio = Dio();
  final box = Hive.box<AQIDetailHistory>('aqi_detail_history');
  var currentloc;
  var homeResponse;
  AqiResponse? aqidata;
  bool travelswitch = false;

 Future<bool> checkAndRequestLocationPermission() async {
  try {
    // Step 1: Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      log("Location services are disabled. Prompting user to enable...");
      await Geolocator.openLocationSettings();
      // Re-check after opening settings
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
    }

    // Step 2: Check permission using Geolocator
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      log("Location permission denied or deniedForever.");
      await openAppSettings(); // opens app settings on iOS
      return false;
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return true;
    }

    return false;
  } catch (e, stacktrace) {
    log("Error checking/requesting location permission: $e");
    log(stacktrace.toString());
    return false;
  }
}

  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions are permanently denied.");
    }
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        throw Exception("Location permission denied.");
      }
    }

    log("📍 Trying Geolocator first...");
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
    } catch (e) {
      log("⚠️ Geolocator failed: $e");
      log("👉 Falling back to Location plugin...");

      try {
        final location = loca.Location();

        // Ensure service enabled
        bool serviceEnabled = await location.serviceEnabled();
        if (!serviceEnabled) {
          serviceEnabled = await location.requestService();
          if (!serviceEnabled) {
            throw Exception(
              "Location services are disabled (Location plugin).",
            );
          }
        }

        // Check permission
        var permissionGranted = await location.hasPermission();
        if (permissionGranted == loca.PermissionStatus.denied) {
          permissionGranted = await location.requestPermission();
          if (permissionGranted != loca.PermissionStatus.granted &&
              permissionGranted != loca.PermissionStatus.grantedLimited) {
            throw Exception("Location permission denied (Location plugin).");
          }
        }

        // Get current location
        final e = await location.getLocation();
        currentloc = Position(
          longitude: e.longitude ?? 0.0,
          latitude: e.latitude ?? 0.0,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            e.time?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
          ),
          accuracy: e.accuracy ?? 0.0,
          altitude: e.altitude ?? 0.0,
          heading: e.heading ?? 0.0,
          speed: e.speed ?? 0.0,
          speedAccuracy: e.speedAccuracy ?? 0.0,
          altitudeAccuracy: e.speedAccuracy ?? 0.0,
          headingAccuracy: e.speedAccuracy ?? 0.0,
        );
        return currentloc;
      } catch (fallbackError) {
        log("❌ Both Geolocator & Location failed: $fallbackError");
        return null;
      }
    }
  }

  /// Get readable address from coordinates
  Future<String> getAddressFromLatLng(Position position) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    log("placemark: ${placemarks.toString().trim().replaceAll(" ", "")}");
    if (placemarks.isEmpty) return "Unknown Location";
    return formatBestAddress(placemarks);
  }

  String formatBestAddress(List<Placemark> placemarks) {
    if (placemarks.isEmpty) return "Unknown Location";

    // Filter out invalid street names (like plus codes: "PV85+FW6")
    List<Placemark> validPlacemarks =
        placemarks.where((p) {
          final street = p.street ?? '';
          return street.isNotEmpty && !_isInvalidStreet(street);
        }).toList();

    // If nothing valid, fall back to all placemarks
    final listToCheck =
        validPlacemarks.isNotEmpty ? validPlacemarks : placemarks;

    // Pick the placemark with the most complete info
    Placemark bestPlacemark = listToCheck.reduce((a, b) {
      int aScore = _placemarkScore(a);
      int bScore = _placemarkScore(b);
      return bScore > aScore ? b : a;
    });

    // Safely get details
    String street = bestPlacemark.street?.trim() ?? '';
    String subLocality = bestPlacemark.subLocality?.trim() ?? '';
    String locality = bestPlacemark.locality?.trim() ?? '';
    String country = bestPlacemark.country?.trim() ?? '';

    // Build clean address
    List<String> parts = [];
    if (street.isNotEmpty) parts.add(street);
    if (subLocality.isNotEmpty) parts.add(subLocality);
    if (locality.isNotEmpty) parts.add(locality);
    if (country.isNotEmpty) parts.add(country);

    return parts.isNotEmpty ? parts.join(", ") : "Unknown Location";
  }

  // Exclude plus codes or junk-like streets
  bool _isInvalidStreet(String street) {
    // Plus codes are usually alphanumeric with +, like "PV85+FW6"
    final plusCodePattern = RegExp(r'^[A-Z0-9\+]{4,}$');
    // Reject if matches plus code style or has no letters at all
    return plusCodePattern.hasMatch(street) ||
        !RegExp(r'[a-zA-Z]').hasMatch(street);
  }

  // Score function for choosing most complete placemark
  int _placemarkScore(Placemark p) {
    int score = 0;
    if (p.street?.isNotEmpty == true && !_isInvalidStreet(p.street!))
      score += 3;
    if (p.subLocality?.isNotEmpty == true) score += 2;
    if (p.locality?.isNotEmpty == true) score += 2;
    if (p.country?.isNotEmpty == true) score += 1;
    return score;
  }

  Future<AQIDetailHistory?> getNCheckOldDataAqi(
    LatLng myLatlng,
    DateTime cDateTime,
  ) async {
    final matchingEntries =
        box.values.where((entry) {
          final entryDate = DateTime.parse(entry.debugSyncTime);
          return entryDate.year == cDateTime.year &&
              entryDate.month == cDateTime.month &&
              entryDate.day == cDateTime.day;
        }).toList();
    if (matchingEntries.isNotEmpty) {
      for (var item in matchingEntries) {
        log("items of the day: ${item.debugSyncTime}");
        final itemLatLng = gd.LatLng(item.inputlatlng[0], item.inputlatlng[1]);
        final targetLatLng = gd.LatLng(myLatlng.latitude, myLatlng.longitude);

        final distance = gd.Geodesy().distanceBetweenTwoGeoPoints(
          itemLatLng,
          targetLatLng,
        );
        final itemTime = DateTime.parse(item.debugSyncTime);
        final timeDifference = cDateTime.difference(itemTime).inMinutes.abs();
        log("time difference: $timeDifference $distance");
        if (distance <= 3000.0 && timeDifference <= 30) {
          return item;
        }
      }
    } else {
      print("No AQI entries found for date ${cDateTime.toIso8601String()}");
    }
    return null;
  }

  /// Call AQI API using Dio
  Future<AQIDetailHistory> fetchAqiByLocation({
    required double lat,
    required double lng,
  }) async {
    var data = await getNCheckOldDataAqi(LatLng(lat, lng), DateTime.now());
    if (data != null) return data;
    const String apiKey = Constantkey.AQI_WAQI_TOKEN;
    final String url =
        "https://api.waqi.info/feed/geo:$lat;$lng/?token=$apiKey";

    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data['status'] == 'ok') {
        await DataReterival.addToLocalDataDB(
          response.data['data'],
          LatLng(lat, lng),
        );
        return fetchAqiByLocation(lat: lat, lng: lng);
        // return response.data['data'];
      } else {
        throw Exception("Failed to fetch AQI data.");
      }
    } catch (e) {
      throw Exception("AQI API Error: $e");
    }
  }

  /// Call AQI API using Dio via Google Api
  Future<Map<String, dynamic>> fetchAqiByLocationViaGoogle({
    required double lat,
    required double lng,
  }) async {
    Aqibulkdatahistory? fetchlocaldata =
        await DataReterival.getNCheckOldAqiDataforGoogle(LatLng(lat, lng));
    if (fetchlocaldata != null) {
      final data = fetchlocaldata.aqidetailjsondata;
      log("Repo row data: $data");
      if (data['indexes'] != null && data['indexes'].isNotEmpty) {
        // addAqiDataToLocalHiveDataDB(data, LatLng(lat, lng));
        return {
          'aqi': data['indexes'][0]['aqi'],
          'color': data['indexes'][0]['color'],
          'category': data['indexes'][0]['category'],
          'dominantPollutant': data['indexes'][0]['dominantPollutant'],
          'pollutants': data['pollutants'],
          'healthRecommendations': data['healthRecommendations'],
        };
      } else {
        throw Exception("AQI data is empty or malformed.");
      }
    } else {
      const String apiKey =
          Constantkey.GOOGLE_MAP_API_KEY; // Replace with your key
      final String url =
          "https://airquality.googleapis.com/v1/currentConditions:lookup?key=$apiKey";

      try {
        final response = await _dio.post(
          url,
          data: {
            "universalAqi": true,
            "location": {"latitude": lat, "longitude": lng},
            "extraComputations": [
              "HEALTH_RECOMMENDATIONS",
              "DOMINANT_POLLUTANT_CONCENTRATION",
              "POLLUTANT_CONCENTRATION",
              // "LOCAL_AQI",
              // "POLLUTANT_ADDITIONAL_INFO",
            ],
            "languageCode": "en",
          },
          options: Options(headers: {'Content-Type': 'application/json'}),
        );

        if (response.statusCode == 200) {
          final data = response.data;
          log("Repo row data: $data");
          if (data['indexes'] != null && data['indexes'].isNotEmpty) {
            DataReterival.addAqiDataToLocalHiveDataDB(data, LatLng(lat, lng));
            return {
              'aqi': data['indexes'][0]['aqi'],
              'color': data['indexes'][0]['color'],
              'category': data['indexes'][0]['category'],
              'dominantPollutant': data['indexes'][0]['dominantPollutant'],
              'pollutants': data['pollutants'],
              'healthRecommendations': data['healthRecommendations'],
            };
          } else {
            throw Exception("AQI data is empty or malformed.");
          }
        } else {
          throw Exception(
            "Google AQI API returned error: ${response.statusCode}",
          );
        }
      } catch (e) {
        throw Exception("Google AQI API Error: $e");
      }
    }
  }

  Future<void> showRunningRideDialog({
    required CurrentRideRoute route,
    required VoidCallback onShowMap,
    required cposition,
    required VoidCallback onCancelTracking,
  }) {
    log("my dialog data" + route.routeDetail.toString());
    final context = NavigationService.navigatorKey.currentContext!;
    final theme = Theme.of(context);
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: GlassCard(
            child: RideContent(
              route: route,
              cLatLng: cposition,
              onShowMap: () {
                Navigator.pushNamed(
                  context,
                  AppRouter.GOOGLE_MAP_PAGE,
                  arguments: GetRouteScreen(
                    cposition: cposition,
                    initfilter: travelswitch ? 2 : 0,
                    fromwhere: 1,
                    tMode: TransportMode.Driving,
                    rawrunnigndata: route,
                  ),
                );
                // UtilToast.showMessageForUser(context, "Coming Soon!!!!");
                // DataReterival.deleteCurrentRide();
                AppLocationService.stopTracking();
              },
              onCancelTracking: () {
                // UtilToast.showMessageForUser(context, "Coming Soon!!!!");
                DataReterival.deleteCurrentRide();
                AppLocationService.stopTracking();
              },
            ),
          ),
        );
      },
    );
  }
}
