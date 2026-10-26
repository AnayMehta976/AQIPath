import 'package:aqi_app/presentation/common_blocs/application/application_bloc.dart';
import 'package:aqi_app/presentation/common_blocs/auth/auth_bloc.dart';
import 'package:aqi_app/presentation/common_blocs/language/language_bloc.dart';
import 'package:aqi_app/presentation/screens/home_page/bloc/home_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CommonBloc {
  /// Bloc
  static final applicationBloc = ApplicationBloc();
  static final authencationBloc = AuthenticationBloc();
  static final languageBloc = LanguageBloc();
  static final homePageBloc = HomeBloc();
  // static final profileBloc = ProfileBloc();

  static final List<BlocProvider> blocProviders = [
    BlocProvider<ApplicationBloc>(create: (context) => applicationBloc),
    BlocProvider<AuthenticationBloc>(create: (context) => authencationBloc),
    BlocProvider<LanguageBloc>(create: (context) => languageBloc),
    BlocProvider<HomeBloc>(create: (constent) => homePageBloc),
    // BlocProvider<ProfileBloc>(
    //   create: (context) => profileBloc,
    // ),
    // BlocProvider<LocationBloc>(create: (context) => locationBloc),
  ];

  /// Dispose
  static void dispose() {
    applicationBloc.close();
    authencationBloc.close();
    // cartBloc.close();
    // orderBloc.close();
    // profileBloc.close();
    languageBloc.close();
  }

  /// Singleton factory
  static final CommonBloc _instance = CommonBloc._internal();

  factory CommonBloc() {
    return _instance;
  }
  CommonBloc._internal();
}
