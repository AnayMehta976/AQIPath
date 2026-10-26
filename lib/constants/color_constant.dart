import 'dart:math';

import 'package:flutter/material.dart';

class COLOR_CONST {
  static const primaryColor = Color(0xFF3ac5c9);
  static const accentTintColor = Color(0xFF7b60c4);
  static const accentShadeColor = Color(0xFF58458c);
  static const darkShadeColor = Color(0xFF25164d);
  static const borderColor = Color(0xFFd3d1d1);
  static const backgroundColor = Color(0xFFA23030);
  static const cardShadowColor = Color(0xFFd3d1d1);
  static const dividerColor = Colors.black12;
  static const btnColorblk = Color(0xFF1A1528);
  static const btnColorOrng = Color(0xFFFF8811);
  static const txtcolorhint = Color(0xFFCF0F47);

  static const primaryGradientColor = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF25164d), Colors.white],
  );

  static const secondaryColor = Color(0xFF3ac5c9);
  static const secondaryBGColor = Color(0xFFEEEEEE);

  static const textColor = Colors.white;
  static const googleButtonColor = Color(0xFFFFF1F0);
  static const deleteButtonColor = Color(0xFFeb4d4b);
  static const googleButtonColorBorder = Color(0xFFF14336);
  static const facebookButtonColor = Color(0xFFF5F9FF);
  static const facebookButtonColorBorder = Color(0xFF3164CE);
  static const discountColor = Color(0xFFF17322);
  // 3. Configure HeatmapGradient (colors for different AQI levels)
  static final List<Color> aqiheatcolors = <Color>[
    Colors.green, // Good (AQI ~0-50)
    Colors.yellow.shade500, // Moderate (AQI ~51-100)
    Colors.orange.shade500, // Unhealthy for Sensitive Groups (AQI ~101-150)
    Colors.brown.shade500,
    Colors.purple.shade500, // Hazardous (AQI >300)
  ];

  static final List<Color> aqiHeatColors = <Color>[
    Colors.green, // Good (0–50)
    Colors.yellow.shade700, // Moderate (51–100)
    Colors.orange.shade700, // Unhealthy for Sensitive Groups (101–150)
    Colors.red.shade700, // Unhealthy (151–200)
    Colors.purple.shade700, // Very Unhealthy (201–300)
    Colors.brown, // Hazardous (301–500)
  ];

  // Define the intensity points corresponding to the color changes in the gradient.
  // These values should align with your _getAQIIntensity mapping.
  // Example: If max intensity is 10.0, then 0.2 means 20% of 10.0 = 2.0 intensity.
  static final List<double> startPoints = <double>[
    0.0, // Green starts at 0 intensity (Good)
    0.2, // Yellow starts (e.g., AQI 50, intensity 1.0)
    0.4, // Orange starts (e.g., AQI 100, intensity 2.0)
    0.6, // Red starts (e.g., AQI 150, intensity 3.0)
    0.8, // Purple starts (e.g., AQI 200, intensity 4.0)
    1.0, // Brown starts (e.g., AQI 300+, intensity 6.0+)
  ];
  static Color getAQIColor(int aqi) {
    if (aqi <= 50) return Colors.green; // Good
    if (aqi <= 100) return Colors.yellow; // Moderate
    if (aqi <= 150) return Colors.orange; // Unhealthy for Sensitive Groups
    if (aqi <= 200) return Colors.red; // Unhealthy
    if (aqi <= 300) return Colors.purple; // Very Unhealthy
    return Colors.brown; // Hazardous
  }

  static Color getRandomDarkColor() {
    final Random random = Random();
    while (true) {
      final color = Color.fromARGB(
        255,
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
      );

      // Perceptual brightness formula
      final brightness =
          (color.red * 0.299 + color.green * 0.587 + color.blue * 0.114);

      // Only accept dark colors (brightness <= 100)
      if (brightness <= 120) {
        return color;
      }
    }
  }

  ///Singleton factory
  static final COLOR_CONST _instance = COLOR_CONST._internal();

  factory COLOR_CONST() {
    return _instance;
  }

  COLOR_CONST._internal();
}

const mAnimationDuration = Duration(milliseconds: 200);
