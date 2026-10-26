import 'package:aqi_app/configs/size_config.dart';
import 'package:aqi_app/constants/color_constant.dart';
import 'package:aqi_app/constants/font_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static final ThemeData currentTheme = ThemeData(
    scaffoldBackgroundColor: COLOR_CONST.backgroundColor,
    fontFamily: "Roboto",
    appBarTheme: _appBarTheme,
    textTheme: _textTheme,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: COLOR_CONST.primaryColor,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    inputDecorationTheme: _inputDecorationThem,
  );

  static final _appBarTheme = AppBarTheme(
    color: Colors.white,
    shadowColor: COLOR_CONST.cardShadowColor,
    elevation: 0.4,
    iconTheme: IconThemeData(color: COLOR_CONST.textColor),
    actionsIconTheme: IconThemeData(color: COLOR_CONST.textColor),
    centerTitle: true,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    toolbarTextStyle:
        TextTheme(titleLarge: FONT_CONST.BOLD_DEFAULT_20).bodyMedium,
    titleTextStyle:
        TextTheme(titleLarge: FONT_CONST.BOLD_DEFAULT_20).titleLarge,
  );

  static final _textTheme = TextTheme(
    bodyLarge: TextStyle(color: COLOR_CONST.textColor),
    bodyMedium: TextStyle(color: COLOR_CONST.textColor),
  );

  static final _inputDecorationThem = InputDecorationTheme(
    contentPadding:
        EdgeInsets.symmetric(horizontal: SizeConfig.defaultPadding * 1.2),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(5)),
      borderSide: BorderSide(color: COLOR_CONST.textColor),
    ),
    hintStyle: FONT_CONST.REGULAR_DEFAULT_20,
  );

  /// Singleton factory
  static final AppTheme _instance = AppTheme._internal();

  factory AppTheme() {
    return _instance;
  }

  AppTheme._internal();
}
