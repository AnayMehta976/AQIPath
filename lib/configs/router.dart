import 'package:aqi_app/presentation/screens/home_page/home_screen.dart';
import 'package:aqi_app/presentation/screens/location_screen/direction_Aqi_Screen.dart';
import 'package:aqi_app/presentation/screens/login/login_screen.dart';
import 'package:aqi_app/presentation/screens/profile/profile_screen.dart';
import 'package:aqi_app/presentation/screens/register/register_screen.dart';
import 'package:aqi_app/presentation/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';

import '../presentation/widgets/Network_error_page.dart';

class AppRouter {
  static const String NetworkErrorScreen = '/network_error_screen';
  static const String SPLASH = '/splash';
  static const String LOGIN = '/login';
  // static const String INITIALIZE_INFO = '/initialize_info';
  static const String REGISTER = '/register';
  static const String FORGOT_PASSWORD = '/forgot_password';
  static const String HOME = '/home';
  static const String PROFILE = '/profile';
  static const String DETAIL_PRODUCT = '/detail_product';
  static const String DETAIL_IMAGE = '/detail_image';
  static const String FEEDBACK = '/feedback';
  static const String CART = '/cart';
  static const String MY_ORDERS = '/my_orders';
  static const String DETAIL_ORDER = '/detail_order';
  static const String DELIVERY_ADDRESS = '/delivery_address';
  static const String GOOGLE_MAP_PAGE = '/map';
  static const String CATEGORIES = '/categories';
  static const String SETTING = '/setting';
  static const String MESSAGES = '/messages';
  static const String SEARCH = '/search';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => SplashScreen());
      case NetworkErrorScreen:
        return MaterialPageRoute(builder: (_) => NetworkErrorPage());
      case SPLASH:
        return MaterialPageRoute(builder: (_) => SplashScreen());
      case LOGIN:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      // case FORGOT_PASSWORD:
      //   return MaterialPageRoute(builder: (_) => ForgotPasswordScreen(),);
      case REGISTER:
        // var initialUser = settings.arguments as UserModel;
        return MaterialPageRoute(builder: (_) => RegisterScreen());
      case HOME:
        return MaterialPageRoute(builder: (_) => HomeScreen());
      // case SETTING:
      //   return MaterialPageRoute(
      //     builder: (_) => SettingScreen(),
      //   );
      case PROFILE:
        var value = settings.arguments as ProfileScreen;
        return MaterialPageRoute(
          builder: (_) => ProfileScreen(clatlng: value.clatlng),
        );
      // case FEEDBACK:
      //   var product = settings.arguments as Product;
      //   return MaterialPageRoute(
      //       builder: (_) => FeedbacksScreen(product: product));
      case GOOGLE_MAP_PAGE:
        var arg = settings.arguments as GetRouteScreen;
        return MaterialPageRoute(builder: (_) => arg);
      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
        );
    }
  }

  ///Singleton factory
  static final AppRouter _instance = AppRouter._internal();

  factory AppRouter() {
    return _instance;
  }

  AppRouter._internal();
}
