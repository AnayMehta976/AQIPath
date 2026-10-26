import 'package:aqi_app/constants/color_constant.dart';
import 'package:aqi_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class LiveTrackingBottomPanel extends StatelessWidget {
  final int aqiValue; // Example: 73
  final String
  turnInstructionHtml; // Example: "Turn <b>left</b> onto <b>Main St</b>"
  final String routeDetail; // Example: "ETA: 12 mins · 3.2 km"
  final VoidCallback onStopPressed;
  final String mode;

  const LiveTrackingBottomPanel({
    super.key,
    required this.aqiValue,
    required this.turnInstructionHtml,
    required this.routeDetail,
    required this.onStopPressed,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final aqiLevel = _getAQILevel(aqiValue);
    final aqiColor = _getAQIColor(aqiValue);
    final aqiIconData = _getAQIIcon(aqiLevel);

    final turnIconData = _getTurnIcon(turnInstructionHtml);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(13),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ AQI Row
            Row(
              children: [
                Icon(aqiIconData, color: aqiColor),
                4.toSpace,
                Expanded(
                  child: Text(
                    "AQI: $aqiValue - $aqiLevel",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: aqiColor,
                    ),
                  ),
                ),
              ],
            ),
            4.toSpace,
            // ✅ Turn Info Row with HTML
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(turnIconData, color: Colors.blueAccent),
                4.toSpace,
                Expanded(
                  child: Html(
                    data: turnInstructionHtml.toString().trim(),
                    style: {
                      "*": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        color: COLOR_CONST.btnColorblk,
                      ),
                    },
                  ),
                ),
              ],
            ),
            4.toSpace,
            // ✅ Route Detail Row
            Row(
              children: [
                Icon(mainFABIcon(mode.toLowerCase()), color: Colors.pinkAccent),
                4.toSpace,
                Expanded(
                  child: Text(
                    routeDetail,
                    style: const TextStyle(
                      fontSize: 16,
                      color: COLOR_CONST.btnColorblk,
                    ),
                  ),
                ),
              ],
            ),
            10.toSpace,
            // ✅ Stop Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(
                  Icons.stop_circle_outlined,
                  color: COLOR_CONST.borderColor,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                label: const Text(
                  "Stop Tracking",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: COLOR_CONST.borderColor,
                  ),
                ),
                onPressed: onStopPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------
  // 🔑 AQI helpers (based on int)
  String _getAQILevel(int value) {
    if (value <= 50) return "Good";
    if (value <= 100) return "Moderate";
    if (value <= 150) return "Unhealthy for Sensitive";
    if (value <= 200) return "Unhealthy";
    if (value <= 300) return "Very Unhealthy";
    return "Hazardous";
  }

  Color _getAQIColor(int value) {
    if (value <= 50) return Colors.green;
    if (value <= 100) return Colors.yellow[700]!;
    if (value <= 150) return Colors.orange;
    if (value <= 200) return Colors.red;
    if (value <= 300) return Colors.purple;
    return Colors.brown;
  }

  mainFABIcon(selectedMode) {
    switch (selectedMode) {
      case 'driving':
        return (Icons.directions_car);
      case 'walking':
        return Icons.directions_walk;
      case 'bicycling':
        return Icons.directions_bike;
      default:
        return Icons.directions_car; // default icon when no mode is selected
    }
  }

  IconData _getAQIIcon(String level) {
    switch (level.toLowerCase()) {
      case "good":
        return Icons.sentiment_very_satisfied;
      case "moderate":
        return Icons.sentiment_satisfied;
      case "unhealthy for sensitive":
        return Icons.sentiment_dissatisfied;
      case "unhealthy":
      case "very unhealthy":
        return Icons.warning;
      case "hazardous":
        return Icons.dangerous;
      default:
        return Icons.cloud; // fallback
    }
  }

  // -------------------------------------------------
  // 🔑 Turn helpers (based on html instruction text)
  IconData _getTurnIcon(String html) {
    final text = html.toLowerCase();
    if (text.contains("left")) return Icons.turn_left;
    if (text.contains("right")) return Icons.turn_right;
    if (text.contains("u-turn")) return Icons.u_turn_left;
    if (text.contains("straight")) return Icons.straight;
    if (text.contains("slight left")) return Icons.turn_slight_left_outlined;
    if (text.contains("slight right")) return Icons.turn_slight_right_outlined;
    return Icons.navigation; // fallback generic
  }
}
