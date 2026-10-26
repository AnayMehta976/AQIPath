import 'package:aqi_app/configs/router.dart';
import 'package:aqi_app/configs/size_config.dart';
import 'package:aqi_app/constants/constants.dart';
import 'package:aqi_app/data/repository/MapScreen_repositry/MapScreen_repositary.dart';
import 'package:aqi_app/presentation/common_blocs/common_bloc.dart';
import 'package:aqi_app/presentation/screens/home_page/widgets/HealthRecommandationDialog.dart';
import 'package:aqi_app/presentation/screens/location_screen/direction_Aqi_Screen.dart';
import 'package:aqi_app/presentation/screens/check_aqi_screen/check_Aqi_circle.dart';
import 'package:aqi_app/presentation/screens/location_screen/location_widget/FloatingActionMultiOption.dart';
import 'package:aqi_app/presentation/screens/profile/profile_screen.dart';
import 'package:aqi_app/utils/comman_widget/location_retry.dart';
import 'package:aqi_app/utils/toast.dart';
import 'package:aqi_app/utils/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gauge_indicator/gauge_indicator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../../widgets/others/loading.dart';
import '../../auto_aqiroute_screen/aqi_route_map.dart';
import '../bloc/bloc.dart';

class AqiScreen extends StatelessWidget {
  AqiScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      bloc: CommonBloc.homePageBloc..add(LoadHome()),
      builder: (context, homeState) {
        if (homeState is HomeLoadFailure) {
          if (homeState.errorType == HomeError.networkError) {
            Future.delayed(Duration(milliseconds: 100)).then(
              (value) => Navigator.pushNamed(
                context,
                AppRouter.NetworkErrorScreen,
              ).then((value) {
                CommonBloc.homePageBloc.add(RefreshHome());
              }),
            );
          }
          return AllowLocationPage(
            errormessage: homeState.error,
            onAllow: () {
              UtilToast.showMessageForUser(
                context,
                "Requesting location permission...",
              );
              CommonBloc.homePageBloc.add(LoadHome());
            },
            onSkip: () {
              UtilToast.showMessageForUser(
                context,
                "Location permission is required to access this feature.",
              );
            },
          );
        }
        if (homeState is HomeLoading) {
          return Loading();
        }
        if (homeState is HomeLoaded || homeState is HomeLoadSwitch) {
          // if (homeState is HomeLoaded) {
          var homeResponse = context.read<HomeBloc>().repository.homeResponse;
          var aqidata = context.read<HomeBloc>().repository.aqidata;
          var travelswitch = context.read<HomeBloc>().repository.travelswitch;
          // }
          // if (homeState is HomeLoadSwitch) travelswitch = homeState.value;
          double bodyHeight =
              SizeConfig.screenHeight -
              MediaQuery.of(context).padding.top -
              MediaQuery.of(context).padding.bottom;
          return Scaffold(
            backgroundColor: Color(0xffF3F3F3),
            body: SafeArea(
              child: SizedBox(
                height: bodyHeight,
                width: SizeConfig.screenWidth,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _backgroundView(height: bodyHeight),
                    // Background elements like birds and clouds can go here (optional)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 2,
                        ),
                        child: Column(
                          children: [
                            // Location & Date
                            Row(
                              children: [
                                Image.asset(
                                  IMAGECONST.START_POINT,
                                  width: 40,
                                  height: 60,
                                  fit: BoxFit.fitWidth,
                                ),
                                4.toSpace,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        homeResponse!['address'] ?? "",
                                        style: FONT_CONST.BOLD_PRIMARY_16
                                            .copyWith(
                                              fontSize: 14,
                                              color:
                                                  COLOR_CONST.accentTintColor,
                                            ),
                                      ),
                                      4.toSpace,
                                      Text(
                                        DateFormat(
                                          'dd/MM/yyyy hh:mm a',
                                        ).format(DateTime.now()).toString(),
                                        style: FONT_CONST.REGULAR.copyWith(
                                          fontSize: 12,
                                          color: COLOR_CONST.darkShadeColor,
                                          // fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    // localNotificationService.showNotification(
                                    //   title: "Hello 👋",
                                    //   body: "This is a test notification",
                                    // );

                                    Navigator.pushNamed(
                                      context,
                                      AppRouter.PROFILE,
                                      arguments: ProfileScreen(
                                        clatlng: homeResponse['position'],
                                      ),
                                    );
                                  },
                                  icon: Container(
                                    padding: EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: COLOR_CONST.btnColorblk,
                                      ),
                                    ),
                                    child: Image.asset(
                                      IMAGECONST.LOCATION_HISTORY,
                                      width: 30,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: bodyHeight * 0.85 - 100,
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ((SizeConfig.defaultPadding * 1.13).round())
                                        .toSpace,
                                    // Gauge Meter
                                    guagemeter(
                                      500.0,
                                      0.0,
                                      context
                                          .read<HomeBloc>()
                                          .repository
                                          .aqidata!
                                          .aqi
                                          .toDouble(),
                                      aqidata!.color,
                                    ),
                                    ((SizeConfig.defaultPadding * 0.8).round())
                                        .toSpace,
                                    // AQI Label
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.black26,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        // aqidata.customCategory.isNotEmpty
                                        aqidata.customCategory,
                                        // : aqidata.category,
                                        style: FONT_CONST.MEDIUM_DEFAULT_16
                                            .copyWith(
                                              color: COLOR_CONST.btnColorblk,
                                            ),
                                      ),
                                    ),
                                    ((SizeConfig.defaultPadding * 1.4).round())
                                        .toSpace,

                                    // Info Text
                                    RichText(
                                      textAlign: TextAlign.center,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      text: TextSpan(
                                        text:
                                            aqidata
                                                .customhealthRecommendations?['generalPublic'] ??
                                            aqidata
                                                .healthRecommendations?['generalPopulation'] ??
                                            '',
                                        style: FONT_CONST.REGULAR.copyWith(
                                          fontSize:
                                              SizeConfig.defaultSize * 1.3,
                                          color: COLOR_CONST.btnColorblk,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '  Know more',
                                            style: FONT_CONST.REGULAR.copyWith(
                                              fontSize:
                                                  SizeConfig.defaultSize * 1.2,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer:
                                                TapGestureRecognizer()
                                                  ..onTap = () {
                                                    showDialog(
                                                      context: context,
                                                      builder:
                                                          (
                                                            _,
                                                          ) => HealthRecommendationsDialog(
                                                            recommendations:
                                                                (aqidata.customhealthRecommendations ??
                                                                    aqidata
                                                                        .healthRecommendations)!,
                                                          ),
                                                    );
                                                    ;
                                                  },
                                          ),
                                        ],
                                      ),
                                    ),

                                    ((SizeConfig.defaultPadding * 1.4).round())
                                        .toSpace,
                                    // Pollutant Data
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: Colors.white70,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                'What am i breathing right now',
                                                style: FONT_CONST
                                                    .REGULAR_DEFAULT_16
                                                    .copyWith(
                                                      color:
                                                          COLOR_CONST
                                                              .btnColorblk,
                                                      height: 0.9,
                                                    ),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  UtilDialog.showCoolAQIInfoDialog(
                                                    context,
                                                  );
                                                },
                                                icon: Icon(
                                                  Icons.info_outline_rounded,
                                                  size: 19,
                                                  color:
                                                      COLOR_CONST.btnColorblk,
                                                ),
                                              ),
                                            ],
                                          ),
                                          8.toSpace,
                                          Column(
                                            children: [
                                              for (
                                                int i = 0;
                                                i < aqidata.pollutants!.length;
                                                i += 3
                                              )
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: List.generate(3, (
                                                    j,
                                                  ) {
                                                    final index = i + j;
                                                    if (index >=
                                                        aqidata
                                                            .pollutants!
                                                            .length) {
                                                      return SizedBox(
                                                        width: 0,
                                                      ); // Filler
                                                    }
                                                    final pollutant =
                                                        aqidata
                                                            .pollutants![index];
                                                    return Padding(
                                                      padding: const EdgeInsets.all(
                                                        3.0,
                                                      ), // spacing between items
                                                      child: pollutantTile(
                                                        (SizeConfig
                                                                .screenWidth *
                                                            0.26),
                                                        pollutant['displayName'],
                                                        '${pollutant['concentration']['value']}',
                                                        pollutant['concentration']['units']
                                                                    .toString() ==
                                                                'PARTS_PER_BILLION'
                                                            ? "ppb"
                                                            : "µg/m³",
                                                        dominant:
                                                            aqidata
                                                                .dominantPollutant! ==
                                                            pollutant['code'],
                                                      ),
                                                    );
                                                  }),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: SizeConfig.defaultSize * 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.transparent.withOpacity(0),
                              ),
                              height: 115,
                              child: Column(
                                children: [
                                  // Low AQI Switch and Button
                                  // Row(
                                  //   mainAxisAlignment: MainAxisAlignment.center,
                                  //   children: [
                                  //     Text(
                                  //       'Low AQI',
                                  //       style: FONT_CONST.BOLD_PRIMARY.copyWith(
                                  //         color: COLOR_CONST.btnColorblk,
                                  //       ),
                                  //     ),
                                  //     6.toSpace,
                                  //     Switch(
                                  //       value: travelswitch,
                                  //       onChanged: (value) {
                                  //         context.read<HomeBloc>().add(
                                  //           SwitchTravel(),
                                  //         );
                                  //       },
                                  //       activeColor: Colors.green,
                                  //     ),
                                  //     6.toSpace,
                                  //     Text(
                                  //       'Fast travels',
                                  //       style: FONT_CONST.BOLD_PRIMARY.copyWith(
                                  //         color: COLOR_CONST.btnColorblk,
                                  //       ),
                                  //     ),
                                  //   ],
                                  // ),
                                  // 2.toSpace,
                                  SizedBox(
                                    width: double.infinity,
                                    height: 46,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade700,
                                        padding: EdgeInsets.symmetric(
                                          vertical: SizeConfig.defaultSize * 1,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            35,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        travelModeDialog(
                                          context,
                                          homeResponse['position'],
                                          travelswitch,
                                        );
                                      },
                                      child: Text(
                                        'Find Route',
                                        style: TextStyle(
                                          fontSize:
                                              SizeConfig.defaultSize * 1.8,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  8.toSpace,
                                  SizedBox(
                                    width: double.infinity,
                                    height: 46,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        padding: EdgeInsets.symmetric(
                                          vertical: SizeConfig.defaultSize * 1,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            35,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => AqiScreenCircle(
                                                  clatlng:
                                                      homeResponse['position'],
                                                ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Check AQI',
                                        style: TextStyle(
                                          fontSize:
                                              SizeConfig.defaultSize * 1.8,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return Loading();
      },
    );
  }

  Color normalizedToColor(double r, double g, double b, [double a = 1.0]) {
    return Color.fromARGB(
      (a * 255).round(),
      (r * 255).round(),
      (g * 255).round(),
      (b * 255).round(),
    );
  }

  Widget guagemeter(max, min, double current, Color curcolor) {
    double interval = 50;
    return Column(
      children: [
        AnimatedRadialGauge(
          duration: const Duration(seconds: 3),
          curve: Curves.elasticOut,
          radius: SizeConfig.screenHeight * 0.12,
          value: current,
          axis: GaugeAxis(
            min: min,
            max: max,
            degrees: 210,
            style: const GaugeAxisStyle(
              thickness: 11,
              // background: Color(0xFFDFE2EC),
              segmentSpacing: 4,
            ),

            pointer: GaugePointer.needle(
              borderRadius: 14,
              color: COLOR_CONST.getAQIColor(current.round()),
              width: SizeConfig.screenHeight * 0.02,
              height: SizeConfig.screenHeight * 0.1,
            ),
            progressBar: GaugeProgressBar.basic(
              color: COLOR_CONST.borderColor.withOpacity(0),
            ),
            segments: [
              for (int i = 0; i < COLOR_CONST.aqiHeatColors.length; i++)
                GaugeSegment(
                  from:
                      i <= 3
                          ? (interval * i) + 1
                          : i == 4
                          ? 201
                          : 301,
                  to:
                      i <= 3
                          ? interval * (i + 1)
                          : i == 4
                          ? (interval * i) + 100
                          : 500,
                  color:
                      COLOR_CONST.aqiHeatColors[i], // Use your real color list!
                  cornerRadius: Radius.zero,
                ),
              // ...List.generate(
              //   COLOR_CONST.aqiHeatColors.length,
              //   (i) => GaugeSegment(
              //     from: interval * i + (i == 0 ? 0 : 1) + (i == 4 ? 25 : 0),
              //     to:
              //         i + 1 == COLOR_CONST.aqiheatcolors.length
              //             ? 500
              //             : interval * (i + 1) + (i == 3 ? 25 : 0),
              //     color:
              //         COLOR_CONST.aqiheatcolors[i], // Use your real color list!
              //     cornerRadius: Radius.zero,
              //   ),
              // ),
            ],
          ),
          child: Text(
            "◉ Live AQI",
            style: FONT_CONST.BOLD_DEFAULT_20.copyWith(color: Colors.black45),
          ),
        ),
        3.toSpace,

        1.toSpace,
        Text(
          current.toString(),
          style: FONT_CONST.REGULAR_WHITE_20.copyWith(
            color: Colors.black, // curcolor,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget pollutantTile(
    double mwidth,
    String name,
    String value,
    String units, {
    bool dominant = false,
  }) {
    return Container(
      width: mwidth,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        border:
            dominant
                ? Border.all(color: Colors.red)
                : Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              text: name,
              style: FONT_CONST.BOLD_DEFAULT.copyWith(
                color: COLOR_CONST.backgroundColor,
              ),
              children: [
                // TextSpan(
                //   text: navval,
                //   style: FONT_CONST.BOLD_DEFAULT.copyWith(
                //     color: COLOR_CONST.backgroundColor,
                //     fontSize: 8,
                //   ),
                // ),
              ],
            ),
          ),
          4.toSpace,
          Text(
            "$value$units",
            style: FONT_CONST.REGULAR_DEFAULT.copyWith(
              color: COLOR_CONST.googleButtonColorBorder,
              fontSize: 10,
            ),
          ),
          if (dominant)
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Dominant Pollutant',
                style: FONT_CONST.REGULAR.copyWith(
                  color: Colors.red,
                  fontSize: SizeConfig.defaultSize * 0.75,
                ),
              ),
            ),
        ],
      ),
    );
  }

  _backgroundView({double? height}) {
    return Container(
      height: height ?? SizeConfig.screenHeight,
      width: SizeConfig.screenWidth,
      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   gradient: RadialGradient(
      //     center: Alignment(0.0, -.4), // Shift center down from (0.0, 0.0)
      //     radius: 1.4,
      //     colors: [
      //       Color.fromARGB(255, 255, 245, 245),
      //       Color.fromARGB(255, 207, 207, 207),
      //     ],
      //     stops: [0.0, 1.0],
      //   ),
      // ),
      child: Stack(
        children: [
          // Positioned(
          //   top: SizeConfig.defaultSize,
          //   child: Image.asset(
          //     IMAGECONST.SPLASH_1,
          //     width: SizeConfig.screenWidth,
          //     fit: BoxFit.cover,
          //     color: COLOR_CONST.deleteButtonColor,
          //     // height: SizeConfig.screenHeight * 0.23,
          //   ),
          // ),
          Positioned(
            top: SizeConfig.defaultSize * 3,
            left: SizeConfig.screenWidth * 0.075,
            child: Column(
              children: [
                Image.asset(
                  "assets/images/topcloud.png",
                  fit: BoxFit.fitWidth,
                  opacity: AlwaysStoppedAnimation(0.7),
                  height: SizeConfig.screenHeight * 0.15,
                  width: SizeConfig.screenWidth * 0.85,
                ),
                SizedBox(height: SizeConfig.defaultSize * 2),
                Image.asset(
                  "assets/images/birds.png",
                  fit: BoxFit.fitWidth,
                  opacity: AlwaysStoppedAnimation(0.7),
                  height: SizeConfig.screenHeight * 0.15,
                  width: SizeConfig.screenWidth * 0.85,
                ),
              ],
            ),
            // assets/images/birds.png
          ),
          Positioned(
            bottom: 2,
            child: Image.asset(
              IMAGECONST.BACKGROUND_CITY,
              fit: BoxFit.cover,
              // color: COLOR_CONST.deleteButtonColor,
              height: SizeConfig.screenHeight * 0.23,
            ),
          ),
        ],
      ),
    );
  }

  Future<Future<Object?>> travelModeDialog(
    BuildContext context,
    cposition,
    travelswitch,
  ) async {
    return showGeneralDialog(
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: COLOR_CONST.borderColor,
      transitionDuration: const Duration(milliseconds: 200),
      context: context,
      pageBuilder: (
        BuildContext buildContext,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            void Function(void Function()) setState,
          ) {
            return SafeArea(
              child: Scaffold(
                backgroundColor: COLOR_CONST.facebookButtonColor,
                body: Stack(
                  children: [
                    _backgroundView(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, -2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(Icons.arrow_back),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18.0,
                              ),
                              child: Text(
                                'How Would You Like to Travel?',
                                style: FONT_CONST.BOLD_DEFAULT_28.copyWith(
                                  letterSpacing: 1.3,
                                  color: Colors.black87,
                                  fontSize: 34,
                                ),
                              ),
                            ),
                          ),
                          12.toSpace,
                          // Option Card Builder
                          _buildOptionCard(
                            context,
                            icon: Icons.directions_car,
                            title: 'Driving',
                            subtitle:
                                'Explore All Car Routes to Your Destination',
                            onTap: () {
                              Navigator.pushReplacementNamed(
                                context,
                                AppRouter.GOOGLE_MAP_PAGE,
                                arguments: GetRouteScreen(
                                  cposition: cposition,
                                  initfilter: -1, //travelswitch ? 2 : 0,
                                  fromwhere: 0,
                                  tMode: TransportMode.Driving,
                                ),
                              );
                              // Navigator.pop(context);
                              // Add your logic for "Driving"
                            },
                          ),
                          _buildOptionCard(
                            context,
                            icon: Icons.directions_bike,
                            title: 'Bicycle',
                            subtitle:
                                'Explore All Nearby Bicycle Routes and Safe Cycling Paths',
                            onTap: () {
                              showWalkCycleDialog(context, 'cycle', (
                                mode,
                                waytype,
                                radius,
                              ) {
                                Navigator.pop(context);
                                if (waytype == 0) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => AqiRouteMap(
                                            center: LatLng(
                                              cposition.latitude,
                                              cposition.longitude,
                                            ),
                                            radiusKm:
                                                waytype == 0 ? radius : null,
                                            mode: mode,
                                          ),
                                    ),
                                  );
                                } else {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    AppRouter.GOOGLE_MAP_PAGE,
                                    arguments: GetRouteScreen(
                                      cposition: cposition,
                                      initfilter: -1, //travelswitch ? 2 : 0,
                                      fromwhere: 0,
                                      tMode: mode,
                                      waymode: waytype,
                                      radiusInKms: waytype == 0 ? radius : null,
                                    ),
                                  );
                                }
                              });
                              // Navigator.pop(context);
                              // Add your logic for "Bicycle"
                            },
                          ),
                          _buildOptionCard(
                            context,
                            icon: Icons.directions_walk,
                            title: 'Walking',
                            subtitle:
                                'Navigate the City on Foot with Optimized Walking Paths',
                            onTap: () {
                              showWalkCycleDialog(context, 'walk', (
                                mode,
                                waytype,
                                radius,
                              ) {
                                Navigator.pop(context);
                                if (waytype == 0) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => AqiRouteMap(
                                            center: LatLng(
                                              cposition.latitude,
                                              cposition.longitude,
                                            ),
                                            radiusKm:
                                                waytype == 0 ? radius : null,
                                            mode: mode,
                                          ),
                                    ),
                                  );
                                } else {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    AppRouter.GOOGLE_MAP_PAGE,
                                    arguments: GetRouteScreen(
                                      cposition: cposition,
                                      initfilter: -1, //travelswitch ? 2 : 0,
                                      fromwhere: 0,
                                      tMode: mode,
                                      waymode: waytype,
                                      radiusInKms: waytype == 0 ? radius : null,
                                    ),
                                  );
                                }
                              });
                              // Navigator.pop(context);
                              // Add your logic for "Walking"
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> showWalkCycleDialog(
    BuildContext context,
    String mode,
    callbackres(route, mode, radiusinKms),
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  mode == 'walk'
                      ? Icons.directions_walk
                      : Icons.directions_bike,
                  size: 48,
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                Text(
                  'How do you want to ${mode == 'walk' ? 'walk' : 'cycle'}?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OptionCard(
                  icon: Icons.auto_awesome,
                  title: 'Find the best place using AI',
                  description:
                      'Analyze routes in a 10 km radius based on AQI, traffic & weather.',
                  onTap: () {
                    // callbackres(
                    //   mode == 'walk'
                    //       ? TransportMode.Walking
                    //       : TransportMode.Bicycling,
                    //   0,
                    // );
                    UtilDialog.showRangeBottomSheet(
                      context,
                      onRangeSelected: (value) {
                        // This is the callback function that gets called with the selected value.
                        callbackres(
                          mode == 'walk'
                              ? TransportMode.Walking
                              : TransportMode.Bicycling,
                          0,
                          value.toDouble(),
                        );

                        // You can perform any action here with the 'value'.
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                OptionCard(
                  icon: Icons.edit_location_alt,
                  title: 'I know the place',
                  description:
                      'Write your destination manually. We\'ll analyze AQI, traffic & weather for your route.',
                  onTap: () {
                    callbackres(
                      mode == 'walk'
                          ? TransportMode.Walking
                          : TransportMode.Bicycling,
                      1,
                      null,
                    );

                    debugPrint('✏️ Manual destination selected for $mode');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(blurRadius: 6, color: Colors.black.withOpacity(0.3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.black, size: 40),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: FONT_CONST.BOLD_DEFAULT_20.copyWith(
                      color: Colors.black,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
