import 'package:hive/hive.dart';

// part 'Loadsearchhistory.g.dart';
part 'LoadSearchHistory.g.dart';

@HiveType(typeId: 30)
class Loadsearchhistory extends HiveObject {
  @HiveField(0)
  String uid;

  @HiveField(1)
  List<double> startlatlng;

  @HiveField(2)
  List<double> endlatlng;

  @HiveField(3)
  DateTime synctime;
  @HiveField(4)
  Map<String, dynamic> directionjsondata;

  Loadsearchhistory({
    required this.uid,
    required this.startlatlng,
    required this.endlatlng,
    required this.synctime,
    required this.directionjsondata,
  });
}
