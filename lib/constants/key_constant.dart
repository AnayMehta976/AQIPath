abstract class KEY_CONST {
  //error description
  static const request_send_timeout = "request_send_timeout";
  static const request_cancelled = "request_cancelled";
  static const request_connect_timeout = "request_connect_timeout";
  static const no_internet = "no_internet";
  static const request_receive_timeout = "request_receive_timeout";
  static const not_found = "Not found.";
  static const error = "Error";
  static const unknown_error = "Unknown_error";
}

class SavedKey {
  static String LASTSYNC = "lastsync";
  static String LASTCLEANDATABASE = "lastcleanDB";
  static String CONFIG_DATA = "configdata";
  static String STREAM_BG_DATA = "trackingdata";
  // static String nowPlaying = "now_playing";
  // static String topRated = "top_rated";
  // static String upcoming = "upcoming";
}

class Constantkey {
  // API keys are injected at build time so they never live in source control.
  // Pass them with:  flutter run --dart-define-from-file=dart_defines.json
  // (copy dart_defines.example.json to dart_defines.json and fill it in).
  static const GOOGLE_MAP_API_KEY = String.fromEnvironment('GOOGLE_MAP_API_KEY');
  static const AQI_NINJA_KEY = String.fromEnvironment('AQI_NINJA_KEY');
  static const AQI_WAQI_TOKEN = String.fromEnvironment('AQI_WAQI_TOKEN');
}
