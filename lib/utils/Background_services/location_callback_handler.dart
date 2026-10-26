import 'dart:async';
import 'dart:isolate';

import 'package:background_locator_2/location_dto.dart';

const String isolateName = "LocatorIsolate";
ReceivePort port = ReceivePort();

class LocationCallbackHandler {
  static Future<void> initCallback(Map<dynamic, dynamic> params) async {
    print("Locator initialized");
  }

  static Future<void> disposeCallback() async {
    print("Locator disposed");
  }

  static Future<void> callback(LocationDto locationDto) async {
    print("New location: ${locationDto.toString()}");
    // Save to DB / send to Bloc / API call
  }
}
