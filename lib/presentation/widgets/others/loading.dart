import 'package:aqi_app/constants/constants.dart';
import 'package:aqi_app/utils/utils.dart';
import 'package:flutter/material.dart';

class Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              COLOR_CONST.backgroundColor,
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingWithHideback extends StatelessWidget {
  final String? title;

  LoadingWithHideback({super.key, this.title});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.black26),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              4.toSpace,
              if (title != null)
                Text(
                  title!,
                  style: FONT_CONST.MEDIUM_PRIMARY_16.copyWith(
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
