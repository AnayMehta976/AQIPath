import 'dart:io';
import 'package:aqi_app/presentation/common_blocs/application/bloc.dart';

import 'package:aqi_app/presentation/common_blocs/common_bloc.dart';
import 'package:aqi_app/utils/AppUpdateDialog.dart';
import 'package:flutter/material.dart';
import 'package:aqi_app/configs/router.dart';
import 'package:aqi_app/configs/size_config.dart';
import 'package:aqi_app/constants/color_constant.dart';
import 'package:aqi_app/constants/font_constant.dart';
import 'package:aqi_app/constants/image_constant.dart' show IMAGECONST;
import 'package:aqi_app/presentation/widgets/buttons/materialbutton.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../common_blocs/auth/bloc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  late Animation<Offset> _slide;

  bool _animationDone = false;
  bool _showButtons = false;

  late AnimationController _textController;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    // Start animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
      ),
    );

    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));
    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          /// Authentication begin check
        
          _animationDone = true;
        });

        _textController.forward().then((_) {});
        // Delay showing buttons
      }
    });
  }

  void onNavigate(String route) {
    Navigator.pushNamed(context, route);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ApplicationBloc, ApplicationState>(
      listener: (context, applicationState) {
        if (applicationState is ApplicationUpdateDialog) {
          if (mounted) {
            setState(() {});
          }
          showUpdateDialog(
            context,
            Platform.isAndroid
                ? applicationState.systemConfig.changeLog!
                : applicationState.systemConfig.changeLogIos!,
            Platform.isAndroid
                ? applicationState.systemConfig.versionName!
                : applicationState.systemConfig.versionNameIos!,
            Platform.isAndroid
                ? applicationState.systemConfig.versionName!
                : applicationState.systemConfig.versionNameIos!,
            applicationState.pkgName,
            applicationState.systemConfig.ismandotory!,
          );
        }
      },
      builder: (context, applicationState) {
        return BlocListener<AuthenticationBloc, AuthenticationState>(
          listener: (context, authState) {
            if (applicationState is ApplicationCompleted) {
              if (authState is Unauthenticated) {
                // onNavigateremoveuntil(AppRouter.SPLASH);
                _showButtons = true;
                setState(() {});
              } else if (authState is Uninitialized) {
                // onNavigate(AppRouter.SPLASH);
              } else if (authState is Authenticated) {
                // loadData();

                // onNavigateremoveuntil(AppRouter.HOME);
              }
            } else {
              onNavigate(AppRouter.SPLASH);
            }
          },
          child: Scaffold(
            backgroundColor: COLOR_CONST.backgroundColor,
            body: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: Image.asset(
                    IMAGECONST.SPLASH_1,
                    width: SizeConfig.screenWidth,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.defaultSize * 4,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,

                    children: [
                      SizedBox(height: SizeConfig.screenHeight * 0.18),
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (_, __) {
                          return Opacity(
                            opacity: _opacity.value,
                            child: Transform.scale(
                              scale: _scale.value,
                              child: SlideTransition(
                                position: _slide,
                                child: Image.asset(
                                  IMAGECONST.APP_LOGO,
                                  width: SizeConfig.defaultSize * 28,
                                  height: SizeConfig.defaultSize * 18.5,
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (_animationDone) ...[
                        // Animated Welcome Text
                        FadeTransition(
                          opacity: _textOpacity,
                          child: Column(
                            children: [
                              SizedBox(height: SizeConfig.defaultSize * 5),
                              Padding(
                                padding: const EdgeInsets.only(right: 40),
                                child: Text(
                                  "WELCOME TO AQI PATH",
                                  style: FONT_CONST.BOLD_DEFAULT_28.copyWith(
                                    height: 1.1,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              SizedBox(height: SizeConfig.defaultSize * 3),
                              Text(
                                "Track real-time air quality, get alerts, and stay safe with personalized tips based on your location.",
                                style: FONT_CONST.REGULAR_DEFAULT,
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (_showButtons) ...[
                        const Spacer(),
                        MaterialBtn(
                          color: COLOR_CONST.btnColorOrng,
                          text: "Login",
                          onpressed: () => onNavigate(AppRouter.LOGIN),
                        ),
                        SizedBox(height: SizeConfig.defaultSize * 2),
                        // MateialBtn(
                        //   color: COLOR_CONST.btnColorblk,
                        //   text: "Register Here",
                        //   onpressed: () => onNavigate(AppRouter.REGISTER),
                        // ),
                        SizedBox(height: SizeConfig.defaultSize * 4),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showUpdateDialog(
    BuildContext context,
    String changelog,
    String version,
    String buildNumber,
    String pkgName,
    bool isMandotiry,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) {
        return UpdateDialog(
          changelog: changelog,
          version: version,
          buildNumber: buildNumber,
          isMandotory: isMandotiry,
          callbackfun: (i) {
            if (i == 0) {
              CommonBloc.applicationBloc.add(SetuplaterApplication());
              
            } else {}
          },
          pkgName: pkgName,
        );
      },
    );
  }
}

  // static Future<SystemConfig?> getSystemConfig() async {
  //   final String? lastFetch = LocalPref.getString(SavedKey.LASTSYNC);
  //   final DateTime now = DateTime.now();

  //   if (lastFetch != null) {
  //     final lastDate = DateTime.tryParse(lastFetch);
  //     if (lastDate != null && now.difference(lastDate).inMinutes < 60) {
  //       final cachedData = LocalPref.getString(SavedKey.CONFIG_DATA);
  //       if (cachedData != null) {
  //         return SystemConfig.fromJson(jsonDecode(cachedData));
  //       }
  //     }
  //   }

  //   final doc =
  //       await FirebaseFirestore.instance
  //           .collection("SystemConfig")
  //           .doc("V1fzgfJhDItQRxDbCV6x")
  //           .get();

  //   if (doc.exists && doc.data() != null) {
  //     final configData = SystemConfig.fromJson(doc.data()!);

  //     LocalPref.setString(
  //       SavedKey.CONFIG_DATA,
  //       jsonEncode(configData.toJson()),
  //     );
  //     LocalPref.setString(SavedKey.LASTSYNC, now.toIso8601String());

  //     return configData;
  //   }

  //   return null;
  // }