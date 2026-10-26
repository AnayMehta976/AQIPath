import 'package:aqi_app/utils/utils.dart';
import 'package:flutter/material.dart';

class AllowLocationPage extends StatelessWidget {
  final VoidCallback onAllow;
  final VoidCallback onSkip;
  final String? errormessage;

  const AllowLocationPage({
    super.key,
    required this.onAllow,
    required this.onSkip,
    this.errormessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(),
                // Icon illustration
                const Icon(
                  Icons.location_on_rounded,
                  color: Colors.redAccent,
                  size: 100,
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  "Allow your location",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Subtitle
                const Text(
                  "We will need your location to give you better experience.",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Please allow location permission from app settings to \"always\" and \"allow while using\" the app.",
                  style: TextStyle(fontSize: 14, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Text(
                  errormessage ?? "",
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),

                40.toSpace,
                // Allow button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: onAllow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      "Sure, I'd like that",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Not now button
                TextButton(
                  onPressed: onSkip,
                  child: const Text(
                    "Not now",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
                Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
