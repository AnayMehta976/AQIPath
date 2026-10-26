import 'dart:io';

import 'package:aqi_app/constants/font_constant.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog extends StatelessWidget {
  final String changelog;
  final String version;
  final String buildNumber;
  final Function callbackfun;
  final String pkgName;
  final bool isMandotory;

  const UpdateDialog({
    Key? key,
    required this.changelog,
    required this.version,
    required this.buildNumber,
    required this.callbackfun,
    required this.pkgName,
    required this.isMandotory,
  }) : super(key: key);
  Future<void> _launchStore() async {
    String url;

    if (Platform.isIOS) {
      // Redirect to iOS App Store
      url = 'itms-apps://itunes.apple.com/app/id$pkgName';
    } else {
      // Redirect to Android Play Store
      url = 'https://play.google.com/store/apps/details?id=$pkgName';
    }

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Fluttertoast.showToast(msg: 'Could not open store');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 16,
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'New Update Available',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 10),
            // Changelog
            Text(
              'Changelog:\n$changelog',
              style: TextStyle(fontSize: 14, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            // Version & Build Number
            Text(
              'Version: $version (Build: $buildNumber)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 20),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _launchStore().then((e) => callbackfun(1));
                    // You can handle the upgrade action here
                    Fluttertoast.showToast(msg: 'Upgrading...');
                    // Navigator.pop(context); // Close the dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: Text(
                    'Upgrade',
                    style: FONT_CONST.BOLD_DEFAULT.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                if (!isMandotory)
                  TextButton(
                    onPressed: () {
                      callbackfun(0);
                      // Navigator.pop(context); // Close the dialog
                    },
                    child: Text('Later'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
