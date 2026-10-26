import 'dart:convert';
import 'dart:developer';

import 'package:aqi_app/configs/navigationservices.dart';
import 'package:aqi_app/configs/network.dart';
import 'package:aqi_app/constants/key_constant.dart';
import 'package:aqi_app/data/local/HiveLDB/HiveModel/AQIBulkDataHistory.dart';
import 'package:aqi_app/data/models/Directional_model.dart';
import 'package:aqi_app/data/models/aqi_responses.dart';
import 'package:aqi_app/data/repository/MapScreen_repositry/aqi_channel.dart';
import 'package:aqi_app/data/request/api_url.dart';
import 'package:aqi_app/utils/Aqi_calculator.dart';
import 'package:aqi_app/utils/dialog.dart';
import 'package:aqi_app/utils/geo_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:uuid/uuid.dart';

import '../local/HiveLDB/Hive_DataRetival.dart';
import '../models/route_overviewdetail.dart';

class AllAPIRequest {
  ///------------------------------------
  /// Fetch Direction Google API between points
  /// -----------------------------------
  // Request _requests = Request();
  static Future<DirectionResult> fetchDirectionByLocation({
    required LatLng origin,
    required LatLng destination,
    String mode = "driving",
    String? departureTime, // e.g., "now" or timestamp
    String trafficModel = "best_guess",
    bool alternatives = true,
    String? waypoints, // e.g., "via:lat,lng|lat,lng"
    String? avoid, // e.g., "tolls|highways|ferries"
    String? language,
    String? region,
  }) async {
    const String apiKey = Constantkey.GOOGLE_MAP_API_KEY;
    try {
      log(
        "Fetching direction: mode=$mode, origin=$origin, destination=$destination",
      );

      // Check if cached data exists
      final recentDirectionDetail =
          await DataReterival.getNCheckOldDataDirection(origin, destination);
      Response response;
      if (recentDirectionDetail == null) {
        final queryParams = {
          "origin": "${origin.latitude},${origin.longitude}",
          "destination": "${destination.latitude},${destination.longitude}",
          "mode": (mode == "bicycling") ? "driving" : mode, // fallback logic
          "alternatives": alternatives.toString(),
          "departure_time": departureTime ?? "now",
          "traffic_model": trafficModel,
          "key": apiKey,
          if (waypoints != null) "waypoints": waypoints,
          if (avoid != null) "avoid": avoid,
          if (language != null) "language": language,
          if (region != null) "region": region,
        };
        if (!await Network.isConnected()) {
          return await fetchDirectionByLocation(
            origin: origin,
            destination: destination,
            mode: mode,
            alternatives: true,
            waypoints: (waypoints != null) ? waypoints : '',
            departureTime: 'now',
          );
        }

        response = await Dio().get(
          AllApi.BASE_URL_DIRECTION,
          queryParameters: queryParams,
        );
      } else {
        response = Response(
          requestOptions: RequestOptions(path: ''),
          data: recentDirectionDetail.directionjsondata,
          statusCode: 200,
        );
      }
      if (response.statusCode != 200 || response.data['status'] != 'OK') {
        throw Exception(
          "Failed to fetch directions: ${response.data['status']}",
        );
      }

      // Save new response if not cached
      final suid = recentDirectionDetail?.uid ?? Uuid().v4();
      if (recentDirectionDetail == null) {
        DataReterival.addDirectionToLocalDataDB(
          response.data,
          origin,
          destination,
          suid,
        );
      }
      log("data from api : " + response.toString());
      // Parse routes
      final List<List<LatLng>> allRoutes = [];
      final List<RouteOverview> overviewDetails = [];
      for (var route in response.data['routes']) {
        final polyline = GeoUtils().decodePolyline(
          route['overview_polyline']['points'],
        );
        allRoutes.add(polyline);

        final leg = combineRouteLegs(route);

        // final durationTraffic =
        //     leg["duration_in_traffic"]?['value'] ?? leg["duration"]['value'];
        overviewDetails.add(RouteOverview.fromLeg(leg));
      }

      return DirectionResult(
        uid: suid,
        directionData: response.data,
        polylineAllRoutes: allRoutes,
        filterData: overviewDetails,
      );
      // {
      //       "uid": suid,
      //       "direction_data": response.data,
      //       "polyline_allroutes": allRoutes,
      //       "filter_data": overviewDetails,
      //     };
    } catch (e, stack) {
      log("Direction API Error: $e\n$stack");
      throw Exception("Direction API Error: $e");
    }
  }

  /// Combine all legs of a Google Directions route into one map.
  static Map<String, dynamic> combineRouteLegs(Map<String, dynamic> route) {
    final legs = (route['legs'] as List).cast<Map<String, dynamic>>();
    if (legs.isEmpty) return {};

    int totalDistance = 0;
    int totalDuration = 0;
    final allSteps = <dynamic>[];

    for (final leg in legs) {
      totalDistance += (leg['distance']['value'] as num).toInt();
      totalDuration += (leg['duration']['value'] as num).toInt();
      allSteps.addAll(leg['steps'] as List);
    }

    final first = legs.first;
    final last = legs.last;

    return {
      // keep start details from first leg
      "start_address": first['start_address'],
      "start_location": first['start_location'],

      // update end details from last leg
      "end_address": last['end_address'],
      "end_location": last['end_location'],

      // summed totals
      "distance": {
        "value": totalDistance,
        "text": "${(totalDistance / 1000).toStringAsFixed(1)} km",
      },
      "duration": {
        "value": totalDuration,
        "text": "${(totalDuration / 60).round()} mins",
      },

      // merged steps list
      "steps": allSteps,

      // optional: merge these if present
      "traffic_speed_entry":
          legs
              .expand((l) => (l['traffic_speed_entry'] as List?) ?? [])
              .toList(),
      "via_waypoint":
          legs.expand((l) => (l['via_waypoint'] as List?) ?? []).toList(),
    };
  }

  ///------------------------------------
  /// Fetch AQI From LatLng Via Google
  /// -----------------------------------
  /// Call AQI API using Dio via Google API
  static Future<AqiResponse> fetchAqiByLocationViaGoogle({
    required double lat,
    required double lng,
    bool detailedResponse = true, // 👈 added parameter
  }) async {
    // await DataReterival.cleanAqiBox();
    // Step 1: Try fetching from local Hive storage

    Aqibulkdatahistory? fetchlocaldata =
        await DataReterival.getNCheckOldAqiDataforGoogle(LatLng(lat, lng));

    if (fetchlocaldata != null) {
      final data = fetchlocaldata.aqidetailjsondata;

      if (data['indexes'] != null && data['indexes'].isNotEmpty) {
        final indexData = data['indexes'][0];

        int calcaqivalue = 0;

        try {
          print("My Cache Datta1:   " + data['pollutants'].toString());

          final List<Pollutant> pollutantList = Pollutant.fromList(
            data['pollutants'],
          );

          final int finalAqi = AqiCalculator.calculateOverallCpcbAqi(
            pollutantList,
          );
          calcaqivalue = finalAqi;
        } catch (e) {
          print('Error calculating AQI1: $e');
        }

        //calculateAQI(data['pollutants']);
        final previewvalue = AqiCalculator.smartAqichoose(
          calcAqi: calcaqivalue,
          waqiAqi: data['waqi'],
          universalAqi: indexData['aqi'],
        );
        var healthrecom = await AQIChannel().getfullRecommendationsForAQI(
          previewvalue,
        );
        return AqiResponse(
          aqi: previewvalue,
          previewaqi: indexData['aqi'],
          waqi: data['waqi'],
          color: AqiColor.fromJson(indexData['color']).toFlutterColor(),
          category:
              previewvalue != indexData['aqi']
                  ? "Air Quality is " + healthrecom['category']
                  : indexData['category'],
          dominantPollutant:
              detailedResponse ? indexData['dominantPollutant'] : null,
          pollutants: detailedResponse ? data['pollutants'] : null,
          healthRecommendations:
              detailedResponse ? data['healthRecommendations']! : null,
          forcast: data["myforcast"] ?? [],
          customCategory: "Air Quality is " + healthrecom['category'],
          customhealthRecommendations: healthrecom['recommendations'],
        );
      } else {
        var calcaqibyp;
        try {
          // 1. Decode the JSON string into a list of Pollutant objects
          final List<Pollutant> pollutantList = Pollutant.fromList(
            fetchlocaldata.aqidetailjsondata['pollutants'],
          );

          // 2. Calculate the final AQI
          final int finalAqi = AqiCalculator.calculateOverallCpcbAqi(
            pollutantList,
          );
          calcaqibyp = finalAqi;
          print('The calculated CPCB AQI is: $finalAqi'); // Output will be 401
        } catch (e) {
          print('Error calculating AQI2: $e');
        }
        //calculateAQI(data['pollutants']);
        final previewvalue = AqiCalculator.smartAqichoose(
          calcAqi: calcaqibyp,
          waqiAqi: data['waqi'],
          universalAqi: data['aqi'],
        );

        var healthrecom = await AQIChannel().getfullRecommendationsForAQI(
          previewvalue,
        );
        return AqiResponse(
          aqi: previewvalue,
          previewaqi: data['aqi'],
          waqi: data['waqi'],
          color:
              AqiColor.fromJson(getColorForAqi(data['aqi'])).toFlutterColor(),
          category: data['extand_data']['category'],
          dominantPollutant: detailedResponse ? data['dominentpol'] : null,
          pollutants: detailedResponse ? data['forecast'] : null,
          healthRecommendations:
              detailedResponse ? data['extand_data']['recommendations'] : null,
          customCategory: "Air Quality is " + healthrecom['category'],
          customhealthRecommendations: healthrecom['recommendations'],
        );
        // throw Exception("AQI local data is empty or malformed.");
      }
    } else {
      // Step 2: Fetch from API if not available in local DB
      const String apiKey = Constantkey.GOOGLE_MAP_API_KEY;
      final String url =
          "https://airquality.googleapis.com/v1/currentConditions:lookup?key=$apiKey";

      try {
        // Prepare request payload dynamically
        final Map<String, dynamic> requestData = {
          "universalAqi": true,
          "location": {"latitude": lat, "longitude": lng},
          "languageCode": "en",
          "customLocalAqis": [
            {"regionCode": "IN", "aqi": "ind_cpcb"},
          ],
        };
        if (detailedResponse) {
          requestData["extraComputations"] = [
            "HEALTH_RECOMMENDATIONS",
            "DOMINANT_POLLUTANT_CONCENTRATION",
            "POLLUTANT_CONCENTRATION",
          ];
        }

        if (await Network.isConnected()) {
          final response = await Dio().post(
            url,
            data: requestData,
            options: Options(headers: {'Content-Type': 'application/json'}),
          );
          if (response.statusCode == 200) {
            final data = response.data;

            if (data['indexes'] != null && data['indexes'].isNotEmpty) {
              final indexData = data['indexes'][0];
              var calcaqibyp;
              try {
                // 1. Decode the JSON string into a list of Pollutant objects
                print("My Cache Datta3:   " + data['pollutants'].toString());
                final List<Pollutant> pollutantList = pollutantFromList(
                  data['pollutants'],
                );

                // 2. Calculate the final AQI
                final int finalAqi = AqiCalculator.calculateOverallCpcbAqi(
                  pollutantList,
                );
                calcaqibyp = finalAqi;
                print(
                  '${data['pollutants']} The calculated CPCB AQI is:  $finalAqi',
                ); // Output will be 401
              } catch (e) {
                print('Error calculating AQI3: $e');
              }

              //calculateAQI(data['pollutants']);
              var forcastdata = await fetchAqiByLocation(lat: lat, lng: lng);
              final previewvalue = AqiCalculator.smartAqichoose(
                calcAqi: calcaqibyp,
                waqiAqi: forcastdata['aqi'],
                universalAqi: indexData['aqi'],
              );
              log("my final Aqi response : $data");
              var healthrecom = await AQIChannel().getfullRecommendationsForAQI(
                previewvalue,
              );
              data['previewaqi'] = previewvalue;
              data['waqi'] = forcastdata['aqi'];
              data["myforcast"] = forcastdata['forecast']['daily'];
              data[""] = "Air Quality is " + healthrecom['category'];
              data["customhealthRecommendations"] =
                  healthrecom['recommendations'];
              // Save into local Hive DB

              DataReterival.addAqiDataToLocalHiveDataDB(data, LatLng(lat, lng));
              return AqiResponse(
                aqi: previewvalue,
                previewaqi: indexData['aqi'],
                waqi: forcastdata['aqi'],
                color: AqiColor.fromJson(indexData['color']).toFlutterColor(),
                category: indexData['category'],
                dominantPollutant:
                    detailedResponse ? indexData['dominantPollutant'] : null,
                pollutants: detailedResponse ? data['pollutants'] : null,
                healthRecommendations:
                    detailedResponse ? data['healthRecommendations'] : null,
                forcast: data['myforcast'],
                customCategory: "Air Quality is " + healthrecom['category'],
                customhealthRecommendations: healthrecom['recommendations'],
              );
            } else {
              throw Exception("AQI API data is empty or malformed.");
            }
          } else {
            throw Exception(
              "Google AQI API returned error: ${response.statusCode}",
            );
          }
        } else {
          UtilDialog.showRetry(
            title: "No Internet Connection ?",
            content:
                "NO Internet Connection found. Please Connect with internet",
            onClose: () async {
              Navigator.pop(NavigationService.navigatorKey.currentContext!);
            },
          );
        }
        throw Exception("SomeThing went wrong: ");
      } catch (e) {
        throw Exception("Google AQI API Error: $e");
      }
    }
  }

  static Future<Map<String, dynamic>> fetchAqiByLocation({
    required double lat,
    required double lng,
  }) async {
    const String apiKey = Constantkey.AQI_WAQI_TOKEN;
    final String url =
        "https://api.waqi.info/feed/geo:$lat;$lng/?token=$apiKey";

    try {
      final Dio _dio = Dio();
      log("called");
      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data['status'] == 'ok') {
        log("mydata res: ${response.data}");
        return response.data['data'];
      } else {
        throw Exception("Failed to fetch AQI data.");
      }
    } catch (e) {
      throw Exception("AQI API Error: $e");
    }
  }

  static Map getColorForAqi(int aqi) {
    if (aqi <= 50) {
      return {'red': 0, 'green': 228, 'blue': 0}; // Green
    } else if (aqi <= 100) {
      return {'red': 255, 'green': 255, 'blue': 0}; // Yellow
    } else if (aqi <= 200) {
      return {'red': 255, 'green': 126, 'blue': 0}; // Orange
    } else if (aqi <= 300) {
      return {'red': 255, 'green': 0, 'blue': 0}; // Red
    } else if (aqi <= 400) {
      return {'red': 143, 'green': 63, 'blue': 151}; // Purple
    } else {
      return {'red': 126, 'green': 0, 'blue': 35}; // Maroon
    }
  }
}
