import 'dart:async';
import 'package:aqi_app/configs/size_config.dart';
import 'package:aqi_app/constants/constants.dart';
import 'package:aqi_app/data/models/route_option.dart';
import 'package:aqi_app/data/repository/MapScreen_repositry/MapScreen_repositary.dart';
import 'package:aqi_app/presentation/screens/location_screen/location_widget/ButtomLiveAnaliztion.dart';
import 'package:aqi_app/presentation/widgets/others/radarscanerwidget.dart';
import 'package:aqi_app/utils/toast.dart';
import 'package:aqi_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../data/repository/aqi_route_repository/aqi_route_repo.dart';
import '../../../../utils/geo_utils.dart';
import 'aqi_routes_widgets.dart';
import 'bloc/aqi_route_bloc.dart';

class AqiRouteMap extends StatefulWidget {
  final LatLng center;
  final double radiusKm;
  final TransportMode? mode; // optional if you want Directions

  const AqiRouteMap({
    Key? key,
    required this.center,
    required this.radiusKm,
    this.mode,
  }) : super(key: key);

  @override
  _AqiRouteMapState createState() => _AqiRouteMapState();
}

class _AqiRouteMapState extends State<AqiRouteMap> {
  final repo = AqiRouteRepository();
  final Completer<GoogleMapController> controller = Completer();
  final AqiRouteBloc _aqiRouteBloc = AqiRouteBloc();
  Set<Marker> _markers = {};
  Set<Heatmap> _heatmaps = {};
  Set<Polyline> _polylines = {};
  bool _isCardVisible = false;
  List<RouteOption> myroutesNdata = [];
  Circle? _circle;
  bool showloading = false;
  int _routeselected = -1;
  bool isStartLivetraking = false;
  Map nearestdetail = {};
  @override
  void dispose() {
    _aqiRouteBloc.close();
    myroutesNdata.clear();
    nearestdetail.clear();
    isStartLivetraking = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => _aqiRouteBloc,
      child: WillPopScope(
        onWillPop: () {
          if (isStartLivetraking) {
            UtilDialog().showExitConfirmationDialog(context, () {
              _aqiRouteBloc.add(StopLiveLocationTracking());
              Navigator.pop(context);
            });
            return Future<bool>.value(false);
          } else {
            return Future<bool>.value(true);
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            centerTitle: false,
            leadingWidth: 50,
            titleSpacing: 1,
            leading: IconButton(
              onPressed: () {
                if (isStartLivetraking) {
                  UtilDialog().showExitConfirmationDialog(context, () {
                    _aqiRouteBloc.add(StopLiveLocationTracking());
                    Navigator.pop(context);
                  });
                  // return Future<bool>.value(false);
                } else {
                  Navigator.pop(context);
                  // return Future<bool>.value(true);
                }

                // return back with dialog
              },
              icon: Icon(Icons.arrow_back_ios, color: Colors.black87),
            ),
            title: Text(
              'AQI Route Finder',
              style: TextStyle(color: COLOR_CONST.backgroundColor),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  // all routes
                  _aqiRouteBloc.add(
                    OnTapActionbtn(tapindex: 1, svalue: _isCardVisible),
                  );
                  // AqiRoutesWidgets.showTopRoutesList(context, _routes,(val)=>  onPolylineTapped(val));
                },
                icon: Icon(Icons.route_rounded, color: Colors.black87),
              ),
              // IconButton(
              //   onPressed: () {
              //     // await _startPipeline();
              //   },
              //   icon: Icon(Icons.refresh_sharp, color: Colors.black87),
              // ),
              IconButton(
                onPressed: () => AqiRoutesWidgets.showRouteOptionsInfo(context),
                icon: Icon(Icons.info_outline, color: Colors.black87),
              ),
            ],
          ),
          body: BlocConsumer<AqiRouteBloc, AqiRouteState>(
            bloc: _aqiRouteBloc,
            listener: (context, state) async {
              // TODO: implement listener
              if (state is AqiRouteLoading) {
                repo.progress.add(state.progress);
                showloading = true;
              }
              if (state is AqiRouteCircleAdded) {
                _circle = state.circle;
                controller.future.then(
                  (e) => e.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      _circle!.center,
                      12 - (widget.radiusKm / 2),
                    ),
                  ),
                );
                _aqiRouteBloc.add(GenerateDensePoints());
              }
              if (state is AqiRoutePointsGenerated) {
                _markers = state.markers;
                _heatmaps = state.heatmap;
                _aqiRouteBloc.add(GenerateRoutes());
              }
              if (state is AqiRouteGenerated) {
                _polylines = state.polyline;
                _aqiRouteBloc.add(
                  FetchDirections(
                    state.routes,
                    widget.mode!,
                    distance: widget.radiusKm,
                  ),
                );
              }
              if (state is AqiRouteWithDirections) {
                _polylines = state.mypolyline;
                // _markers.clear();
                showloading = false;
                _markers = state.myMarker;
                repo.progress.add(1);
                controller.future
                    .then(
                      (e) => e.animateCamera(
                        CameraUpdate.newLatLngZoom(widget.center, 16),
                        duration: Duration(seconds: 1),
                      ),
                    )
                    .whenComplete(
                      () => _aqiRouteBloc.add(
                        OnTapActionbtn(tapindex: 1, svalue: _isCardVisible),
                      ),
                    );
              }
              if (state is ActionTapResponse) {
                if (state.index == 1) {
                  if (state.svalue) {
                    myroutesNdata = state.routes!;
                    _isCardVisible = true;
                    _showAqiRouteBottomSheet(
                      context,
                      widget.radiusKm,
                      widget.mode!.name,
                    );
                  } else {
                    _isCardVisible = false;
                  }
                } else if (state.index == 2) {
                  // recompute
                } else {
                  // show info
                }
              }
              if (state is UpdateLiveLocationState) {
                debugPrint("i am here in state $state");
                _markers.add(state.markers);
                nearestdetail = state.nearestdetail!;
                controller.future.then(
                  (v) => v.animateCamera(
                    CameraUpdate.newLatLngZoom(state.currentLocation!, 22),
                  ),
                );
                // nearestdetail['aqiValue'] = state.nearestdetail!['aqiValue'];
                // nearestdetail['turnInstructionHtml'] =
                //     state.nearestdetail!['turnInstructionHtml'];
                // nearestdetail['routeDetail'] =
                //     state.nearestdetail!['routeDetail'];
                // nearestdetail == null? state.nearestdetail:s
                isStartLivetraking = true;
              }
              if (state is SelectrouteTapResponse) {
                _isCardVisible = !_isCardVisible;
                _polylines.clear();
                _polylines.add(state.routes.polyline!);
                _markers.clear();
                _markers = state.marker;
                _routeselected = state.isrouteindex;
              }
              if (state is StopLiveLocationTrackingState) {
                final markerId = MarkerId('current_location');
                _markers.removeWhere((element) => element.markerId == markerId);
                isStartLivetraking = false;
              }
            },
            builder: (context, state) {
              return Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: widget.center,
                      zoom: GeoUtils().zoomFromRadius(widget.radiusKm),
                    ),
                    minMaxZoomPreference: MinMaxZoomPreference(13, 20),
                    markers: _markers,
                    polylines: _polylines,
                    heatmaps: _heatmaps,
                    circles: _circle != null ? {_circle!} : {},
                    onMapCreated: (GoogleMapController ctrl) {
                      controller.complete(ctrl);
                      _aqiRouteBloc.add(
                        StartPipeline(
                          center: widget.center,
                          radiusKm: widget.radiusKm,
                          tMode: widget.mode!,
                        ),
                      );
                    },
                  ),
                  if (showloading)
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: SizeConfig.screenWidth,
                        height: SizeConfig.screenHeight,
                        color: Colors.black26.withOpacity(0.3),
                        child: Center(
                          child: RadarScanWidget(
                            size: SizeConfig.screenWidth * 0.9,
                          ),
                        ),
                      ),
                    ),
                  if (state is AqiRouteInitial)
                    const Center(child: CircularProgressIndicator()),

                  // progress bar stream
                  Positioned(
                    top: 8,
                    left: 12,
                    right: 12,
                    child: StreamBuilder<double>(
                      stream: repo.progress.stream,
                      initialData: 0.0,
                      builder: (context, snap) {
                        final v = snap.data ?? 0.0;
                        return v <= 0 || v >= 1
                            ? SizedBox.shrink()
                            : LinearProgressIndicator(value: v, minHeight: 6);
                      },
                    ),
                  ),

                  // filter chips
                  // Positioned(
                  //   top: 15,
                  //   left: 24,
                  //   right: 12,
                  //   child: Card(
                  //     elevation: 2,
                  //     child: Padding(
                  //       padding: const EdgeInsets.all(8.0),
                  //       child: Row(
                  //         mainAxisAlignment: MainAxisAlignment.center,
                  //         children: [
                  //           ChoiceChip(
                  //             label: Text(
                  //               'Lowest AQI',
                  //               style: FONT_CONST.BOLD_DEFAULT.copyWith(
                  //                 color: Colors.black,
                  //               ),
                  //             ),
                  //             selected: repo.filterMode == 'aqi',
                  //             onSelected: (v) async {
                  //               setState(() => repo.filterMode = 'aqi');
                  //               await _startPipeline();
                  //             },
                  //           ),
                  //           SizedBox(width: 8),
                  //           ChoiceChip(
                  //             label: Text(
                  //               'Shortest',
                  //               style: FONT_CONST.BOLD_DEFAULT.copyWith(
                  //                 color: Colors.black,
                  //               ),
                  //             ),
                  //             selected: _filterMode == 'distance',
                  //             onSelected: (v) async {
                  //               setState(() => _filterMode = 'distance');
                  //               await _startPipeline();
                  //             },
                  //           ),
                  //           SizedBox(width: 8),
                  //           ChoiceChip(
                  //             label: Text(
                  //               'Least Traffic',
                  //               style: FONT_CONST.BOLD_DEFAULT.copyWith(
                  //                 color: Colors.black,
                  //               ),
                  //             ),
                  //             selected: _filterMode == 'traffic',
                  //             onSelected: (v) async {
                  //               setState(() => _filterMode = 'traffic');
                  //               await _startPipeline();
                  //             },
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ),
                  // ),

                  // small legend
                  Positioned(
                    bottom: 10 + MediaQuery.of(context).viewPadding.bottom,
                    left: 12,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            AqiRoutesWidgets.legendDot(Colors.green, 'Good'),
                            SizedBox(width: 8),
                            AqiRoutesWidgets.legendDot(
                              Colors.orange,
                              'Moderate',
                            ),
                            SizedBox(width: 8),
                            AqiRoutesWidgets.legendDot(Colors.red, 'Unhealthy'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_routeselected != -1 && !isStartLivetraking)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildBottomInfoPanel(
                        myroutesNdata[_routeselected],
                        true,
                        widget.mode!.name.toUpperCase(),
                      ),
                    ),
                  if (isStartLivetraking)
                    LiveTrackingBottomPanel(
                      aqiValue: nearestdetail['aqiValue'],
                      turnInstructionHtml: nearestdetail['turnInstructionHtml'],
                      routeDetail: nearestdetail['routeDetail'],
                      onStopPressed: () {
                        _aqiRouteBloc.add(StopLiveLocationTracking());
                      },
                      mode: widget.mode!.name.toLowerCase(),
                    ),
                  // if (state is MapLoading)
                  //   LoadingWithHideback(title: "Map Initilizing..."),
                  // if (state is ShowOnTapMarkerWindorInfoState)
                  //   Positioned(
                  //     top: MediaQuery.of(context).size.height * 0.3,
                  //     left: 16,
                  //     right: 16,
                  //     child: FuturisticInfoWindow(
                  //       type: state.type,
                  //       position: state.position,
                  //     ),
                  //   ),
                  // 👇 Reusable Card
                  // AnimatedPositioned(
                  //   duration: const Duration(milliseconds: 300),
                  //   curve: Curves.easeInOut,
                  //   bottom: _isCardVisible ? 0 : -SizeConfig.screenHeight * 0.5,
                  //   left: 0,
                  //   right: 0,
                  //   child: AqiRouteCard(
                  //     maxHeight: SizeConfig.screenHeight * 0.45,
                  //     type: 1,
                  //     allroutes: myroutesNdata,
                  //     onUseCallback: (id) {
                  //       if (isStartLivetraking) {
                  //         UtilToast.showMessageForUser(
                  //           context,
                  //           "Live Navigation is Running. Please Stop First",
                  //         );
                  //       } else {
                  //         _aqiRouteBloc.add(
                  //           SelectRouteEvent(
                  //             tapindex: myroutesNdata.indexWhere(
                  //               (e) => e.id == id,
                  //             ),
                  //           ),
                  //         );
                  //       }
                  //     },
                  //   ),
                  // ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInfoPanel(
    RouteOption aqidetail,
    bool shownavigation,
    String mode,
  ) {
    debugPrint("my selected route data: $aqidetail");
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _infoTile(
                      "AQI",
                      aqidetail.avgAqi.round().toString(),
                      aqiinstring(aqidetail.avgAqi.round()),
                    ),
                  ),
                  Expanded(
                    child: _infoTile(
                      "Traffic",
                      classifyTraffic(
                        aqidetail.duration!.inMinutes /
                            aqidetail.filterData!.durationInTraffic,
                      )[1],
                      classifyTraffic(
                        aqidetail.duration!.inMinutes /
                            aqidetail.filterData!.durationInTraffic,
                      )[0],
                    ),
                  ),
                  Expanded(
                    child: _infoTile(
                      "Distance",
                      (aqidetail.distanceKm).toStringAsFixed(2),
                      "Km",
                    ),
                  ),
                  Expanded(
                    child: _infoTile(
                      "Time",
                      "~${(aqidetail.duration!.inMinutes).round().toString()}",
                      'min',
                    ),
                  ),
                ],
              ),
              10.toSpace,
              if (shownavigation)
                Row(
                  children: [
                    Expanded(
                      // width: SizeConfig.screenWidth * 0.5,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: COLOR_CONST.accentTintColor,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          _aqiRouteBloc.add(StartLiveLocationTracking());
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,

                          children: [
                            Text(
                              'Start $mode'.toUpperCase(),
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            8.toSpace,
                            Icon(
                              mainFABIcon(mode.toLowerCase()),
                              color: Colors.white,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 10.toSpace,
                    // const TravelModeFAB(showingfrombtmbar: true),
                  ],
                ),
              if (shownavigation) 10.toSpace,
            ],
          ),
        ),
      ),
    );
  }

  mainFABIcon(selectedMode) {
    switch (selectedMode) {
      case 'driving':
        return (Icons.directions_car);
      case 'walking':
        return Icons.directions_walk;
      case 'bicycling':
        return Icons.directions_bike;
      default:
        return Icons.directions_car; // default icon when no mode is selected
    }
  }

  List classifyTraffic(num ratio) {
    if (ratio <= 1.1) return ["Low", "🟢"];
    if (ratio <= 1.3) return ["Moderate", "🔵"];
    return ["Heavy", '🔴'];
  }

  String aqiinstring(int aqi) {
    if (aqi <= 50) {
      return "Good";
    } else if (aqi <= 100) {
      return "Average";
    } else if (aqi <= 200) {
      return "Moderate";
    } else if (aqi <= 300) {
      return "Poor";
    } else if (aqi <= 400) {
      return "Very Poor";
    } else {
      return "Severe";
    }
  }

  Widget _infoTile(String title, String main, String sub) {
    return Card(
      child: Column(
        children: [
          // ✅ Full-width background with centered text
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                width: constraints.maxWidth, // ✅ Bound by parent
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: COLOR_CONST.backgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
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

          const SizedBox(height: 4),

          // ✅ Main Text
          Text(
            main,
            style: FONT_CONST.BOLD_DEFAULT.copyWith(
              color: COLOR_CONST.backgroundColor,
            ),
          ),
          2.toSpace,
          // ✅ Sub Text
          Text(
            sub,
            style: FONT_CONST.REGULAR_WHITE.copyWith(
              color: COLOR_CONST.googleButtonColorBorder,
            ),
          ),
        ],
      ),
    );
  }

  void _showAqiRouteBottomSheet(BuildContext context, radiuskm, mode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4, // same as your maxHeight
          minChildSize: 0.3,
          maxChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                8,
                8,
                8,
                8 + MediaQuery.of(context).viewPadding.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Scrollbar(
                thumbVisibility: true,
                controller: scrollController,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: AqiRouteCard(
                    mode: mode,
                    radiuskm: radiuskm,
                    maxHeight: SizeConfig.screenHeight * 0.45,
                    type: 1,
                    allroutes: myroutesNdata,
                    onUseCallback: (id) {
                      if (isStartLivetraking) {
                        UtilToast.showMessageForUser(
                          context,
                          "Live Navigation is Running. Please Stop First",
                        );
                      } else {
                        _aqiRouteBloc.add(
                          SelectRouteEvent(
                            tapindex: myroutesNdata.indexWhere(
                              (e) => e.id == id,
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
