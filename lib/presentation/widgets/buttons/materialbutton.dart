import 'package:aqi_app/configs/size_config.dart';
import 'package:aqi_app/constants/constants.dart';
import 'package:flutter/material.dart';

class MaterialBtn extends StatefulWidget {
  String? assetimage;
  Color? textColor;
  final color;
  final text;
  final onpressed;
  MaterialBtn({
    super.key,
    this.color,
    this.text,
    this.onpressed,
    this.assetimage,
    this.textColor,
  });

  @override
  State<MaterialBtn> createState() => _MaterialBtnState();
}

class _MaterialBtnState extends State<MaterialBtn> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: MaterialButton(
        minWidth: SizeConfig.screenWidth,
        height: 47,
        color: widget.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        onPressed: () {
          widget.onpressed();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.assetimage != null)
              Image.asset(widget.assetimage!, width: 45),
            Text(
              widget.text,
              style: FONT_CONST.BOLD_DEFAULT_18.copyWith(
                color: widget.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
