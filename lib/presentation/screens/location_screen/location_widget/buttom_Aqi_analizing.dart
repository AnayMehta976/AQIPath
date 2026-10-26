import 'dart:async';
import 'dart:developer';
import 'package:aqi_app/configs/size_config.dart';
import 'package:aqi_app/data/models/comman_aqi_model.dart';
import 'package:aqi_app/data/repository/MapScreen_repositry/check_Aqi_repo.dart';
import 'package:aqi_app/presentation/screens/home_page/widgets/HealthRecommandationDialog.dart';
import 'package:aqi_app/utils/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gauge_indicator/gauge_indicator.dart';
import 'package:intl/intl.dart';
import 'package:typewritertext/typewritertext.dart';
import '../../../../constants/constants.dart';

class BtmAnalizeAqi extends StatefulWidget {
  final String message;
  final bool isloading;
  int cindex;
  final data;
  final List pinpointdetail;
  BtmAnalizeAqi({
    super.key,
    required this.message,
    required this.isloading,
    this.data,
    required this.pinpointdetail,
    required this.cindex,
  });

  @override
  State<BtmAnalizeAqi> createState() => _BtmAnalizeAqiState();
}

class _BtmAnalizeAqiState extends State<BtmAnalizeAqi>
    with TickerProviderStateMixin {
  final streamer = StreamController<String>();
  final _scrollcontroller = ScrollController();
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    print("initilized data: " + widget.pinpointdetail.length.toString());
    if (widget.pinpointdetail.isEmpty) {
      _controller = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      )..forward();
    } else {
      _controller = AnimationController(
        duration: const Duration(seconds: 0),
        vsync: this,
      )..forward();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollanimatior();
    });
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.cindex != widget.cindex) {
      if (widget.pinpointdetail.isNotEmpty) {
        // Instantly stop and complete
        _controller.stop();
        _controller.value = 1.0;
      }
      scrollanimatior();
    }
  }

  void scrollanimatior() {
    final index = widget.cindex;
    final itemWidth = SizeConfig.screenWidth * 0.95;
    final offset = index * itemWidth;

    if (_scrollcontroller.hasClients) {
      _scrollcontroller.animateTo(
        offset,
        duration: const Duration(milliseconds: 220),
        curve: Curves.bounceInOut,
      );
    } else {
      // Optionally: try again later if needed
      log("ScrollController has no clients yet — skipping animateTo");
      Future.delayed(Duration(seconds: 1)).then((e) => scrollanimatior());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 12 + MediaQuery.of(context).viewPadding.bottom,

      child: AnimatedContainer(
        height: widget.isloading ? 70 : 200,
        width: SizeConfig.screenWidth,
        duration: Duration(seconds: 1),
        curve: Curves.linear,
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(vertical: 7),
        child:
            widget.isloading
                ? Container(
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _TinkingIcon(),
                      8.toSpace,
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Intelligent Analysis Center",
                                  style: FONT_CONST.BOLD_DEFAULT_18.copyWith(
                                    color: COLOR_CONST.btnColorblk.withOpacity(
                                      0.7,
                                    ),
                                  ),
                                ),
                                CircularProgressIndicator(
                                  strokeWidth: 1.2,
                                  constraints: BoxConstraints(
                                    minWidth: 13,
                                    minHeight: 13,
                                    maxWidth: 20,
                                    maxHeight: 20,
                                  ),
                                ),
                              ],
                            ),
                            4.toSpace,
                            Text(
                              widget.message,
                              style: FONT_CONST.BOLD_DEFAULT.copyWith(
                                color: COLOR_CONST.backgroundColor.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                : ListView.separated(
                  controller: _scrollcontroller,
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.pinpointdetail.length + 1,
                  separatorBuilder:
                      (_, i) =>
                          widget.pinpointdetail.length + 1 == 1
                              ? Container()
                              : 4.toSpace,
                  itemBuilder: (_, i) {
                    return Container(
                      alignment: Alignment.bottomCenter,
                      height: SizeConfig.screenHeight * 0.25,
                      width: SizeConfig.screenWidth * 0.93,
                      color: Colors.transparent,
                      child:
                          i == 0
                              ? detailbtmview()
                              : detailbtmpinpointview(i, widget.pinpointdetail),
                    );
                  },
                ),
      ),
    );
  }

  /// widget for  Comman overAll Detail Buttom view
  Widget detailbtmview() {
    bool isfinished = false;
    // if (widget.pinpointdetail.isNotEmpty) {
    //   print("I am here");
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     _controller.stop(); // 🛑 Stop any running animation
    //     _controller.value = 1.0; // ✅ Jump instantly to end });
    //   });
    // }
    String text = widget.data["recomandation"]['generalPublic'].toString();
    int maxLength = 150;

    String safeText =
        text.length > maxLength ? text.substring(0, maxLength) : text;
    Future.delayed(Duration(minutes: 2)).then((value) {
      isfinished = true;
      if (mounted) {
        setState(() {});
      }
      //
    });
    return Container(
      height: SizeConfig.screenHeight * 0.25,
      width: SizeConfig.screenWidth * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StaggeredItem(
              controller: _controller,
              start: 0.0,
              end: 0.1,
              child: SizedBox(
                width: SizeConfig.screenWidth,
                child: TypeWriter.text(
                  // "Overall Air Quality Index (5KM Range)",
                  'Surrounding AQI Overview (5KM Radius)',
                  maxLines: 1,
                  style: TextStyle(
                    color: COLOR_CONST.backgroundColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  duration: const Duration(milliseconds: 20),
                ),
              ),
            ),
            3.toSpace,
            Divider(height: 10),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          1.toSpace,
                          StaggeredItem(
                            controller: _controller,
                            start: 0.0,
                            end: 0.24,
                            child: Text(
                              "${widget.data['category']} Air Quality ",
                              style: FONT_CONST.EXTRA_BOLD.copyWith(
                                color: COLOR_CONST.btnColorblk,
                              ),
                            ),
                          ),
                          4.toSpace,
                          StaggeredItem(
                            controller: _controller,
                            start: 0.25,
                            end: 0.34,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Dominant Pollutent : ${widget.data['dominent_pollutent'].toString().toUpperCase()}',
                                style: FONT_CONST.BOLD.copyWith(
                                  fontSize: 10,
                                  color: Colors.brown,
                                ),
                              ),
                            ),
                          ),
                          6.toSpace,
                          StaggeredItem(
                            controller: _controller,
                            start: 0.35,
                            end: 0.69,
                            child: TypeWriter(
                              controller: TypeWriterController(
                                text: safeText,
                                duration:
                                    widget.pinpointdetail.isNotEmpty
                                        ? Duration(seconds: 0)
                                        : const Duration(milliseconds: 30),
                              ),
                              onFinished: (value) {
                                // ✅ Ensure rebuild triggers
                                if (mounted && !isfinished) {
                                  setState(() => isfinished = true);
                                }
                              },
                              builder: (context, value) {
                                return RichText(
                                  maxLines: 4,
                                  text: TextSpan(
                                    text: 'Health tip: ',
                                    style: FONT_CONST.REGULAR.copyWith(
                                      fontSize: SizeConfig.defaultSize * 1.2,
                                      color: COLOR_CONST.btnColorblk,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: value.text,
                                        style: FONT_CONST.BOLD.copyWith(
                                          fontSize:
                                              SizeConfig.defaultSize * 1.2,
                                          height: 1.1,
                                          color: COLOR_CONST.txtcolorhint,
                                        ),
                                      ),
                                      if (isfinished)
                                        TextSpan(
                                          text: '..Know more',
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
                                                              (widget
                                                                  .data["recomandation"])!,
                                                        ),
                                                  );
                                                },
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          4.toSpace,
                        ],
                      ),
                    ),
                  ),
                  4.toSpace,
                  SizedBox(
                    width: SizeConfig.screenWidth * 0.22,
                    child: guagemeter(
                      300.0,
                      0.0,
                      widget.data['aqi'],
                      aqicolor(widget.data['aqi']),

                      0,
                    ),
                  ),
                ],
              ),
            ),
            StaggeredItem(
              controller: _controller,
              start: 0.8,
              end: 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: RichText(
                  maxLines: 2,
                  text: TextSpan(
                    text: 'Tip: ',
                    style: FONT_CONST.REGULAR.copyWith(
                      fontSize: SizeConfig.defaultSize,
                      color: COLOR_CONST.facebookButtonColorBorder.withOpacity(
                        0.8,
                      ),
                    ),

                    children: [
                      TextSpan(
                        text: widget.data['tips'],
                        style: FONT_CONST.REGULAR.copyWith(
                          color: COLOR_CONST.darkShadeColor,
                          fontSize: SizeConfig.defaultSize * 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget detailbtmpinpointview(index, history) {
    print("My Data: %%%  " + history.toString());
    final CommanDetailAqiModel datafield =
        history[index - 1].values.toList()[0]['aqidetail'];
    // var healthrecom = await AQIChannel().getfullRecommendationsForAQI(
    //   datafield.aqi!,
    // );
    final aqipridictpreportlist = CheckAqiRepo().generateUpcomingAqiForecast(
      datafield.forcast ?? [],
    );
    return Container(
      alignment: Alignment.bottomCenter,
      height: SizeConfig.screenHeight * 0.25,
      width: SizeConfig.screenWidth * 0.93,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header row: title + time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Air Quality Detail',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: SizeConfig.defaultSize * 1.4,
                    color: Colors.black,
                  ),
                ),
                Text(
                  DateFormat('HH:mm aa').format(DateTime.now()),
                  style: FONT_CONST.BOLD.copyWith(
                    color: Colors.black,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Divider(height: 3),

            /// Location +  Status + Meter + AQI
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 4,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Status & dominant pollutant
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Location
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.start,
                        //   crossAxisAlignment: CrossAxisAlignment.start,
                        //   children: [
                        //     Icon(Icons.location_on_outlined, size: 15),
                        //     1.toSpace,
                        Text(
                          history[index - 1].values
                                  .toList()[0]['fulladdress'] ??
                              "Unknown Place",
                          style: FONT_CONST.BOLD.copyWith(
                            height: 1.0,
                            fontSize: 10,
                            color: Colors.black54,
                            overflow: TextOverflow.fade,
                          ),
                          maxLines: 2,
                        ),
                        //   ],
                        // ),
                        3.toSpace,
                        Text(
                          // datafield.healthRecommendations!['generalPublic'] ??
                          //     "",
                          datafield.category!,
                          // "Air Quality is " + healthrecom['category'],
                          style: FONT_CONST.EXTRA_BOLD.copyWith(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        2.toSpace,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Dominant Pollutent : ${datafield.dominantPollutant.toString()}',
                            style: FONT_CONST.REGULAR.copyWith(
                              fontSize: 9,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// Gauge image placeholder + AQI value
                  SizedBox(
                    width: 70,
                    height: 55,
                    child: guagemeter(
                      300.0,
                      0.0,
                      datafield.aqi!.toDouble(),
                      aqicolor(datafield.aqi!.toDouble()),
                      1,
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Last 4 day history label
                  Text(
                    'AQI: Levels Ahead',
                    style: FONT_CONST.REGULAR.copyWith(
                      fontSize: 10,
                      color: Colors.black54,
                    ),
                  ),
                  1.toSpace,

                  /// Day chips
                  SizedBox(
                    height: 45,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: aqipridictpreportlist.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final item = aqipridictpreportlist[index];
                        return Container(
                          width: 60,

                          decoration: BoxDecoration(
                            color: Colors.white70,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(),
                              Text(
                                item['aqi'].toString(),
                                style: FONT_CONST.EXTRA_BOLD.copyWith(
                                  color: Colors.black54,
                                ),
                              ),
                              1.toSpace,
                              Container(
                                width: 60,
                                height: 20,
                                // color: item['bgcolor'].withOpacity(0.5),
                                decoration: BoxDecoration(
                                  color: item['bgcolor'].withOpacity(0.9),
                                  borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(8),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  // index == 0 ? "Today" :
                                  item['day'],
                                  style: FONT_CONST.BOLD_DEFAULT.copyWith(
                                    fontSize: SizeConfig.defaultSize * 1.30,
                                    color: Colors.brown,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  1.toSpace,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String title, String main, String sub) {
    return Card(
      child: Column(
        children: [
          Text(
            main,
            style: FONT_CONST.BOLD_DEFAULT.copyWith(
              color: COLOR_CONST.backgroundColor,
            ),
          ),
          // ✅ Full-width background with centered text
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                width: constraints.maxWidth, // ✅ Bound by parent
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: COLOR_CONST.backgroundColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  title,
                  style: FONT_CONST.REGULAR_WHITE.copyWith(
                    color: COLOR_CONST.googleButtonColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),

          // const SizedBox(height: 1),

          // ✅ Main Text
          // 1.toSpace,
          // // ✅ Sub Text
          // Text(
          //   sub,
          //   style: FONT_CONST.REGULAR_WHITE.copyWith(
          //     color: COLOR_CONST.googleButtonColorBorder,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _richtextcustomtile(title, value, {child}) {
    return RichText(
      text: TextSpan(
        text: title,
        style: FONT_CONST.BOLD_PRIMARY,
        children: [
          TextSpan(
            text: value,
            style: FONT_CONST.BOLD_PRIMARY.copyWith(
              color: COLOR_CONST.btnColorblk,
            ),
          ),
          ...child,
        ],
      ),
    );
  }

  Widget _TinkingIcon() {
    return Card(
      elevation: 1,
      child: SizedBox(child: Image.asset("assets/images/thinking_Ai.gif")),
    );
  }

  Widget guagemeter(max, min, double current, Color curcolor, type) {
    double interval = 50;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Stack(
          alignment: AlignmentDirectional.center,
          children: [
            AnimatedRadialGauge(
              duration: const Duration(seconds: 4),
              curve: Curves.elasticOut,
              radius: type == 0 ? 55 : 30,
              value: current,
              axis: GaugeAxis(
                min: min,
                max: max,
                degrees: type == 0 ? 210 : 270,
                style: GaugeAxisStyle(
                  cornerRadius: Radius.circular(20),
                  thickness: type == 0 ? 10 : 6,
                  background: Color(0xFFDFE2EC),
                  segmentSpacing: 2,
                ),
                pointer:
                    type == 0
                        ? GaugePointer.needle(
                          borderRadius: 12,
                          color: COLOR_CONST.getAQIColor(current.round()),
                          width: 12,
                          height: 40,
                        )
                        : GaugePointer.circle(radius: 7, color: curcolor),

                progressBar: GaugeProgressBar.basic(
                  color: COLOR_CONST.borderColor.withOpacity(0),
                ),

                segments: [
                  ...List.generate(
                    COLOR_CONST.aqiheatcolors.length,
                    (i) => GaugeSegment(
                      // from: (max / COLOR_CONST.aqiheatcolors.length) * i,
                      // to:
                      //     (max / COLOR_CONST.aqiheatcolors.length) *
                      //     (i + 1), // ✅ correct
                      from: interval * i + (i == 0 ? 0 : 1) + (i == 4 ? 25 : 0),
                      to:
                          i + 1 == COLOR_CONST.aqiheatcolors.length
                              ? 500
                              : interval * (i + 1) + (i == 3 ? 25 : 0),
                      color:
                          COLOR_CONST
                              .aqiheatcolors[i], // Use your real color list!
                      cornerRadius: Radius.zero,
                    ),
                  ),
                ],
              ),
            ),
            if (type == 1)
              Align(
                alignment: Alignment.center,
                child: Text(
                  current.toStringAsFixed(0),
                  style: FONT_CONST.REGULAR_WHITE_20.copyWith(
                    color: curcolor,
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.defaultSize * 1.4,
                  ),
                ),
              ),
          ],
        ),
        // if (type == 0)
        //   Text(
        //     "Area Aqi",
        //     style: FONT_CONST.REGULAR_DEFAULT_16.copyWith(color: Colors.black),
        //   ),
        1.toSpace,
        if (type == 0)
          Text(
            "AQI:- ${current.toStringAsFixed(0)}",
            style: FONT_CONST.BOLD.copyWith(
              color: COLOR_CONST.accentShadeColor,
              // fontWeight: FontWeight.w900,
              // fontSize: SizeConfig.defaultSize * 1.6,
            ),
          ),
      ],
    );
  }

  Color aqicolor(aqivalue) {
    if (aqivalue < 50) {
      return COLOR_CONST.aqiheatcolors[0];
    } else if (aqivalue < 100) {
      return COLOR_CONST.aqiheatcolors[1];
    } else if (aqivalue < 200) {
      return COLOR_CONST.aqiheatcolors[2];
    } else if (aqivalue < 300) {
      return COLOR_CONST.aqiheatcolors[3];
    } else {
      return COLOR_CONST.aqiheatcolors[4];
    }
  }
}

class StaggeredItem extends StatelessWidget {
  final Widget child;
  final AnimationController controller;
  final double start;
  final double end;

  const StaggeredItem({
    required this.child,
    required this.controller,
    required this.start,
    required this.end,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOut),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}
