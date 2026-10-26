import 'package:aqi_app/constants/color_constant.dart';
import 'package:aqi_app/data/models/aqi_responses.dart';
import 'package:flutter/material.dart';

class CommanDetailAqiModel {
  /// The main AQI value (null if not provided)
  final int? aqi;

  /// The AQI category (Good, Moderate, Unhealthy, etc.)
  final String? category;

  /// The AQI color code (if available)
  final Color? color;

  /// Dominant pollutant (e.g., PM2.5)
  final String? dominantPollutant;

  /// Map of pollutants with details
  /// Example: {'pm25': {'value': 35.0, 'unit': 'µg/m³'}}
  final Object? pollutants;

  /// Health recommendations (optional)
  final Map<dynamic, dynamic>? healthRecommendations;

  /// Location name (station, area, etc.)
  final String? locationName;

  /// City name if available
  final String? city;

  /// Station latitude and longitude
  final double? latitude;
  final double? longitude;

  /// When the measurement was taken
  final DateTime? timestamp;

  /// Which API provider provided this data
  final String source;

  /// Help for prediction next days
  final Object? forcast;

  /// pin location
  final String? pinlocationadd;

  CommanDetailAqiModel({
    required this.source,
    this.aqi,
    this.category,
    this.color,
    this.dominantPollutant,
    this.pollutants,
    this.healthRecommendations,
    this.locationName,
    this.city,
    this.latitude,
    this.longitude,
    this.timestamp,
    this.forcast,
    this.pinlocationadd,
  });

  @override
  String toString() {
    return 'CommanDetailAqiModel(aqi: $aqi, category: $category, dominantPollutant: $dominantPollutant, location: $locationName, city: $city, timestamp: $timestamp, source: $source , forcast $forcast)';
  }

  /// Factory helper to create from WAQI
  factory CommanDetailAqiModel.fromWAQI(Map<String, dynamic> data) {
    Color aqicolor(aqivalue) {
      if (aqivalue < 50) {
        return COLOR_CONST.aqiheatcolors[0];
      } else if (aqivalue < 100) {
        return COLOR_CONST.aqiheatcolors[1];
      } else if (aqivalue < 200) {
        return COLOR_CONST.aqiheatcolors[2];
      } else if (aqivalue < 300) {
        return COLOR_CONST.aqiheatcolors[3];
      } else {
        return COLOR_CONST.aqiheatcolors[4];
      }
    }

    return CommanDetailAqiModel(
      source: 'WAQI',
      aqi: data['aqi'],
      dominantPollutant: data['dominentpol'],
      locationName: data['city']?['name'],
      latitude: data['city']?['geo']?[0],
      longitude: data['city']?['geo']?[1],
      color: aqicolor(data['aqi']),
      timestamp: DateTime.tryParse(data['time']?['iso'] ?? ''),
      pollutants: {
        for (var key in (data['iaqi'] ?? {}).keys)
          key: {'value': data['iaqi'][key]['v'], 'unit': 'µg/m³'},
      },
      forcast: data['forecast']['daily'],
      healthRecommendations:
          data['extand_data'] == null
              ? {}
              : data['extand_data']['recommendations'],
      category:
          "Air Quility is ${data['extand_data'] == null ? '' : data['extand_data']['category']}",
    );
  }

  /// Factory helper for Google AQI
  factory CommanDetailAqiModel.fromGoogle(Map<String, dynamic> data) {
    final index = data['indexes']?[0];
    Color normalizedToColor(double r, double g, double b, [double a = 1.0]) {
      return Color.fromARGB(
        (a * 255).round(),
        (r * 255).round(),
        (g * 255).round(),
        (b * 255).round(),
      );
    }

    return CommanDetailAqiModel(
      source: 'Google',
      aqi: index?['aqi'],
      category: index?['category'],
      color: normalizedToColor(
        index?['color']['red'].toDouble() ?? 0,
        index?['color']['green'].toDouble() ?? 0,
        index?['color']['blue']?.toDouble() ?? 0,
      ),
      dominantPollutant: index?['dominantPollutant'],
      pollutants: data['pollutants'] ?? [],
      healthRecommendations: data['healthRecommendations'],
      timestamp: DateTime.now(),
      forcast: data['extand_data'],
    );
  }

  /// Factory helper for Google AQI
  factory CommanDetailAqiModel.fromGoogleNew(AqiResponse data) {
    return CommanDetailAqiModel(
      source: 'Google',
      aqi: data.aqi,
      category: data.customCategory ?? data.category,
      color: data.color,
      dominantPollutant: data.dominantPollutant,
      pollutants: data.pollutants ?? [],
      healthRecommendations:
          data.customhealthRecommendations ?? data.healthRecommendations,
      timestamp: DateTime.now(),
      forcast: data.forcast,
    );
  }

  /// Factory helper for OpenAQ
  factory CommanDetailAqiModel.fromOpenAQ(Map<String, dynamic> result) {
    final measurements = result['measurements'] as List<dynamic>;
    return CommanDetailAqiModel(
      source: 'OpenAQ',
      aqi: null, // OpenAQ provides raw values, not unified AQI
      pollutants: {
        for (var m in measurements)
          m['parameter']: {'value': m['value'], 'unit': m['unit']},
      },
      locationName: result['location'],
      city: result['city'],
      latitude: result['coordinates']?['latitude'],
      longitude: result['coordinates']?['longitude'],
      timestamp: DateTime.tryParse(result['date']['utc'] ?? ''),
    );
  }
}
