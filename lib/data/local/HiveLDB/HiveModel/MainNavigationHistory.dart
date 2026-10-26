import 'package:hive/hive.dart';

part 'MainNavigationHistory.g.dart';

@HiveType(typeId: 40) // make sure each class has a unique typeId
class MainNavigationHistory extends HiveObject {
  @HiveField(0)
  String startAddress;

  @HiveField(1)
  String endAddress;

  @HiveField(2)
  List<double> stratEndLatLng;

  @HiveField(3)
  DateTime dateOfSync;

  @HiveField(4)
  double routeAvgAqi;

  @HiveField(5)
  String detailDataReferenceId;

  MainNavigationHistory({
    required this.startAddress,
    required this.endAddress,
    required this.stratEndLatLng,
    required this.dateOfSync,
    required this.routeAvgAqi,
    required this.detailDataReferenceId,
  });
}
