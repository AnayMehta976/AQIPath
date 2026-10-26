class DevEnvironment {
  final receiveTimeout = Duration(milliseconds: 2 * 60 * 1000);
  final connectTimeout = Duration(milliseconds: 2 * 60 * 1000);
}

class AllApi {
  static const BASE_URL_AQI = "https://api.api-ninjas.com/v1/airquality";
  static const BASE_URL_DIRECTION =
      "https://maps.googleapis.com/maps/api/directions/json";
}

final environment = DevEnvironment();

enum MethodType { GET, POST }
