import 'package:aqi_app/configs/size_config.dart';
import 'package:aqi_app/constants/color_constant.dart';
import 'package:aqi_app/constants/font_constant.dart';
import 'package:aqi_app/data/models/user_model.dart';
import 'package:aqi_app/presentation/common_blocs/auth/auth_bloc.dart';
import 'package:aqi_app/presentation/common_blocs/auth/auth_event.dart';
import 'package:aqi_app/presentation/screens/register/register/register_bloc.dart';
import 'package:aqi_app/presentation/screens/register/register/register_event.dart';
import 'package:aqi_app/presentation/screens/register/register/register_state.dart';
import 'package:aqi_app/presentation/widgets/buttons/default_button.dart';
import 'package:aqi_app/utils/dialog.dart';
import 'package:aqi_app/utils/toast.dart';
import 'package:aqi_app/utils/translate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class RegisterForm extends StatefulWidget {
  // final UserModel? intialUser;

  const RegisterForm({Key? key}) : super(key: key);
  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  late RegisterBloc registerBloc;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isShowPassword = false;
  bool isShowConfirmPassword = false;

  @override
  void initState() {
    registerBloc = BlocProvider.of<RegisterBloc>(context);
    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool get isPopulated =>
      emailController.text.isNotEmpty &&
      passwordController.text.isNotEmpty &&
      confirmPasswordController.text.isNotEmpty;

  bool isRegisterButtonEnabled() {
    return registerBloc.state.isFormValid &&
        !registerBloc.state.isSubmitting &&
        isPopulated;
  }

  void onRegister() {
    if (isRegisterButtonEnabled()) {
      UserModel newUser = UserModel(
        email: emailController.text,
        id: '',
        name: nameController.text,
        phoneNumber: numberController.text,
        passward: passwordController.text,
      );
      registerBloc.add(
        Submitted(
          newUser: newUser,
          password: passwordController.text,
          confirmPassword: confirmPasswordController.text,
        ),
      );
    } else {
      UtilToast.showMessageForUser(context, "Please provide correct data");
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegisterBloc, RegisterState>(
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

        /// Registering
        if (state.isSubmitting) {
          UtilDialog.showWaiting(context);
        }
      },
      child: BlocBuilder<RegisterBloc, RegisterState>(
        builder: (context, state) {
          return Container(
            margin: EdgeInsets.symmetric(
              horizontal: SizeConfig.defaultSize * 1.5,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.defaultPadding,
              vertical: SizeConfig.defaultSize * 0.1,
            ),
            child: Form(
              child: Column(
                children: <Widget>[
                  _buildNameInput(),
                  SizedBox(height: SizeConfig.defaultSize),
                  _buildnumberInput(),
                  SizedBox(height: SizeConfig.defaultSize),
                  _buildEmailInput(),
                  SizedBox(height: SizeConfig.defaultSize),
                  _buildPasswordInput(),
                  SizedBox(height: SizeConfig.defaultSize),
                  _buildConfirmPasswordInput(),
                  SizedBox(height: SizeConfig.defaultSize * 3),
                  _buildButtonRegister(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build content
  _buildEmailInput() {
    return TextFormField(
      controller: emailController,
      onChanged: (value) {
        registerBloc.add(EmailChanged(email: value));
      },
      validator: (_) {
        return !registerBloc.state.isEmailValid
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
        suffixIcon: Icon(Icons.email_outlined),
      ),
    );
  }

  _buildnumberInput() {
    return TextFormField(
      controller: numberController,
      onChanged: (value) {
        registerBloc.add(NumberChanged(number: value));
      },
      validator: (_) {
        return !registerBloc.state.isNumberValid ? "Enter valid number" : null;
      },
      style: FONT_CONST.REGULAR_PRIMARY.copyWith(
        color: COLOR_CONST.btnColorblk,
      ),
      autovalidateMode: AutovalidateMode.always,
      keyboardType: TextInputType.number,
      maxLength: 12,

      decoration: InputDecoration(
        hintStyle: FONT_CONST.REGULAR_PRIMARY.copyWith(
          color: COLOR_CONST.btnColorblk,
        ),
        counterText: '',
        labelStyle: FONT_CONST.REGULAR_PRIMARY.copyWith(
          color: COLOR_CONST.btnColorblk,
        ),

        hintText: Translate.of(context).translate('Mobile Number'),
        suffixIcon: Icon(Icons.phone_android_outlined),
      ),
    );
  }

  _buildNameInput() {
    return TextFormField(
      controller: nameController,
      onChanged: (value) {
        registerBloc.add(NameChanged(name: value));
      },
      validator: (_) {
        return !registerBloc.state.isNameValid ? "Enter valid name" : null;
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
        hintText: Translate.of(context).translate('User Name'),
        suffixIcon: Icon(Icons.person),
      ),
    );
  }

  _buildPasswordInput() {
    return TextFormField(
      controller: passwordController,
      onChanged: (value) {
        registerBloc.add(PasswordChanged(password: value));
      },
      validator: (_) {
        return !registerBloc.state.isPasswordValid
            ? Translate.of(context).translate('invalid_password')
            : null;
      },
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
        suffixIcon: IconButton(
          icon:
              isShowPassword
                  ? Icon(Icons.visibility_outlined)
                  : Icon(Icons.visibility_off_outlined),
          onPressed: () {
            setState(() {
              isShowPassword = !isShowPassword;
            });
          },
        ),
      ),
    );
  }

  _buildConfirmPasswordInput() {
    return TextFormField(
      controller: confirmPasswordController,
      onChanged: (value) {
        registerBloc.add(
          ConfirmPasswordChanged(
            password: passwordController.text,
            confirmPassword: value,
          ),
        );
      },
      validator: (_) {
        return !registerBloc.state.isConfirmPasswordValid
            ? Translate.of(context).translate('don\'t_match_password')
            : null;
      },
      autovalidateMode: AutovalidateMode.always,
      keyboardType: TextInputType.text,
      obscureText: !isShowConfirmPassword,
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
        hintText: Translate.of(context).translate('confirm_password'),
        suffixIcon: IconButton(
          icon:
              isShowConfirmPassword
                  ? Icon(Icons.visibility_outlined)
                  : Icon(Icons.visibility_off_outlined),
          onPressed: () {
            setState(() {
              isShowConfirmPassword = !isShowConfirmPassword;
            });
          },
        ),
      ),
    );
  }

  _buildButtonRegister() {
    return DefaultButton(
      child: Text(
        "Register NoW".toUpperCase(),
        style: FONT_CONST.BOLD_WHITE_18,
      ),
      onPressed: onRegister,
      backgroundColor: COLOR_CONST.backgroundColor,
    );
  }
}
