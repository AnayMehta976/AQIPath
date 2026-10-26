// lib/services/aqi_calculator.dart
import 'dart:math';
// lib/models/pollutant_data.dart

class AqiCalculator {
  // --- 1. CPCB Breakpoints ---
  static const Map<String, List<List<double>>> _cpcbBreakpoints = {
    "PM10": [
      [0, 50, 0, 50],
      [51, 100, 51, 100],
      [101, 250, 101, 200],
      [251, 350, 201, 300],
      [351, 430, 301, 400],
      [431, 1000000, 401, 500],
    ],
    "PM25": [
      [0, 30, 0, 50],
      [31, 60, 51, 100],
      [61, 90, 101, 200],
      [91, 120, 201, 300],
      [121, 250, 301, 400],
      [251, 1000000, 401, 500],
    ],
    "NO2": [
      [0, 40, 0, 50],
      [41, 80, 51, 100],
      [81, 180, 101, 200],
      [181, 280, 201, 300],
      [281, 400, 301, 400],
      [401, 1000000, 401, 500],
    ],
    "O3": [
      [0, 50, 0, 50],
      [51, 100, 51, 100],
      [101, 168, 101, 200],
      [169, 208, 201, 300],
      [209, 748, 301, 400],
      [749, 1000000, 401, 500],
    ],
    "CO": [
      [0.0, 1.0, 0, 50],
      [1.1, 2.0, 51, 100],
      [2.1, 10.0, 101, 200],
      [10.1, 17.0, 201, 300],
      [17.1, 34.0, 301, 400],
      [34.1, 1000000, 401, 500],
    ],
    "SO2": [
      [0, 40, 0, 50],
      [41, 80, 51, 100],
      [81, 380, 101, 200],
      [381, 800, 201, 300],
      [801, 1600, 301, 400],
      [1601, 1000000, 401, 500],
    ],
  };

  // --- 2. Unit Conversion ---
  static const double _molarVolume = 24.45; // L/mol at 25°C, 1 atm
  static const Map<String, double> _molecularWeights = {
    "CO": 28.01,
    "NO2": 46.01,
    "O3": 48.00,
    "SO2": 64.07,
  };

  /// Converts Google API units → CPCB standard units
  /// CO → mg/m³, others → µg/m³
  static double _convertToStandardUnit(
    String code,
    double value,
    String units,
  ) {
    final upper = code.toUpperCase();

    if (units == "MICROGRAMS_PER_CUBIC_METER") return value;

    if (units == "PARTS_PER_BILLION") {
      if (!_molecularWeights.containsKey(upper)) return 0.0;

      // Formula: µg/m³ = (ppb × MW) / molar volume
      final ugM3 = (value * _molecularWeights[upper]!) / _molarVolume;

      // Convert to mg/m³ if pollutant is CO
      return (upper == "CO") ? (ugM3 / 1000.0) : ugM3;
    }

    return 0.0;
  }

  // --- 3. Individual AQI calculation ---
  static double _calculateIndividualAqi(String code, double concentration) {
    final pollutant =
        (code.toUpperCase() == "PM2.5") ? "PM25" : code.toUpperCase();
    final breakpoints = _cpcbBreakpoints[pollutant];
    if (breakpoints == null || concentration <= 0) return 0.0;

    for (final b in breakpoints) {
      final cL = b[0], cH = b[1], iL = b[2], iH = b[3];
      if (concentration >= cL && concentration <= cH) {
        return (((iH - iL) / (cH - cL)) * (concentration - cL) + iL).clamp(
          0.0,
          500.0,
        );
      }
    }

    // Above last range
    final last = breakpoints.last;
    return last[3];
  }

  // --- 4. Overall AQI ---
  static int calculateOverallCpcbAqi(List<Pollutant> pollutants) {
    double maxAqi = 0.0;

    for (final pollutant in pollutants) {
      final concentration = pollutant.concentration.value;
      final units = pollutant.concentration.units;
      final code = pollutant.code;

      final converted = _convertToStandardUnit(code, concentration, units);
      final individualAqi = _calculateIndividualAqi(code, converted);

      maxAqi = individualAqi > maxAqi ? individualAqi : maxAqi;
    }

    return maxAqi.round();
  }

  // choose smart Aqi
  static int smartAqichoose({
    required num? calcAqi,
    required num? waqiAqi,
    required num? universalAqi,
  }) {
    final c = (calcAqi ?? 0).toInt();
    final w = (waqiAqi ?? 0).toInt();
    final u = (universalAqi ?? 0).toInt();
    int upperAqi = c < u ? u : c;

    int minVal = upperAqi < w ? upperAqi : w;
    int maxVal = upperAqi > w ? upperAqi : w;

    double ratio = minVal / maxVal;

    if (ratio > 0.6) {
      // AQIs are close → prefer upper/universal side
      return upperAqi;
    } else {
      // Too different → trust WAQI as ground truth
      return ((w + upperAqi) / 2).toInt();
    }
  }
}

// Helper function for safe JSON decoding
// ✅ Corrected Helper Function (Accepts List<dynamic> directly)
List<Pollutant> pollutantFromList(List<dynamic> jsonList) {
  return jsonList.map((x) => Pollutant.fromJson(x)).toList();
}

class Pollutant {
  final String code;
  final String displayName;
  final String fullName;
  final Concentration concentration;

  Pollutant({
    required this.code,
    required this.displayName,
    required this.fullName,
    required this.concentration,
  });

  /// Convert a single Map → Pollutant
  factory Pollutant.fromJson(Map<String, dynamic> json) => Pollutant(
    code: json["code"],
    displayName: json["displayName"],
    fullName: json["fullName"],
    concentration: Concentration.fromJson(json["concentration"]),
  );

  /// Alias: Map → Pollutant (same as fromJson)
  factory Pollutant.fromMap(Map<String, dynamic> map) =>
      Pollutant.fromJson(map);

  /// Convert List<Map> → List<Pollutant>
  static List<Pollutant> fromList(List<dynamic> list) {
    return list.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      map["concentration"] = Map<String, dynamic>.from(
        map["concentration"] as Map,
      );
      return Pollutant.fromJson(map);
    }).toList();
  }

  /// Convert model → Map
  Map<String, dynamic> toMap() {
    return {
      "code": code,
      "displayName": displayName,
      "fullName": fullName,
      "concentration": concentration.toMap(),
    };
  }

  @override
  String toString() {
    return 'Pollutant('
        'code: $code, '
        'displayName: $displayName, '
        'fullName: $fullName, '
        'concentration: $concentration'
        ')';
  }
}

class Concentration {
  final double value;
  final String units;

  Concentration({required this.value, required this.units});

  /// Convert Map → Concentration
  factory Concentration.fromJson(Map<String, dynamic> json) => Concentration(
    value: (json["value"] as num).toDouble(),
    units: json["units"],
  );

  /// Alias: Map → Concentration
  factory Concentration.fromMap(Map<String, dynamic> map) =>
      Concentration.fromJson(map);

  /// Convert Concentration → Map
  Map<String, dynamic> toMap() {
    return {"value": value, "units": units};
  }

  @override
  String toString() => 'Concentration(value: $value, units: $units)';
}




// gemine calc.
  // static double calculateAQI(List<dynamic> pollutants) {
  //   // Helper: breakpoints for each pollutant
  //   final breakpoints = {
  //     'pm25': [
  //       [0, 30, 0, 50],
  //       [31, 60, 51, 100],
  //       [61, 90, 101, 200],
  //       [91, 120, 201, 300],
  //       [121, 250, 301, 400],
  //       [251, 500, 401, 500],
  //     ],
  //     'pm10': [
  //       [0, 50, 0, 50],
  //       [51, 100, 51, 100],
  //       [101, 250, 101, 200],
  //       [251, 350, 201, 300],
  //       [351, 430, 301, 400],
  //       [431, 600, 401, 500],
  //     ],
  //     'no2': [
  //       [0, 40, 0, 50],
  //       [41, 80, 51, 100],
  //       [81, 180, 101, 200],
  //       [181, 280, 201, 300],
  //       [281, 400, 301, 400],
  //       [401, 1000, 401, 500],
  //     ],
  //     'so2': [
  //       [0, 40, 0, 50],
  //       [41, 80, 51, 100],
  //       [81, 380, 101, 200],
  //       [381, 800, 201, 300],
  //       [801, 1600, 301, 400],
  //       [1601, 2000, 401, 500],
  //     ],
  //     'o3': [
  //       [0, 50, 0, 50],
  //       [51, 100, 51, 100],
  //       [101, 168, 101, 200],
  //       [169, 208, 201, 300],
  //       [209, 748, 301, 400],
  //       [749, 1000, 401, 500],
  //     ],
  //     'co': [
  //       [0, 1, 0, 50],
  //       [1.1, 2, 51, 100],
  //       [2.1, 10, 101, 200],
  //       [10.1, 17, 201, 300],
  //       [17.1, 34, 301, 400],
  //       [34.1, 50, 401, 500],
  //     ],
  //   };

  //   double maxAqi = 0;

  //   for (var p in pollutants) {
  //     final code = p['code'].toString().toLowerCase();
  //     final concentration = p['concentration']['value'].toDouble();

  //     if (!breakpoints.containsKey(code)) continue;

  //     for (var bp in breakpoints[code]!) {
  //       double bplo = bp[0].toDouble(), bphi = bp[1].toDouble();
  //       double ilo = bp[2].toDouble(), ihi = bp[3].toDouble();

  //       if (concentration >= bplo && concentration <= bphi) {
  //         final aqi =
  //             ((ihi - ilo) / (bphi - bplo)) * (concentration - bplo) + ilo;
  //         if (aqi > maxAqi) maxAqi = aqi;
  //         break;
  //       }
  //     }
  //   }

  //   return maxAqi;
  // }

  // static int smartAqichoose({
  //   required num? calcAqi,
  //   required num? waqiAqi,
  //   required num? universalAqi,
  // }) {
  //   final c = (calcAqi ?? 0).toInt();
  //   final w = (waqiAqi ?? 0).toInt();
  //   final u = (universalAqi ?? 0).toInt();
  //   int upperAqi = c < u ? u : c;

  //   int minVal = upperAqi < w ? upperAqi : w;
  //   int maxVal = upperAqi > w ? upperAqi : w;

  //   double ratio = minVal / maxVal;

  //   if (ratio > 0.6) {
  //     // AQIs are close → prefer upper/universal side
  //     return upperAqi;
  //   } else {
  //     // Too different → trust WAQI as ground truth
  //     return ((w + upperAqi) / 2).toInt();
  //   }
  // }

  // static int getPreviewAqi({
  //   required num? calcAqi,
  //   required num? waqiAqi,
  //   required num? universalAqi,
  // }) {
  //   // Convert all to int safely
  //   final c = (calcAqi ?? 0).toInt();
  //   final w = (waqiAqi ?? 0).toInt();
  //   final u = (universalAqi ?? 0).toInt();
  //   print("Calculated AQI: $c, WAQI AQI: $w, Universal AQI: $u");
  //   // 1️⃣ If calculated AQI is valid (> 0), prefer it
  //   if (c > 0) return c;

  //   // 2️⃣ Else if WAQI AQI is valid, use that
  //   if (w > 0) return w;

  //   // 3️⃣ Else fallback to Universal AQI
  //   if (u > 0) return u;

  //   // 4️⃣ If all invalid, return 0 as "No Data"
  //   return 0;
  // }
