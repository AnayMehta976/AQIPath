class DailyAqiResult {
  final DateTime day;
  final int pm10Aqi;
  final int pm25Aqi;
  final int finalAqi;
  final String dominantPollutant;

  DailyAqiResult({
    required this.day,
    required this.pm10Aqi,
    required this.pm25Aqi,
    required this.finalAqi,
    required this.dominantPollutant,
  });

  @override
  String toString() {
    return "Day: $day | AQI: $finalAqi | Dominant: $dominantPollutant | PM10 AQI: $pm10Aqi | PM2.5 AQI: $pm25Aqi";
  }
}

class DailyAqiPredictor {
  final List<Map<String, dynamic>> dailyPm10;
  final List<Map<String, dynamic>> dailyPm25;

  DailyAqiPredictor({
    required this.dailyPm10,
    required this.dailyPm25,
  });

  List<DailyAqiResult> calculateDailyAqi() {
    final List<DailyAqiResult> results = [];

    final int days = dailyPm10.length;

    for (int i = 0; i < days; i++) {
      final pm10Avg = dailyPm10[i]['avg'].toDouble();
      final pm25Avg = dailyPm25[i]['avg'].toDouble();
      final day = DateTime.parse(dailyPm10[i]['day']);

      final pm10Aqi = _calculatePM10Aqi(pm10Avg);
      final pm25Aqi = _calculatePM25Aqi(pm25Avg);

      final finalAqi = pm10Aqi >= pm25Aqi ? pm10Aqi : pm25Aqi;
      final dominantPollutant = pm10Aqi >= pm25Aqi ? 'PM10' : 'PM2.5';

      results.add(
        DailyAqiResult(
          day: day,
          pm10Aqi: pm10Aqi,
          pm25Aqi: pm25Aqi,
          finalAqi: finalAqi,
          dominantPollutant: dominantPollutant,
        ),
      );
    }

    return results;
  }

  int _calculatePM10Aqi(double pm10) {
    if (pm10 <= 50) {
      return _linearScale(pm10, 0, 50, 0, 50);
    } else if (pm10 <= 100) {
      return _linearScale(pm10, 51, 100, 51, 100);
    } else if (pm10 <= 250) {
      return _linearScale(pm10, 101, 250, 101, 200);
    } else if (pm10 <= 350) {
      return _linearScale(pm10, 251, 350, 201, 300);
    } else if (pm10 <= 430) {
      return _linearScale(pm10, 351, 430, 301, 400);
    } else {
      return _linearScale(pm10, 431, 500, 401, 500);
    }
  }

  int _calculatePM25Aqi(double pm25) {
    if (pm25 <= 30) {
      return _linearScale(pm25, 0, 30, 0, 50);
    } else if (pm25 <= 60) {
      return _linearScale(pm25, 31, 60, 51, 100);
    } else if (pm25 <= 90) {
      return _linearScale(pm25, 61, 90, 101, 200);
    } else if (pm25 <= 120) {
      return _linearScale(pm25, 91, 120, 201, 300);
    } else if (pm25 <= 250) {
      return _linearScale(pm25, 121, 250, 301, 400);
    } else {
      return _linearScale(pm25, 251, 500, 401, 500);
    }
  }

  int _linearScale(
    double Cp,
    double Clow,
    double Chigh,
    int Ilow,
    int Ihigh,
  ) {
    return (((Ihigh - Ilow) / (Chigh - Clow)) * (Cp - Clow) + Ilow).round();
  }
}
