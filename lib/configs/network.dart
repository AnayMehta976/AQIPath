import 'package:connectivity_plus/connectivity_plus.dart';

class Network {
  static bool connected = false;

  static init() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result.contains(ConnectivityResult.mobile)) {
        connected = true;
      } else if (result.contains(ConnectivityResult.wifi)) {
        connected = true;
      } else {
        connected = false;
      }
    });
  }

  static Future<bool> isConnected() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      return true;
    } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
      return true;
    } else {
      return false;
    }
  }
}
