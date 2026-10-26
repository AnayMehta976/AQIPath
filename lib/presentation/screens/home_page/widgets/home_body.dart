import 'package:aqi_app/constants/constants.dart';
import 'package:aqi_app/data/local/HiveLDB/HiveModel/AQiDetailHistory.dart';
import 'package:aqi_app/presentation/screens/home_page/bloc/home_bloc.dart';
import 'package:aqi_app/presentation/widgets/others/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../configs/config.dart';

import '../bloc/home_state.dart';

class HomeBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, homeState) {
        if (homeState is HomeLoadFailure) {
          return Center(child: Text(homeState.error));
        }
        if (homeState is HomeLoaded) {
          var homeResponse = homeState.homeResponse;
          AQIDetailHistory aqidata = homeResponse['aqi_data'];
          return SizedBox(
            height: SizeConfig.screenHeight,
            width: SizeConfig.screenWidth,
            child: Stack(
              children: [
                _backgroundView(),
                // Background elements like birds and clouds can go here (optional)
                Positioned.fill(
                  child: Column(
                    children: [
                      SizedBox(height: SizeConfig.screenHeight * 0.1),
                      // Sun & AQI Display
                      SizedBox(
                        width: SizeConfig.screenWidth * 0.98,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // Weather Icon
                              Image.asset(
                                IMAGECONST.CLEAR_SUN,
                                width: SizeConfig.screenWidth * 0.38,
                              ),
                              SizedBox(width: SizeConfig.defaultSize * 2),
                              // AQI Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "◉ Live AQI",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      aqidata.aqi.toString(),
                                      style: FONT_CONST.BOLD_DEFAULT_28,
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.location_pin,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            aqidata.city.name.toString(),
                                            // homeResponse["address"],
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: SizeConfig.screenHeight * 0.1),
                      // Info Cards
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xffFFE8E8).withOpacity(0.7),
                                borderRadius: BorderRadius.circular(
                                  SizeConfig.defaultSize * 6,
                                ),
                              ),
                              padding: const EdgeInsets.all(24),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Low AQI",
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 18,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        aqidata.forecast.pm25[0].min
                                            // homeResponse["aqi_data"]['forecast']['daily']['pm25'][0]['min']
                                            .toString(),
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // RadialGaugeVIEW(
                                  //   maxvalue: 500.0,
                                  //   cvalue: aqidata.aqi.toDouble(),
                                  // ),
                                  // Image.asset(
                                  //   'assets/images/aqi_meter.png',
                                  //   height: 64,
                                  //   width: 120,
                                  //   fit: BoxFit.contain,
                                  // ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xffFFE8E8).withOpacity(0.7),
                                borderRadius: BorderRadius.circular(
                                  SizeConfig.defaultSize * 6,
                                ),
                              ),
                              padding: const EdgeInsets.all(24),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Fast travels",
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 18,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "1.5 Km",
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Image.asset(
                                    IMAGECONST.LOCATION_PIN,
                                    width: SizeConfig.screenWidth * 0.21,
                                    fit: BoxFit.cover,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),
                      // Button
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 20,
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF9A1D33),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: const Size.fromHeight(50),
                          ),
                          onPressed: () {
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (_) => MapScreenWithActualHeatmap(),
                            //   ),
                            // );
                            Navigator.pushNamed(
                              context,
                              AppRouter.GOOGLE_MAP_PAGE,
                              arguments: homeResponse['position'],
                            );
                          },
                          child: Text(
                            'Find Route',
                            style: FONT_CONST.BOLD_WHITE_EXTRA.copyWith(
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          // SingleChildScrollView(
          //   child: Column(
          //     children: [
          //       HomeBanner(banners: homeResponse.banners),
          //       _buildHomeCategories(
          //         context,
          //         homeResponse.categories,
          //       ),
          //       // PromoWidget(),
          //       _buildPopularProducts(
          //         context,
          //         homeResponse.popularProducts,
          //       ),
          //       _buildDiscountProducts(
          //         context,
          //         homeResponse.discountProducts,
          //       ),
          //     ],
          //   ),
          // );
          // }

          // return Center(child: Text("Something went wrong."));
        }
        return Loading();
      },
    );
  }

  _backgroundView() {
    return Container(
      height: SizeConfig.screenHeight,
      width: SizeConfig.screenWidth,
      decoration: BoxDecoration(
        color: Color(0xFF810000),
        gradient: RadialGradient(
          center: Alignment(0.0, -.4), // Shift center down from (0.0, 0.0)
          radius: 1.4,
          colors: [Color(0xFFEA9A9A), Color(0xFF810000)],
          stops: [0.0, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 2,
            child: Image.asset(
              IMAGECONST.BACKGROUND_CITY,
              fit: BoxFit.cover,
              color: COLOR_CONST.googleButtonColor,
              height: SizeConfig.screenHeight * 0.23,
            ),
          ),
        ],
      ),
    );
  }

  // _topView() {}
  // _middleView() {}
  // _footerView() {}
}

// class HomeBody extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFFE2647A), // base red gradient background
//       body: Stack(
//         children: [
//           // Background elements like birds and clouds can go here (optional)
//           Positioned.fill(
//             child: Column(
//               children: [
//                 const SizedBox(height: 60),
//                 // Sun & AQI Display
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 24.0),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Weather Icon
//                       Column(
//                         children: [
//                           Icon(
//                             Icons.wb_sunny_rounded,
//                             size: 64,
//                             color: Colors.yellowAccent,
//                           ),
//                           Icon(Icons.cloud, color: Colors.white70, size: 48),
//                         ],
//                       ),
//                       const Spacer(),
//                       // AQI Info
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.end,
//                         children: const [
//                           Text(
//                             "◉ live AQI",
//                             style: TextStyle(fontSize: 18, color: Colors.white),
//                           ),
//                           Text(
//                             "115",
//                             style: TextStyle(
//                               fontSize: 48,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                           SizedBox(height: 4),
//                           Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Icon(
//                                 Icons.location_pin,
//                                 color: Colors.white,
//                                 size: 18,
//                               ),
//                               SizedBox(width: 4),
//                               Text(
//                                 "South Tukoganj, Indore",
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 60),

//                 // Info Cards
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 24),
//                   child: Column(
//                     children: [
//                       Container(
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.2),
//                           borderRadius: BorderRadius.circular(32),
//                         ),
//                         padding: const EdgeInsets.all(24),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: const [
//                                 Text(
//                                   "Low AQI",
//                                   style: TextStyle(
//                                     color: Colors.black87,
//                                     fontSize: 18,
//                                   ),
//                                 ),
//                                 SizedBox(height: 4),
//                                 Text(
//                                   "115",
//                                   style: TextStyle(
//                                     fontSize: 28,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.black54,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             Image.asset(
//                               'assets/images/aqi_meter.png',
//                               height: 64,
//                               width: 120,
//                               fit: BoxFit.contain,
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       Container(
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.2),
//                           borderRadius: BorderRadius.circular(32),
//                         ),
//                         padding: const EdgeInsets.all(24),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: const [
//                             Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   "Fast travels",
//                                   style: TextStyle(
//                                     color: Colors.black87,
//                                     fontSize: 18,
//                                   ),
//                                 ),
//                                 SizedBox(height: 4),
//                                 Text(
//                                   "1.5 Km",
//                                   style: TextStyle(
//                                     fontSize: 28,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.black54,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             Icon(
//                               Icons.alt_route,
//                               color: Colors.deepOrangeAccent,
//                               size: 40,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const Spacer(),

//                 // Button
//                 Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 32,
//                     vertical: 20,
//                   ),
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Color(0xFF9A1D33),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(32),
//                       ),
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       minimumSize: const Size.fromHeight(50),
//                     ),
//                     onPressed: () {},
//                     child: const Text(
//                       'Find Route',
//                       style: TextStyle(fontSize: 18),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
