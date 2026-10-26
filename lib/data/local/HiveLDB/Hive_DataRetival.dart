import 'dart:developer';

import 'package:aqi_app/constants/key_constant.dart';
import 'package:aqi_app/data/local/HiveLDB/HiveModel/AQIBulkDataHistory.dart';
import 'package:aqi_app/data/local/HiveLDB/HiveModel/AQiDetailHistory.dart';
import 'package:aqi_app/data/local/HiveLDB/HiveModel/CurrentRideRoute.dart';
import 'package:aqi_app/data/local/HiveLDB/HiveModel/LoadSearchHistory.dart';
import 'package:aqi_app/data/local/pref.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'HiveModel/MainNavigationHistory.dart';

class DataReterival {
  final aqibox = Hive.box<Aqibulkdatahistory>('aqi_bulk_history');

  /// -------------------------------------------
  /// Get and Check weather direction polyline isSaved or not->model Loadsearchhistory
  /// -------------------------------------------
  static Future getNCheckOldDataDirection(
    LatLng csLatlng,
    LatLng celatlng,
  ) async {
    try {
      final directionbox = Hive.box<Loadsearchhistory>('direction_api_history');
      final now = DateTime.now();
      final dateKey =
          "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${DateFormat('hh').format(now)}";
      String generateKey(LatLng start, LatLng end) {
        String sLat = start.latitude.toStringAsFixed(5);
        String sLng = start.longitude.toStringAsFixed(5);
        String eLat = end.latitude.toStringAsFixed(5);
        String eLng = end.longitude.toStringAsFixed(5);
        return "direction_${sLat}_${sLng}_${eLat}_${eLng}_$dateKey";
      }

      // for direction key expire in hour
      final key = generateKey(csLatlng, celatlng);
      if (directionbox.containsKey(key)) {
        return directionbox.get(key);
      } else {
        log("No direction data found for key: $key");
        return null;
      }
    } catch (e) {
      log("Error in getNCheckOldDataDirection: $e");
      return null;
    }
  }

  ///-----------------------------------
  ///Save A Google Direction Detail on local Database
  ///-----------------------------------
  static void addDirectionToLocalDataDB(
    Map<String, dynamic> data,
    LatLng clatlng,
    LatLng dlatlng,
    suid,
  ) async {
    try {
      final now = DateTime.now();
      final hour = DateFormat('hh').format(now);
      final dateKey =
          "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}$hour";
      String generateKey(LatLng start, LatLng end) {
        String sLat = start.latitude.toStringAsFixed(5);
        String sLng = start.longitude.toStringAsFixed(5);
        String eLat = end.latitude.toStringAsFixed(5);
        String eLng = end.longitude.toStringAsFixed(5);
        return "direction_${sLat}_${sLng}_${eLat}_${eLng}_$dateKey";
      }

      final key = generateKey(clatlng, dlatlng);
      Loadsearchhistory entry = Loadsearchhistory(
        directionjsondata: data,
        uid: suid,
        startlatlng: [clatlng.latitude, clatlng.longitude],
        endlatlng: [dlatlng.latitude, dlatlng.longitude],
        synctime: DateTime.now(),
      );
      final directionbox = Hive.box<Loadsearchhistory>('direction_api_history');
      await directionbox.put(key, entry);
      log("✅ Direction data added to local Hive DB");
    } catch (e, st) {
      log("❌ Error adding to local DB: $e");
      log("📌 StackTrace: $st");
    }
  }

  ///-----------------------------------
  ///Save A Google Direction Detail on local Database
  ///-----------------------------------

  static Future<void> addNavigationHistoryToLocalDataDB(
    MainNavigationHistory data,
    String suid,
  ) async {
    try {
      final directionBox = Hive.box<MainNavigationHistory>('navigationHistory');
      if (directionBox.containsKey(suid)) {
        log("⚠️ Record with suid: $suid already exists in local Hive DB");
      } else {
        await directionBox.put(suid, data);
        log("✅ Direction Main data added to local Hive DB with key: $suid");
      }
    } catch (e, st) {
      log("❌ Error adding to local DB: $e");
      log("📌 StackTrace: $st");
    }
  }

  /// Get last `n` records
  static List<MainNavigationHistory> getNavLastNRecords(int n) {
    final box = Hive.box<MainNavigationHistory>('navigationHistory');
    final all = box.values.toList();
    if (all.length <= n) return all;
    return all.sublist(all.length - n);
  }

  /// Get first `n` records
  // List<MainNavigationHistory> getFirstNRecords(int n) {
  //   final box = Hive.box<MainNavigationHistory>('navigationHistory');
  //   if (all.length <= n) return all;
  //   return all.sublist(0, n);
  // }

  /// Get all records
  static List<MainNavigationHistory> getNavAllRecords() {
    final box = Hive.box<MainNavigationHistory>('navigationHistory');
    return box.values.toList();
  }

  ///-----------------------------------------------
  ///=====SAVED AND RETRIVE AQI DATA================
  /// ----------------------------------------------

  static void addAqiDataToLocalHiveDataDB(data, LatLng clatlng) {
    final aqibox = Hive.box<Aqibulkdatahistory>('aqi_bulk_history');
    final box = aqibox;
    // Round lat/lng to ~1 km precision (2 decimals)
    final newLat = (clatlng.latitude * 1000).round() / 1000;
    final newLng = (clatlng.longitude * 1000).round() / 1000;

    // Current time
    final now = DateTime.now();

    // Only date part
    final onlyDate = DateFormat("dd/MM/yyyy").format(now);

    // Hour (24h format to avoid AM/PM confusion)
    final hour = DateFormat('HH').format(now);

    // Calculate which 10-minute bucket we’re in
    final minuteBucket = (now.minute ~/ 10) * 10; // e.g., 0, 10, 20, 30, 40, 50

    // Final key
    final key = "$newLat,${newLng}_${onlyDate}_$hour:$minuteBucket";

    if (!box.containsKey(key)) {
      try {
        final intiid = Uuid().v7();
        Aqibulkdatahistory entry = Aqibulkdatahistory(
          aqidetailjsondata: data,
          uid: intiid,
          apiType: 0,
          synctime: DateTime.now(),
          direction_uid: "initial_$intiid",
          pointlatlng: [clatlng.latitude, clatlng.longitude],
        );
        box.put(key, entry);
        log("✅ AQI data added to local Hive DB");
      } catch (e, st) {
        log("❌ Error adding to local DB: $e");
        log("📌 StackTrace: $st");
      }
    }
  }

  static cleanAqiBox(box) async {
    await box.clear();
  }

  static Future getNCheckOldAqiDataforGoogle(latlng) async {
    try {
      final aqibox = Hive.box<Aqibulkdatahistory>('aqi_bulk_history');
      // cleanAqiBox(aqibox);
      final String? lastFetch = LocalPref.getString(SavedKey.LASTCLEANDATABASE);
      final curenttime = DateTime.now();
      if (lastFetch != null) {
        final lastDate = DateTime.tryParse(lastFetch);
        if (lastDate != null && curenttime.difference(lastDate).inDays > 2) {
          cleanAqiBox(aqibox);
          LocalPref.setString(
            SavedKey.LASTCLEANDATABASE,
            curenttime.toString(),
          );
        }
      } else {
        log("Local DB");
        LocalPref.setString(SavedKey.LASTCLEANDATABASE, curenttime.toString());
      }
      // Round lat/lng to ~1 km precision (2 decimals)
      final newLat = (latlng.latitude * 1000).round() / 1000;
      final newLng = (latlng.longitude * 1000).round() / 1000;

      // Current time
      final now = DateTime.now();

      // Only date part
      final onlyDate = DateFormat("dd/MM/yyyy").format(now);

      // Hour (24h format to avoid AM/PM confusion)
      final hour = DateFormat('HH').format(now);
      // Calculate which 10-minute bucket we’re in
      final minuteBucket =
          (now.minute ~/ 10) * 10; // e.g., 0, 10, 20, 30, 40, 50
      // Final key
      final key = "$newLat,${newLng}_${onlyDate}_$hour:$minuteBucket";
      log("myKey to fetch: $key");
      if (aqibox.containsKey(key)) {
        log("yes contain");
        return aqibox.get(key);
      } else {
        log("No direction data found for key: $key");
        return null;
      }
    } catch (e) {
      log("Error in getNCheckOldDataDirection: $e");
      return null;
    }
  }

  static Future<void> addToLocalDataDB(
    Map<String, dynamic> data,
    LatLng clatlng,
  ) async {
    try {
      log("🌍 Adding AQI data: $data");
      // Parse attributions
      List<Attribution> attributions =
          (data['attributions'] as List)
              .map(
                (e) => Attribution(
                  url: e['url'],
                  name: e['name'],
                  logo: e['logo'],
                ),
              )
              .toList();

      // Parse city
      var cityMap = data['city'];
      AQICity city = AQICity(
        geo: List<double>.from(cityMap['geo']),
        name: cityMap['name'],
        url: cityMap['url'],
        location: cityMap['location'] ?? '',
      );

      // Parse iaqi
      Map<String, dynamic> iaqiRaw = data['iaqi'];
      Map<String, double> iaqiValues = {};
      iaqiRaw.forEach((key, value) {
        iaqiValues[key] = (value['v'] as num).toDouble();
      });
      IAQI iaqi = IAQI(values: iaqiValues);

      // Parse time
      var timeMap = data['time'];
      AQITime time = AQITime(
        s: timeMap['s'],
        tz: timeMap['tz'],
        v: timeMap['v'],
        iso: timeMap['iso'],
      );

      // Parse forecast
      var forecastRaw = data['forecast']['daily'];
      List<DailyForecast> parseDaily(List<dynamic> list) =>
          list
              .map(
                (e) => DailyForecast(
                  avg: e['avg'],
                  day: e['day'],
                  max: e['max'],
                  min: e['min'],
                ),
              )
              .toList();

      Forecast forecast = Forecast(
        pm10: parseDaily(forecastRaw['pm10']),
        pm25: parseDaily(forecastRaw['pm25']),
        uvi: parseDaily(forecastRaw['uvi']),
      );

      // Create final model
      final AQIDetailHistory entry = AQIDetailHistory(
        aqi: data['aqi'],
        idx: data['idx'],
        attributions: attributions,
        city: city,
        dominentpol: data['dominentpol'],
        iaqi: iaqi,
        time: time,
        forecast: forecast,
        debugSyncTime: DateTime.now().toIso8601String(),
        inputlatlng: [clatlng.latitude, clatlng.longitude],
      );

      final box = Hive.box<AQIDetailHistory>('aqi_detail_history');
      await box.add(entry);
      log("✅ AQI data added to local Hive DB");
    } catch (e, st) {
      log("❌ Error adding to local DB: $e");
      log("📌 StackTrace: $st");
    }
  }

  ///----------------------------------------
  ///=====CURRENT RIDE DATABASE==============
  ///----------------------------------------
  static Future<void> addCurrentRideToLocaldb(
    CurrentRideRoute curentdata,
  ) async {
    // Open box
    var box = await Hive.openBox<CurrentRideRoute>('rideRoutes');
    if (!box.containsKey("currentRide")) {
      // Save route
      await box.put("currentRide", curentdata);
    }
    // // Fetch routes
    // List<RideRoute> routes = box.values.toList();
  }

  static Future<void> updateCenter(LatLngPoint newCenter) async {
    var box = await Hive.openBox<CurrentRideRoute>('rideRoutes');

    if (box.containsKey("currentRide")) {
      CurrentRideRoute? ride = box.get("currentRide");
      if (ride != null) {
        ride.currentpont = newCenter; // update field
        await box.put("currentRide", ride); // overwrite with updated object
      }
    }
  }

  static Future<CurrentRideRoute?> getcurrentRide() async {
    var box = await Hive.openBox<CurrentRideRoute>('rideRoutes');
    final ride = box.get("currentRide");
    if (ride != null) {
      return ride;
    } else {
      return null;
    }
  }

  static Future<void> deleteCurrentRide() async {
    try {
      if (!Hive.isBoxOpen('rideRoutes')) {
        await Hive.openBox<CurrentRideRoute>('rideRoutes');
      }
      var box = Hive.box<CurrentRideRoute>('rideRoutes');

      if (box.containsKey("currentRide")) {
        await box.delete("currentRide");
        log("✅ Current ride deleted.");
      } else {
        log("ℹ️ No current ride found to delete.");
      }
    } catch (e, st) {
      log("❌ Error deleting current ride: $e");
      debugPrintStack(stackTrace: st);
    }
  }
}
