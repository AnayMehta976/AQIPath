import 'package:aqi_app/data/local/HiveLDB/HiveModel/AQIBulkDataHistory.dart';
import 'package:aqi_app/data/local/HiveLDB/HiveModel/AQiDetailHistory.dart';
import 'package:aqi_app/data/local/HiveLDB/HiveModel/CurrentRideRoute.dart';
import 'package:aqi_app/data/local/HiveLDB/HiveModel/LoadSearchHistory.dart';
import 'package:aqi_app/data/local/HiveLDB/HiveModel/MainNavigationHistory.dart';
import 'package:hive/hive.dart';

class HiveBasemodel {
  static initilizeHive() async {
    Hive.registerAdapter(AQIDetailHistoryAdapter());
    Hive.registerAdapter(AttributionAdapter());
    Hive.registerAdapter(AQICityAdapter());
    Hive.registerAdapter(IAQIAdapter());
    Hive.registerAdapter(AQITimeAdapter());
    Hive.registerAdapter(ForecastAdapter());
    Hive.registerAdapter(DailyForecastAdapter());
    Hive.registerAdapter(LoadsearchhistoryAdapter());
    Hive.registerAdapter(AqibulkdatahistoryAdapter());
    Hive.registerAdapter(MainNavigationHistoryAdapter());
    Hive.registerAdapter(CurrentRideRouteAdapter());
    Hive.registerAdapter(PolylinePointAdapter());
    Hive.registerAdapter(LatLngPointAdapter());
    await Hive.openBox<CurrentRideRoute>('rideRoutes');
    await Hive.openBox<AQIDetailHistory>('aqi_detail_history');
    await Hive.openBox<Aqibulkdatahistory>('aqi_bulk_history');
    await Hive.openBox<Loadsearchhistory>('direction_api_history');
    await Hive.openBox<MainNavigationHistory>('navigationHistory');
  }
}
