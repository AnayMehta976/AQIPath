import 'package:aqi_app/configs/size_config.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UtilToast {
  static void showMessageForUser(
    BuildContext context,
    String message, {
    ToastGravity? tostgravity,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: tostgravity ?? ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black.withOpacity(0.7),
      textColor: Colors.white,
      fontSize: SizeConfig.defaultSize * 1.6,
    );
  }
}
