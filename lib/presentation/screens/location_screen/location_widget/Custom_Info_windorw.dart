import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FuturisticInfoWindow extends StatelessWidget {
  final String type;
  final LatLng position;

  const FuturisticInfoWindow({
    super.key,
    required this.type,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return _glassContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.home, size: 55, color: Colors.white),
              ),
              Column(
                children: [
                  Text(
                    "🔍 $type",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text("📍 Lat: ${position.latitude.toStringAsFixed(5)}"),
                  Text("📍 Lng: ${position.longitude.toStringAsFixed(5)}"),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "🤖 AI Insight: This point might be optimal for energy efficiency and crowd flow based on previous movement data.",
            style: TextStyle(fontSize: 12, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _glassContainer({child}) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.cyanAccent.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}
