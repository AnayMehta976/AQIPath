import 'package:aqi_app/presentation/screens/login/bloc/login_bloc.dart';
import 'package:aqi_app/presentation/screens/login/widgets/login_form.dart';
import 'package:aqi_app/presentation/screens/login/widgets/login_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../configs/config.dart';
import '../../../constants/constants.dart';
import '../../../utils/utils.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginBloc(),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: COLOR_CONST.secondaryBGColor,
          body: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(children: [LoginHeader(title: "Login"), LoginForm()]),
          ),
          bottomNavigationBar: _buildNoAccountText(context),
        ),
      ),
    );
  }

  _buildNoAccountText(context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: SizeConfig.defaultSize * 3),
        child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            Translate.of(context).translate('don\'t_have_an_account'),
            style: FONT_CONST.REGULAR_DEFAULT_20.copyWith(
              color: COLOR_CONST.darkShadeColor,
            ),
          ),
          SizedBox(width: 5),
          GestureDetector(
            onTap:
                () => Navigator.pushNamed(
                  context,
                  AppRouter.REGISTER,
                  // ModalRoute.withName('/'),
                ),
            child: Text(
              Translate.of(context).translate('register'),
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
