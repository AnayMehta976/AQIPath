import 'dart:io';

import 'package:aqi_app/configs/navigationservices.dart';
import 'package:aqi_app/constants/color_constant.dart';
import 'package:aqi_app/constants/font_constant.dart';
import 'package:aqi_app/data/models/info_model.dart';
import 'package:aqi_app/presentation/widgets/others/loading.dart';
import 'package:aqi_app/utils/translate.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';

class UtilDialog {
  static showInformation(
    BuildContext context, {
    String? title,
    String? content,
    Function()? onClose,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title ?? Translate.of(context).translate("message_for_you"),
            style: FONT_CONST.MEDIUM_PRIMARY_20.copyWith(
              color: COLOR_CONST.backgroundColor,
            ),
          ),
          content: Text(
            content!,
            style: FONT_CONST.MEDIUM_PRIMARY_16.copyWith(
              color: COLOR_CONST.btnColorblk,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: onClose ?? () => Navigator.of(context).pop(),
              child: Text(
                Translate.of(context).translate("close"),
                style: FONT_CONST.MEDIUM_PRIMARY_18.copyWith(
                  color: COLOR_CONST.darkShadeColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static showRetry({
    String? title,
    required String content,
    Function()? onClose,
    bool? isdeny,
  }) {
    final context = NavigationService.navigatorKey.currentContext!;
    final localTitle =
        title ?? Translate.of(context).translate("message_for_you");

    if (Platform.isIOS) {
      // 🍏 Cupertino Dialog for iOS
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: Text(
                localTitle,
                style: FONT_CONST.MEDIUM_PRIMARY_20.copyWith(
                  color: COLOR_CONST.backgroundColor,
                ),
              ),
              content: Text(
                content,
                style: FONT_CONST.MEDIUM_PRIMARY_16.copyWith(
                  color: COLOR_CONST.btnColorblk,
                ),
              ),
              actions: <Widget>[
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () {
                    Navigator.pop(context);
                    onClose?.call();
                  },
                  child: Text(
                    Translate.of(context).translate("Retry"),
                    style: FONT_CONST.MEDIUM_PRIMARY_18.copyWith(
                      color: COLOR_CONST.darkShadeColor,
                    ),
                  ),
                ),
                if (isdeny ?? false)
                  CupertinoDialogAction(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      Translate.of(context).translate("NO"),
                      style: FONT_CONST.MEDIUM_PRIMARY_18.copyWith(
                        color: COLOR_CONST.darkShadeColor,
                      ),
                    ),
                  ),
              ],
            ),
      );
    } else {
      // 🤖 Material AlertDialog for Android
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(
                localTitle,
                style: FONT_CONST.MEDIUM_PRIMARY_20.copyWith(
                  color: COLOR_CONST.backgroundColor,
                ),
              ),
              content: Text(
                content,
                style: FONT_CONST.MEDIUM_PRIMARY_16.copyWith(
                  color: COLOR_CONST.btnColorblk,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onClose?.call();
                  },
                  child: Text(
                    Translate.of(context).translate("Retry"),
                    style: FONT_CONST.MEDIUM_PRIMARY_18.copyWith(
                      color: COLOR_CONST.darkShadeColor,
                    ),
                  ),
                ),
                if (isdeny ?? false)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      Translate.of(context).translate("NO"),
                      style: FONT_CONST.MEDIUM_PRIMARY_18.copyWith(
                        color: COLOR_CONST.darkShadeColor,
                      ),
                    ),
                  ),
              ],
            ),
      );
    }
  }

  static Future<bool> showRetry2({
    String? title,
    String? content,
    bool isDeny = false,
    Future<bool> Function()? onClose, // now must return bool
  }) async {
    var context = NavigationService.navigatorKey.currentContext!;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title ?? Translate.of(context).translate("message_for_you"),
            style: FONT_CONST.MEDIUM_PRIMARY_20.copyWith(
              color: COLOR_CONST.backgroundColor,
            ),
          ),
          content: Text(
            content ?? "",
            style: FONT_CONST.MEDIUM_PRIMARY_16.copyWith(
              color: COLOR_CONST.btnColorblk,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                bool value = await (onClose?.call() ?? Future.value(true));
                Navigator.pop(context, value); // ✅ return permission result
              },
              child: Text(
                Translate.of(context).translate("Retry"),
                style: FONT_CONST.MEDIUM_PRIMARY_18.copyWith(
                  color: COLOR_CONST.darkShadeColor,
                ),
              ),
            ),
            if (isDeny)
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  Translate.of(context).translate("NO"),
                  style: FONT_CONST.MEDIUM_PRIMARY_18.copyWith(
                    color: COLOR_CONST.darkShadeColor,
                  ),
                ),
              ),
          ],
        );
      },
    );

    return result ?? false; // default false
  }

  static showLogoutWarning(
    BuildContext context, {
    String? title,
    String? content,
    Function()? onClose,
  }) {
    if (Platform.isIOS) {
      // ✅ Cupertino Alert for iOS
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text(
              title ?? Translate.of(context).translate("message_for_you"),
            ),
            content: Text(content ?? ''),
            actions: <Widget>[
              CupertinoDialogAction(
                onPressed: onClose,
                isDestructiveAction: true,
                child: Text(Translate.of(context).translate("Logout")),
              ),
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(Translate.of(context).translate("No")),
              ),
            ],
          );
        },
      );
    } else {
      // ✅ Material Alert for Android
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              title ?? Translate.of(context).translate("message_for_you"),
              style: FONT_CONST.MEDIUM_PRIMARY_20.copyWith(
                color: COLOR_CONST.backgroundColor,
              ),
            ),
            content: Text(
              content ?? '',
              style: FONT_CONST.MEDIUM_PRIMARY_16.copyWith(
                color: COLOR_CONST.btnColorblk,
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: onClose,
                child: Text(
                  Translate.of(context).translate("Logout"),
                  style: FONT_CONST.MEDIUM_PRIMARY_18.copyWith(
                    color: COLOR_CONST.darkShadeColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  Translate.of(context).translate("No"),
                  style: FONT_CONST.MEDIUM_PRIMARY_18.copyWith(
                    color: COLOR_CONST.secondaryColor,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> showExitConfirmationDialog(
    BuildContext context,
    VoidCallback onYesPressed,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Are you sure you want to return back?",
            style: FONT_CONST.BOLD_DEFAULT_20.copyWith(color: Colors.black),
          ),
          content: Text(
            "Currently live tracking is ongoing. If you really want to exit, please confirm.",
            style: FONT_CONST.REGULAR_DEFAULT_16.copyWith(
              color: Colors.black54,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // No action
              child: const Text("No"),
            ),
            ElevatedButton(
              style: TextButton.styleFrom(
                backgroundColor: COLOR_CONST.backgroundColor,
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                onYesPressed(); // Call the passed function
              },
              child: Text(
                "Yes",
                style: FONT_CONST.REGULAR_WHITE_18.copyWith(
                  color: COLOR_CONST.borderColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static showWaiting(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: Container(
            height: 150,
            alignment: Alignment.center,
            child: Loading(),
          ),
        );
      },
    );
  }

  static hideWaiting(BuildContext context) {
    Navigator.pop(context);
  }

  static Future<bool?> showConfirmation(
    BuildContext context, {
    String? title,
    required Widget content,
    String confirmButtonText = "Yes",
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title ?? Translate.of(context).translate("message_for_you"),
            style: FONT_CONST.MEDIUM_PRIMARY_24.copyWith(
              color: COLOR_CONST.backgroundColor,
            ),
          ),
          content: content,
          actions: <Widget>[
            TextButton(
              child: Text(
                Translate.of(context).translate("close"),
                style: FONT_CONST.MEDIUM_PRIMARY_18.copyWith(
                  color: COLOR_CONST.deleteButtonColor,
                ),
              ),
              onPressed: () => Navigator.pop(context, false),
            ),
            TextButton(
              child: Text(
                confirmButtonText,
                style: FONT_CONST.REGULAR_WHITE_18.copyWith(
                  color: COLOR_CONST.darkShadeColor,
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                backgroundColor: COLOR_CONST.primaryColor,
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showCoolAQIInfoDialog(BuildContext context) async {
    return showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 30),
          backgroundColor: Colors.white, // Dark background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            "🌫️ What's in the Air?",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AQIInfoText(
                  title: "🔸 PM2.5 (Fine Dust)",
                  description:
                      "Tiny particles that reach deep into your lungs. They reduce oxygen flow and may trigger asthma and heart problems.",
                ),
                AQIInfoText(
                  title: "🔹 PM10 (Dust Particles)",
                  description:
                      "Larger particles from roads and construction. They irritate the nose, throat, and affect breathing.",
                ),
                AQIInfoText(
                  title: "🟥 CO (Carbon Monoxide)",
                  description:
                      "Invisible and dangerous. It blocks oxygen in your blood, making you feel dizzy or tired.",
                ),
                AQIInfoText(
                  title: "🟨 NO₂ (Nitrogen Dioxide)",
                  description:
                      "Comes from vehicle exhaust. It lowers your lung function and harms kids more.",
                ),
                AQIInfoText(
                  title: "🟧 SO₂ (Sulfur Dioxide)",
                  description:
                      "From burning coal or oil. It irritates the lungs and narrows airways.",
                ),
                AQIInfoText(
                  title: "🟦 O₃ (Ozone - Ground Level)",
                  description:
                      "It’s not the good ozone. This causes coughing, chest pain, and makes breathing hard.",
                ),
                SizedBox(height: 12),
                Text(
                  "💡 High AQI = Poor oxygen absorption. Breathe safe, stay aware!",
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  // A method to show the custom bottom sheet and handle the returned value.
  static showRangeBottomSheet(
    BuildContext context, {
    required void Function(int value) onRangeSelected,
  }) async {
    // A variable to hold the current value of the slider.
    double selectedRange = 1.0;

    // showModalBottomSheet returns the value passed to Navigator.pop
    final returnedValue = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        // StatefulBuilder is used here to allow the bottom sheet's content to rebuild
        // and update the slider value without rebuilding the entire page.
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20.0,
                20.0,
                20.0,
                20.0 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Please tell me range to find your path!",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: COLOR_CONST.accentShadeColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "To provide the most relevant routes for your journey, please select your preferred search radius below.",
                    style: FONT_CONST.REGULAR.copyWith(
                      color: COLOR_CONST.btnColorblk.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Slider(
                          value: selectedRange,
                          min: 1.0,
                          max: 5.0,
                          divisions: 4, // Creates integer steps from 1 to 8.
                          label: '${selectedRange.round()} km',
                          onChanged: (double value) {
                            // Update the selectedRange and rebuild the dialog's content.
                            setState(() {
                              selectedRange = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${selectedRange.round()} km',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          // The 'Cancel' button closes the dialog without returning a value.
                          Navigator.of(context).pop();
                        },
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          // The 'OK' button closes the dialog and returns the selected range.
                          Navigator.of(context).pop(selectedRange.round());
                        },
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    // Check if a value was returned and call the callback function.
    if (returnedValue != null) {
      onRangeSelected(returnedValue);
    }
  }

  static void showInfoDialogAqiRoute({
    required BuildContext context,
    required String title,
    required List<InfoItem> items,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                children:
                    items.map((item) {
                      return Card(
                        elevation: 0.5,
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        child: ListTile(
                          leading: Icon(
                            item.icon,
                            color: Colors.blue,
                            size: 35,
                          ),
                          title: Text(
                            item.title,
                            style: FONT_CONST.BOLD_DEFAULT_20.copyWith(
                              color: Colors.black45,
                            ),
                          ),
                          subtitle: Text(
                            item.description,
                            style: FONT_CONST.REGULAR_DEFAULT_16.copyWith(
                              color: Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }
}

class AQIInfoText extends StatelessWidget {
  final String title;
  final String description;

  const AQIInfoText({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.lightBlueAccent,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(color: Colors.black87, fontSize: 13.5),
          ),
        ],
      ),
    );
  }
}
