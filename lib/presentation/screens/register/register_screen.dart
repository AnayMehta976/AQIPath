import 'package:aqi_app/configs/router.dart';
import 'package:aqi_app/configs/size_config.dart';
import 'package:aqi_app/constants/color_constant.dart';
import 'package:aqi_app/constants/font_constant.dart';
import 'package:aqi_app/presentation/screens/login/widgets/login_header.dart';
import 'package:aqi_app/presentation/screens/register/register/register_bloc.dart';
import 'package:aqi_app/presentation/screens/register/widgets/register_form.dart';
import 'package:aqi_app/utils/translate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegisterBloc(),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: COLOR_CONST.secondaryBGColor,
          body: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              children: [
                LoginHeader(title: "Sign-Up"), //RegisterHeader(),
                RegisterForm(),
              ],
            ),
          ),
          bottomNavigationBar: _buildHaveAccountText(context),
        ),
      ),
    );
  }

  _buildHaveAccountText(context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: SizeConfig.defaultSize * 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              Translate.of(context).translate('already_have_an_account'),
              style: FONT_CONST.REGULAR_DEFAULT_20.copyWith(
                color: COLOR_CONST.btnColorblk,
              ),
            ),
            SizedBox(width: 5),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                Translate.of(context).translate('login'),
                style: FONT_CONST.BOLD_PRIMARY_20.copyWith(
                  color: COLOR_CONST.backgroundColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
