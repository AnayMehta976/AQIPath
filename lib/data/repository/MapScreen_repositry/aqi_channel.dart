import 'package:aqi_app/constants/key_constant.dart';

import 'package:dio/dio.dart';

import '../../models/comman_aqi_model.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class AQIChannel {
  final Dio _dio = Dio();

  Future<CommanDetailAqiModel> fetchFromWAQI({
    required double lat,
    required double lng,
  }) async {
    final apiKey = Constantkey.AQI_WAQI_TOKEN;
    final url = "https://api.waqi.info/feed/geo:$lat;$lng/?token=$apiKey";
    final response = await _dio.get(url);

    if (response.statusCode == 200 && response.data['status'] == 'ok') {
      return CommanDetailAqiModel.fromWAQI(response.data['data']);
    } else {
      throw Exception("WAQI failed");
    }
  }

  Future<CommanDetailAqiModel> fetchFromGoogle({
    required double lat,
    required double lng,
  }) async {
    const apiKey = Constantkey.GOOGLE_MAP_API_KEY;
    final url =
        "https://airquality.googleapis.com/v1/currentConditions:lookup?key=$apiKey";

    final response = await _dio.post(
      url,
      data: {
        "universalAqi": true,
        "location": {"latitude": lat, "longitude": lng},
        "extraComputations": [
          "HEALTH_RECOMMENDATIONS",
          "DOMINANT_POLLUTANT_CONCENTRATION",
          "POLLUTANT_CONCENTRATION",
        ],
        "languageCode": "en",
      },
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    if (response.statusCode == 200 && response.data['indexes'] != null) {
      return CommanDetailAqiModel.fromGoogle(response.data);
    } else {
      throw Exception("Google AQI failed");
    }
  }

  Future<CommanDetailAqiModel> fetchFromOpenAQ({
    required double lat,
    required double lng,
  }) async {
    final url =
        "https://api.openaq.org/v2/latest?coordinates=$lat,$lng&radius=10000";

    final response = await _dio.get(url);

    if (response.statusCode == 200 && response.data['results'] != null) {
      final results = response.data['results'];
      if (results.isNotEmpty) {
        return CommanDetailAqiModel.fromOpenAQ(results[0]);
      } else {
        throw Exception("OpenAQ no data");
      }
    } else {
      throw Exception("OpenAQ failed");
    }
  }

  Future<Map<String, String>> getAltRecommendationsForAQI(int aqi) async {
    final jsonString = await rootBundle.loadString(
      'assets/locale/health_recommandation_tips.json',
    );
    final List<dynamic> recs = jsonDecode(jsonString);

    for (final item in recs) {
      final range = item['aqiRange'].split('-').map(int.parse).toList();
      if (aqi >= range[0] && aqi <= range[1]) {
        final random = Random();
        final Map<String, String> result = {};
        item['recommendations'].forEach((group, list) {
          final options = List<String>.from(list);
          result[group] = options[random.nextInt(options.length)];
        });
        print(result.toString());
        return result;
      }
    }
    return {};
  }

  getfullRecommendationsForAQI(int aqi) async {
    final jsonString = await rootBundle.loadString(
      'assets/locale/health_recommandation_tips.json',
    );
    final List<dynamic> recs = jsonDecode(jsonString);

    for (final item in recs) {
      final range = item['aqiRange'].split('-').map(int.parse).toList();
      if (aqi >= range[0] && aqi <= range[1]) {
        final random = Random();
        final Map<String, String> result = {};
        item['recommendations'].forEach((group, list) {
          final options = List<String>.from(list);
          result[group] = options[random.nextInt(options.length)];
        });
        item['recommendations'] = result;
        return item;
      }
    }
    return {};
  }
}
