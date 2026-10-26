import 'package:aqi_app/configs/size_config.dart';
import 'package:aqi_app/constants/color_constant.dart';
import 'package:flutter/material.dart';

class DefaultButton extends StatelessWidget {
  final Function() onPressed;
  final Widget child;
  final Color backgroundColor;

  const DefaultButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor = COLOR_CONST.primaryColor,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: SizeConfig.defaultSize * 5,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(backgroundColor: backgroundColor),
        child: child,
      ),
    );
  }
}
