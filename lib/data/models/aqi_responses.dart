import 'dart:ui';

class AqiColor {
  final double red;
  final double green;
  final double blue;

  AqiColor({required this.red, required this.green, required this.blue});

  factory AqiColor.fromJson(Map<dynamic, dynamic> json) {
    return AqiColor(
      red: (json['red'] ?? 0.0).toDouble(),
      green: (json['green'] ?? 0.0).toDouble(),
      blue: (json['blue'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'red': red, 'green': green, 'blue': blue};
  }

  /// Convert normalized (0.0–1.0) to Flutter [Color]
  Color toFlutterColor() {
    return Color.fromRGBO(
      (red * 255).round(),
      (green * 255).round(),
      (blue * 255).round(),
      1.0,
    );
  }
}

class AqiResponse {
  final int aqi;
  final int previewaqi;
  final int waqi;
  final Color color; // handled via AqiColor model
  final String category;
  final String customCategory;
  final String? dominantPollutant;
  final List<dynamic>? pollutants;
  final Map? healthRecommendations;
  final Map? customhealthRecommendations;
  final Object? forcast;

  AqiResponse({
    required this.aqi,
    required this.previewaqi,
    required this.waqi,
    required this.color,
    required this.category,
    required this.customCategory,
    this.dominantPollutant,
    this.pollutants,
    this.healthRecommendations,
    this.customhealthRecommendations,
    this.forcast,
  });

  factory AqiResponse.fromJson(Map<String, dynamic> json) {
    return AqiResponse(
      aqi: json['aqi'] ?? 0,
      color:
          json['color'] != null
              ? AqiColor.fromJson(json['color']).toFlutterColor()
              : AqiColor(red: 0, green: 0, blue: 0).toFlutterColor(),
      category: json['category'] ?? "Unknown",
      customCategory: (json['customCategory'] ?? ""),
      dominantPollutant: json['dominantPollutant'],
      pollutants: json['pollutants'],
      healthRecommendations: json['healthRecommendations'],
      customhealthRecommendations: json['customhealthRecommendations'],
      previewaqi: json['previewaqi'] ?? 0,
      waqi: json['waqi'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aqi': aqi,
      'color': color,
      'category': category,
      if (forcast != null) 'myforcast': forcast,
      if (dominantPollutant != null) 'dominantPollutant': dominantPollutant,
      if (pollutants != null) 'pollutants': pollutants,
      if (healthRecommendations != null)
        'healthRecommendations': healthRecommendations,
      'customCategory': customCategory,
      "previewaqi": previewaqi,
      'waqi': waqi,
    };
  }

  @override
  String toString() {
    return 'AqiResponse('
        'aqi: $aqi, '
        'color: ${color.value.toRadixString(16).padLeft(8, '0')}, ' // HEX format
        'category: $category, '
        'customCategory: $customCategory'
        'dominantPollutant: $dominantPollutant, '
        'pollutants: $pollutants, '
        'healthRecommendations: $healthRecommendations, '
        'forcast: $forcast'
        ')';
  }
}
