import 'package:flutter/material.dart';

import '../../../../configs/config.dart';
import '../../../../constants/constants.dart';
import '../../../../utils/utils.dart';

class RegisterHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: SizeConfig.defaultSize * 15,
        bottom: SizeConfig.defaultSize * 3,
        right: SizeConfig.defaultSize * 1.5,
        left: SizeConfig.defaultSize * 1.5,
      ),
      color: COLOR_CONST.primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Translate.of(context).translate('register_now').toUpperCase(),
            style: FONT_CONST.BOLD_WHITE_32,
          ),
          Text(
            Translate.of(context).translate('it_so_quick_and_easy'),
            style: FONT_CONST.MEDIUM_WHITE_20,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
