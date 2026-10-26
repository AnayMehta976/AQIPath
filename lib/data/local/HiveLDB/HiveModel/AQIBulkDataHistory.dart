import 'package:hive_flutter/hive_flutter.dart';

part 'AQIBulkDataHistory.g.dart';

@HiveType(typeId: 20)
class Aqibulkdatahistory extends HiveObject {
  @HiveField(0)
  String uid;
  @HiveField(1)
  String direction_uid;

  @HiveField(2)
  List<double> pointlatlng;

  @HiveField(3)
  DateTime synctime;

  @HiveField(4)
  Map<String, dynamic> aqidetailjsondata;

  @HiveField(5)
  int apiType;

  Aqibulkdatahistory({
    required this.uid,
    required this.direction_uid,
    required this.pointlatlng,
    required this.synctime,
    required this.aqidetailjsondata,
    required this.apiType,
  });
}
