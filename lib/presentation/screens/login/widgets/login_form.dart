import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../configs/size_config.dart';
import '../../../../constants/constants.dart';
import '../../../../utils/utils.dart';

import '../../../common_blocs/auth/bloc.dart';
import '../../../widgets/buttons/materialbutton.dart';
import '../../../widgets/custom_widgets.dart';
import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';

class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  late LoginBloc loginBloc;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isShowPassword = false;

  @override
  void initState() {
    loginBloc = BlocProvider.of<LoginBloc>(context);

    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool get isPopulated =>
      emailController.text.isNotEmpty && passwordController.text.isNotEmpty;

  bool isLoginButtonEnabled() {
    return loginBloc.state.isFormValid &&
        !loginBloc.state.isSubmitting &&
        isPopulated;
  }

  void onLogin() {
    if (isLoginButtonEnabled()) {
      loginBloc.add(
        LoginWithCredential(
          email: emailController.text,
          password: passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        /// Success
        if (state.isSuccess) {
          UtilDialog.hideWaiting(context);
          BlocProvider.of<AuthenticationBloc>(context).add(LoggedIn());
        }

        /// Failure
        if (state.isFailure) {
          UtilDialog.hideWaiting(context);
          UtilDialog.showInformation(context, content: state.message);
        }

        /// Logging
        if (state.isSubmitting) {
          UtilDialog.showWaiting(context);
        }
      },
      child: BlocBuilder<LoginBloc, LoginState>(
        builder: (context, state) {
          return Container(
            margin: EdgeInsets.symmetric(
              horizontal: SizeConfig.defaultSize * 1.5,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.defaultPadding,
              vertical: SizeConfig.defaultSize * 1,
            ),
            color: COLOR_CONST.secondaryBGColor,
            child: Form(
              child: Column(
                children: <Widget>[
                  _buildTextFieldUsername(),
                  SizedBox(height: SizeConfig.defaultSize),
                  _buildTextFieldPassword(),
                  SizedBox(height: SizeConfig.defaultSize * 1),
                  // Align(
                  //   alignment: Alignment.centerRight,
                  //   child: Text(
                  //     Translate.of(context).translate('forgot_password'),
                  //     style: FONT_CONST.REGULAR_DEFAULT_18.copyWith(
                  //       color: COLOR_CONST.btnColorblk,
                  //     ),
                  //   ),
                  // ),
                  SizedBox(height: SizeConfig.defaultSize * 3),
                  _buildButtonLogin(state),
                  SizedBox(height: SizeConfig.defaultSize * 2),
                  _buildTextOr(),
                  SizedBox(height: SizeConfig.defaultSize * 2),
                  if (Platform.isIOS)
                    SignInWithAppleButton(
                      onPressed: () {
                        if (Platform.isIOS) {
                          loginBloc.add(LoginWithAppleSign());
                        } else {
                          loginBloc.add(LoginWithGoogleSign());
                        }
                      },
                    ),
                  if (Platform.isAndroid)
                    MaterialBtn(
                      textColor: COLOR_CONST.btnColorblk,
                      color: COLOR_CONST.googleButtonColor,
                      text: "Continue With Google",
                      assetimage: IMAGECONST.GOOGLE_LOGO,
                      onpressed: () {
                        loginBloc.add(LoginWithGoogleSign());
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build content
  _buildTextFieldUsername() {
    return TextFormField(
      textInputAction: TextInputAction.next,
      controller: emailController,
      onChanged: (value) {
        loginBloc.add(EmailChanged(email: value));
      },
      validator: (_) {
        return !loginBloc.state.isEmailValid
            ? Translate.of(context).translate('invalid_email')
            : null;
      },
      style: FONT_CONST.REGULAR_PRIMARY.copyWith(
        color: COLOR_CONST.btnColorblk,
      ),
      autovalidateMode: AutovalidateMode.always,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintStyle: FONT_CONST.REGULAR_PRIMARY.copyWith(
          color: COLOR_CONST.btnColorblk,
        ),

        labelStyle: FONT_CONST.REGULAR_PRIMARY.copyWith(
          color: COLOR_CONST.btnColorblk,
        ),
        hintText: Translate.of(context).translate('email'),
        prefixIcon: Icon(Icons.email_outlined),
      ),
    );
  }

  _buildTextFieldPassword() {
    return TextFormField(
      controller: passwordController,
      textInputAction: TextInputAction.go,
      onChanged: (value) {
        loginBloc.add(PasswordChanged(password: value));
      },
      validator: (_) {
        return !loginBloc.state.isPasswordValid
            ? Translate.of(context).translate('invalid_password')
            : null;
      },
      onEditingComplete: onLogin,
      autovalidateMode: AutovalidateMode.always,
      keyboardType: TextInputType.text,
      obscureText: !isShowPassword,
      style: FONT_CONST.REGULAR_PRIMARY.copyWith(
        color: COLOR_CONST.btnColorblk,
      ),
      decoration: InputDecoration(
        hintStyle: FONT_CONST.REGULAR_PRIMARY.copyWith(
          color: COLOR_CONST.btnColorblk,
        ),
        labelStyle: FONT_CONST.REGULAR_PRIMARY.copyWith(
          color: COLOR_CONST.btnColorblk,
        ),
        hintText: Translate.of(context).translate('password'),
        prefixIcon: Icon(Icons.lock),
        suffixIcon: IconButton(
          icon:
              isShowPassword
                  ? Icon(Icons.visibility_outlined)
                  : Icon(Icons.visibility_off_outlined),
          onPressed: () {
            setState(() => isShowPassword = !isShowPassword);
          },
        ),
      ),
    );
  }

  _buildButtonLogin(LoginState state) {
    return DefaultButton(
      child: Text(
        Translate.of(context).translate('login').toUpperCase(),
        style: FONT_CONST.BOLD_WHITE_18,
      ),
      onPressed: onLogin,
      backgroundColor: COLOR_CONST.backgroundColor,
    );
  }

  _buildTextOr() {
    return Stack(
      children: <Widget>[
        Align(
          alignment: Alignment.center,
          child: Divider(color: Colors.black26),
        ),
        Align(
          alignment: Alignment.center,
          child: Container(
            color: COLOR_CONST.backgroundColor,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.defaultSize,
                vertical: 0,
              ),
              child: Text(Translate.of(context).translate('or')),
            ),
          ),
        ),
      ],
    );
  }
}
