import 'package:flutter/material.dart';

import '../../../../configs/config.dart';
import '../../../../constants/constants.dart';

class LoginHeader extends StatelessWidget {
  final title;

  const LoginHeader({super.key, this.title});
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: TopCurveClipper(),
      child: Container(
        color: COLOR_CONST.backgroundColor,
        height: SizeConfig.screenHeight * 0.42,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Image.asset(
                IMAGECONST.SPLASH_1,
                width: SizeConfig.screenWidth,
                fit: BoxFit.fitWidth,
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: SizeConfig.defaultSize * 10,
                bottom: SizeConfig.defaultSize * 3,
                right: SizeConfig.defaultSize * 1.5,
                left: SizeConfig.defaultSize * 1.5,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    IMAGECONST.APP_LOGO,
                    width: SizeConfig.defaultSize * 20,
                    height: SizeConfig.defaultSize * 14,
                    fit: BoxFit.fill,
                  ),
                  // Text(
                  //   "Air Quality Index",
                  //   style: FONT_CONST.MEDIUM_WHITE_20.copyWith(
                  //     letterSpacing: 1.2,
                  //   ),
                  // ),
                  SizedBox(height: SizeConfig.defaultSize * 2.4),
                  Text(
                    title,
                    style: FONT_CONST.BOLD_DEFAULT_26.copyWith(
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height * 0.75);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height * 0.75,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
