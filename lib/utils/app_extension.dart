// import 'package:aqi_app/utils/formatter.dart';

import 'package:aqi_app/data/models/route_option.dart';
import 'package:flutter/cupertino.dart';

// extension PriceParsing on int {
//   String toPrice() {
//     return "${UtilFormatter.formatNumber(this)}₫";
//   }
// }

extension Space on int {
  Widget get toSpace {
    return SizedBox(height: toDouble(), width: toDouble());
  }
}

extension Ex on double {
  double toPrecision(int n) => double.parse(toStringAsFixed(n));
}

extension UniqueRouteOptions on List<RouteOption> {
  List<RouteOption> uniqueByProperties() {
    final seen = <String>{};
    final unique = <RouteOption>[];

    for (final r in this) {
      final key =
          '${r.isLoop}|${r.points}|${r.avgAqi}|'
          '${r.distanceKm}|${r.duration}|${r.trafficInfo}';
      if (seen.add(key)) {
        unique.add(r);
      }
    }
    return unique;
  }
}
