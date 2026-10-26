import 'package:aqi_app/configs/navigationservices.dart';
import 'package:aqi_app/presentation/common_blocs/profile/profile_bloc.dart';
import 'package:aqi_app/presentation/common_blocs/profile/profile_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'presentation/common_blocs/common_bloc.dart';
import 'presentation/common_blocs/application/bloc.dart';
import 'presentation/common_blocs/language/bloc.dart';
import 'presentation/common_blocs/auth/bloc.dart';

import 'configs/config.dart';
import 'utils/translate.dart';

class AppView extends StatefulWidget {
  @override
  _AppViewState createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  final _navigatorKey = NavigationService.navigatorKey;

  NavigatorState? get _navigator => _navigatorKey.currentState;

  @override
  void initState() {
    super.initState();
    callfunction();
  }

  callfunction() {
    Future.delayed(Duration(seconds: 3)).then((w) {
      CommonBloc.applicationBloc.add(SetupApplication());
    });
  }

  @override
  void dispose() {
    CommonBloc.dispose();
    super.dispose();
  }

  void onNavigate(String route) {
    _navigator!.pushNamed(route);
  }

  void onNavigateremoveuntil(String route) {
    _navigator!.pushNamedAndRemoveUntil(route, ModalRoute.withName('/'));
  }

  void loadData() {
    // Only load data when authenticated
    BlocProvider.of<ProfileBloc>(context).add(LoadProfile());
    // BlocProvider.of<CartBloc>(context).add(LoadCart());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ApplicationBloc, ApplicationState>(
      builder: (context, applicationState) {
        return BlocBuilder<LanguageBloc, LanguageState>(
          builder: (context, state) {
            return MaterialApp(
              navigatorKey: _navigatorKey,
              debugShowCheckedModeBanner: Application.debug,
              title: Application.title,
              theme: AppTheme.currentTheme,
              onGenerateRoute: AppRouter.generateRoute,
              initialRoute: AppRouter.SPLASH,
              locale: AppLanguage.defaultLanguage,
              supportedLocales: AppLanguage.supportLanguage,
              localizationsDelegates: [Translate.delegate],
              builder: (context, child) {
                return BlocListener<AuthenticationBloc, AuthenticationState>(
                  listener: (context, authState) {
                    if (applicationState is ApplicationCompleted) {
                      if (authState is Unauthenticated) {
                        // onNavigateremoveuntil(AppRouter.SPLASH);
                      } else if (authState is Uninitialized) {
                        // onNavigate(AppRouter.SPLASH);
                      } else if (authState is Authenticated) {
                        // loadData();
                        onNavigateremoveuntil(AppRouter.HOME);
                      }
                    } else {
                      onNavigateremoveuntil(AppRouter.SPLASH);
                    }
                  },
                  child: child,
                );
              },
            );
          },
        );
      },
    );
  }
}
