import 'dart:io';

import 'package:flutter/material.dart';

showLocationPermissionDialog(
  BuildContext context, {
  Future<void> Function()? onAllow,
  VoidCallback? onSkip,
}) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.black.withOpacity(0.9),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, color: Colors.cyanAccent, size: 60),
                  const SizedBox(height: 20),
                  Text(
                    "Enable Location Access 🌍",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "To provide hyper-accurate tracking and\n"
                            "seamless background insights 🚀,\n"
                            "please allow *All-the-time* location access.\n\n"
                            "🔹 Smarter AI recommendations\n"
                            "🔹 Real-time background updates\n"
                            "🔹 Precision up to 5 meters\n"
                            "🔹 Go To -> Aqi Path Setting App -> Permission -> location -> tap on " +
                        (Platform.isAndroid ? "All-the-time" : "Always"),
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: onAllow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            "Sure, Proceed",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Not now button
                      TextButton(
                        onPressed: onSkip,
                        child: const Text(
                          "Go With current Permission",
                          style: TextStyle(fontSize: 16, color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ) ??
      false;
}
