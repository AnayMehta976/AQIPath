import 'package:flutter/material.dart';

import 'package:aqi_app/configs/size_config.dart';
import 'package:aqi_app/constants/color_constant.dart';
import 'package:aqi_app/constants/font_constant.dart';
import 'package:aqi_app/data/models/aqi_point.dart';
import 'package:aqi_app/data/models/info_model.dart';
import 'package:aqi_app/utils/dialog.dart';
import 'package:aqi_app/utils/geo_utils.dart';

import '../../../data/models/route_option.dart';

class AqiRoutesWidgets {
  static Widget legendDot(Color c, String text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        SizedBox(width: 6),
        Text(
          text,
          style: FONT_CONST.REGULAR_DEFAULT.copyWith(color: Colors.black),
        ),
      ],
    );
  }

  static void showTopRoutesList(context, routes, onpressedcallback(cvalue)) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Top Routes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                if (routes.isEmpty) ...[
                  Text(
                    'No routes computed yet',
                    style: FONT_CONST.BOLD_DEFAULT.copyWith(
                      color: Colors.black,
                    ),
                  ),
                ] else ...[
                  for (final r in routes)
                    ListTile(
                      title: Text(
                        r.id,
                        style: FONT_CONST.BOLD_DEFAULT.copyWith(
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        'AQI: ${r.avgAqi.toStringAsFixed(1)} • Dist: ${r.distanceKm.toStringAsFixed(2)} km',
                        style: FONT_CONST.BOLD_DEFAULT.copyWith(
                          color: Colors.black,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        onpressedcallback(r);
                      },
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  static void showRouteOptionsInfo(BuildContext context) {
    UtilDialog.showInfoDialogAqiRoute(
      context: context,
      title: 'Options Info',
      items: [
        InfoItem(
          icon: Icons.route,
          title: 'Check Out Available Routes',
          description:
              'On tap, you will find all the available best AQI-based routes.',
        ),
        InfoItem(
          icon: Icons.polyline,
          title: 'Route Details',
          description: 'Tap any route to view detailed route information.',
        ),
        InfoItem(
          icon: Icons.navigation,
          title: 'Start Navigation',
          description: 'Tap "Use" to begin navigation with the selected route.',
        ),
      ],
    );
  }

  void showRouteInfoPanel(RouteOption route, context, onUseCallback) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16.0,
            16.0,
            16.0,
            16.0 + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 4, width: 40, color: Colors.grey[300]),
              SizedBox(height: 12),
              Text(
                'Route Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 8),
              buildInfoRow(Icons.route, 'Points', '${route.points.length}'),
              buildInfoRow(
                Icons.cloud,
                'Average AQI',
                route.avgAqi.toStringAsFixed(1),
              ),
              buildInfoRow(
                Icons.pin_drop,
                'Distance',
                '${route.distanceKm.toStringAsFixed(2)} km',
              ),
              buildInfoRow(
                Icons.access_time,
                'Duration',
                route.duration != null
                    ? '${route.duration!.inMinutes} min'
                    : 'N/A',
              ),
              buildInfoRow(
                Icons.traffic,
                'Traffic',
                route.trafficInfo ?? 'N/A',
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Close',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ),

                  // SizedBox(width: 12),
                  // ElevatedButton(
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Colors.blue, // 👈 Blue background
                  //     foregroundColor: Colors.white, // 👈 Text/Icon color

                  //     padding: const EdgeInsets.symmetric(
                  //       horizontal: 24,
                  //       vertical: 12,
                  //     ), // optional padding
                  //   ),
                  //   onPressed: () {
                  //     onUseCallback(route.id, context);
                  //     // action: set as preferred or navigate
                  //     Navigator.of(context).pop();
                  //   },
                  //   child: const Text(
                  //     'Use Route',
                  //     style: TextStyle(
                  //       fontSize: 16,
                  //       fontWeight: FontWeight.w600,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget aqiPointDetailsSheet(AqiPoint ap, context) {
    return Container(
      constraints: BoxConstraints(minWidth: SizeConfig.screenWidth),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16.0,
          16.0,
          16.0,
          16.0 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AQI Point',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black12,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'AQI: ${ap.aqi.toStringAsFixed(0)}',
              style: TextStyle(color: Colors.black),
            ),
            Text(
              'Lat: ${ap.pos.latitude.toStringAsFixed(6)}',
              style: TextStyle(color: Colors.black),
            ),
            Text(
              'Lng: ${ap.pos.longitude.toStringAsFixed(6)}',
              style: TextStyle(color: Colors.black),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔹 Separate Reusable Widget
class AqiRouteCard extends StatefulWidget {
  final int type;
  final String mode;
  final double radiuskm;
  final double maxHeight;
  final List<RouteOption> allroutes;
  Function onUseCallback;
  AqiRouteCard({
    Key? key,
    required this.type,
    required this.mode,
    required this.radiuskm,
    required this.maxHeight,
    required this.allroutes,
    required this.onUseCallback,
  }) : super(key: key);

  @override
  State<AqiRouteCard> createState() => _AqiRouteCardState();
}

class _AqiRouteCardState extends State<AqiRouteCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      // constraints: BoxConstraints(maxHeight: widget.maxHeight),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        // borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        // boxShadow: [
        //   BoxShadow(color: Colors.black26, blurRadius: 8, spreadRadius: 2),
        // ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1️⃣ Route List
          const Text(
            "Available Routes",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: COLOR_CONST.btnColorOrng,
            ),
          ),

          const SizedBox(height: 20),
          ...widget.allroutes.map(
            (e) => Column(
              children: [
                ListTile(
                  leading:
                      e.isLoop
                          ? Image.asset(
                            "assets/images/routing.png",
                            width: 50,
                            height: 50,
                          )
                          : const Icon(Icons.alt_route, size: 50),
                  title: RichText(
                    text: TextSpan(
                      style: TextStyle(color: COLOR_CONST.darkShadeColor),
                      children:
                          !e.isLoop
                              ? <TextSpan>[
                                TextSpan(
                                  text: getSubstringUntilThirdComma(
                                    e.filterData!.startAddress.toString(),
                                  ),
                                  style: TextStyle(
                                    // Add your desired style for the start address here
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                TextSpan(
                                  text: ' to ',
                                  style: TextStyle(
                                    // Add your desired style for the "to" here
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                TextSpan(
                                  text: getSubstringUntilThirdComma(
                                    e.filterData!.endAddress.toString(),
                                  ),
                                  style: TextStyle(
                                    // Add your desired style for the end address here
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ]
                              : <TextSpan>[
                                TextSpan(
                                  text: 'Loop',
                                  style: TextStyle(
                                    // Add your desired style for "Loop" here
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic,
                                    color: COLOR_CONST.darkShadeColor,
                                  ),
                                ),
                              ],
                    ),
                  ),
                  subtitle: Text(
                    "${e.duration!.inMinutes.toStringAsFixed(0)} mins • ${(e.distanceKm).toStringAsFixed(2)} KM • AQI ${e.avgAqi.toStringAsFixed(1)}",
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      widget.onUseCallback(e.id);
                    },
                    child: const Text("Use"),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 6,
                  ),
                  margin: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300, // light tile background
                    borderRadius: BorderRadius.circular(
                      8,
                    ), // pill/rounded style
                  ),
                  child: Text(
                    GeoUtils.buildRouteInstruction(
                      isLoop: e.isLoop,
                      routeDistanceKm: e.distanceKm,
                      totalDistanceKm: widget.radiuskm,
                      avgAqi: e.avgAqi,
                      mode: widget.mode,
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
                Divider(),
              ],
            ),
          ),

          // const Divider(),

          // // 2️⃣ Recompute with radius
          // const Text(
          //   "Recompute with Radius",
          //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          // ),
          // Slider(
          //   value: _radius,
          //   min: 1,
          //   max: 10,
          //   divisions: 9,
          //   label: "${_radius.toStringAsFixed(1)} km",
          //   onChanged: (v) {
          //     setState(() {
          //       _radius = v;
          //     });
          //   },
          // ),

          // const Divider(),

          // // 3️⃣ About feature
          // const Text(
          //   "About",
          //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          // ),
          // const Text(
          //   "AQI Path helps you choose healthier routes by analyzing "
          //   "air quality data in real time. Recompute routes with custom "
          //   "radius to optimize your path for cleaner air.",
          // ),
        ],
      ),
    );
  }

  String getSubstringUntilThirdComma(String text) {
    int count = 0;
    int thirdCommaIndex = -1;

    for (int i = 0; i < text.length; i++) {
      if (text[i] == ',') {
        count++;
        if (count == 3) {
          thirdCommaIndex = i;
          break;
        }
      }
    }

    if (thirdCommaIndex != -1) {
      return text.substring(0, thirdCommaIndex);
    } else {
      // Return the original text if there aren't three commas
      return text;
    }
  }
}
