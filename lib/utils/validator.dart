import 'dart:developer';

class UtilValidators {
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );
  static final RegExp _passwordRegExp = RegExp(r'^.{7,}$');

  static final RegExp commonMobileNumberRegExp = RegExp(r'^[6-9]\d{9}$');

  static isValidEmail(String email) {
    return _emailRegExp.hasMatch(email);
  }

  static isVietnamesePhoneNumber(String phoneNumber) {
    return commonMobileNumberRegExp.hasMatch(phoneNumber);
  }

  static isValidPassword(String password) {
    log("printpass: $password");
    return _passwordRegExp.hasMatch(password);
  }

  static isValidName(String name) {
    return name.isNotEmpty;
  }

  ///Singleton factory
  static final UtilValidators _instance = UtilValidators._internal();

  factory UtilValidators() {
    return _instance;
  }

  UtilValidators._internal();
}
