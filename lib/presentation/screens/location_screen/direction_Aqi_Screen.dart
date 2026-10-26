// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:developer';

import 'package:aqi_app/configs/router.dart';
import 'package:aqi_app/configs/size_config.dart';
import 'package:aqi_app/constants/key_constant.dart';
import 'package:aqi_app/data/repository/MapScreen_repositry/MapScreen_repositary.dart';
import 'package:aqi_app/presentation/screens/location_screen/location_bloc/location_bloc.dart';
import 'package:aqi_app/presentation/screens/location_screen/location_bloc/location_state.dart';
import 'package:aqi_app/presentation/widgets/custom_widgets.dart';
import 'package:aqi_app/utils/toast.dart';
import 'package:aqi_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../constants/constants.dart';
import 'location_bloc/location_event.dart';
import 'location_widget/ButtomLiveAnaliztion.dart';
import 'location_widget/Custom_Info_windorw.dart';
import 'location_widget/Custom_Place_search.dart';
import 'location_widget/filterbuttonwidget.dart';

class GetRouteScreen extends StatefulWidget {
  final int fromwhere;
  final cposition;
  final initfilter;
  final TransportMode tMode;
  int? waymode;
  final double? radiusInKms;
  var rawrunnigndata;
  GetRouteScreen({
    super.key,
    required this.fromwhere,
    required this.cposition,
    required this.initfilter,
    required this.tMode,
    this.waymode,
    this.radiusInKms,
    this.rawrunnigndata,
  });

  @override
  State<GetRouteScreen> createState() => _GetRouteScreenState();
}

class _GetRouteScreenState extends State<GetRouteScreen> {
  //controllers
  LocationBloc locationBloc = LocationBloc(
    apiKey: Constantkey.GOOGLE_MAP_API_KEY,
  );
  GoogleMapController? mapController;
  LatLng? currentLocation;
  final TextEditingController _startCtrl = TextEditingController();
  final TextEditingController _endCtrl = TextEditingController();
  LatLng? _startPrediction;
  LatLng? _endPrediction;
  final FocusNode _startfocus = FocusNode();
  final FocusNode _endfocus = FocusNode();
  Duration animatedcamera = Duration(seconds: 1);
  // added on over map
  Set<Circle> aqicircle = {};
  final Set<Heatmap> _heatmaps = {};
  Map aqideatilfilter = {};
  bool _isexpanded = true;
  bool isStartLivetraking = false;
  Map nearestdetail = {};
  bool isloading = false;
  @override
  void dispose() {
    mapController!.dispose();
    aqideatilfilter.clear();
    nearestdetail.clear();
    isloading = false;
    // locationBloc.close();
    isStartLivetraking = false;
    super.dispose();
  }

  @override
  void initState() {
    isloading = true;
    setState(() {});
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => locationBloc,
      child: WillPopScope(
        onWillPop: () {
          if (isStartLivetraking || isloading) {
            UtilDialog().showExitConfirmationDialog(context, () {
              locationBloc.add(
                StopLiveLocationTracking(ispreviousride: widget.fromwhere == 1),
              );
              Navigator.pop(context);
            });
            return Future<bool>.value(false);
          } else {
            return Future<bool>.value(true);
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: BlocConsumer<LocationBloc, MapState>(
              bloc: locationBloc,
              listener: (context, state) async {
                if (state is CurrentLocationState) {
                  isloading = false;
                  if (TransportMode.Driving == state.transportMode) {
                    setState(() {
                      // _markers[state.mrkid!] = state.markers;
                      currentLocation = state.currentLocation!;
                    });
                    mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(state.currentLocation!, 22),
                    );
                    nearestdetail['aqiValue'] =
                        state.nearestdetail!['aqiValue'];
                    nearestdetail['turnInstructionHtml'] =
                        state.nearestdetail!['turnInstructionHtml'];
                    nearestdetail['routeDetail'] =
                        state.nearestdetail!['routeDetail'];
                    // nearestdetail == null? state.nearestdetail:s
                    isStartLivetraking = true;
                  } else if (TransportMode.Bicycling == state.transportMode) {
                  } else {
                    await Future.delayed(animatedcamera);
                    currentLocation = state.currentLocation!;
                    _startCtrl.text = state.useraddress;
                    _startPrediction = LatLng(
                      currentLocation!.latitude,
                      currentLocation!.longitude,
                    );
                    mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(state.currentLocation!, 18),
                      duration: Duration(seconds: 2),
                    );
                  }
                }
                if (state is MapLoaded) {
                  log("I am here in state");
                  if (state.filterdata[0]['start_address'] != null) {
                    _startCtrl.text = state.filterdata[0]['start_address'];
                  }
                  if (state.filterdata[0]['end_address'] != null) {
                    _endCtrl.text = state.filterdata[0]['end_address'];
                  }
                  if (state.polylineCoordinates.isNotEmpty) {
                    // addmarkerforroute(state.polylineCoordinates, state.marker);
                    aqideatilfilter = {};
                    aqicircle = state.aqicircle;
                    mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        state.polylineCoordinates[0].last,
                        15,
                      ),
                      duration: animatedcamera,
                    );
                  }
                  _isexpanded = false;
                  if (widget.fromwhere == 1) {
                    locationBloc.add(
                      ResumeLiveTrakingEvent(
                        rawdata: widget.rawrunnigndata,
                        // mode: widget.tMode,
                      ),
                    );
                  }
                }
                if (state is StopLiveLocationTrackingState) {
                  isStartLivetraking = false;
                  if (widget.fromwhere == 1) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRouter.HOME,
                      ModalRoute.withName('/'),
                    );
                  }
                }
                if (state is MapFilterLoaded) {
                  if (state.polylineCoordinates.isNotEmpty) {
                    aqicircle = state.aqicircle;
                    mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        state.polylineCoordinates[0].last,
                        15,
                      ),
                      duration: animatedcamera,
                    );
                  }
                  aqideatilfilter = state.filterdata;
                }
                if (state is OutOFRangeStage) {
                  UtilDialog.showInformation(context, content: state.message);
                }
                if (state is OnDragPinPointSEState) {
                  _updatelocationondrag(
                    state.id,
                    state.position,
                    state.address,
                  );
                }
              },
              builder: (context, state) {
                return SizedBox.expand(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GoogleMap(
                        mapType: MapType.normal,
                        initialCameraPosition: CameraPosition(
                          target: LatLng(23.04017862564687, 79.74788449924758),
                          zoom: 7,
                          tilt: 45,
                        ),
                        onMapCreated: (controller) {
                          locationBloc.repository.cleardata();
                          mapController = controller;

                          locationBloc.add(
                            InitmapNfetchcLocEvent(
                              currentlatlng: LatLng(
                                widget.cposition.latitude,
                                widget.cposition.longitude,
                              ),
                              initialfilter: widget.initfilter,
                              mode: widget.tMode,
                              wayModepreferance: widget.waymode ?? 1,
                              wayRadiusKms: widget.radiusInKms,
                              rowrunnigData:
                                  widget.fromwhere == 1
                                      ? widget.rawrunnigndata
                                      : null,
                            ),
                          );
                        },
                        markers: locationBloc.repository.markers,
                        fortyFiveDegreeImageryEnabled: true,
                        polylines: locationBloc.repository.polylines,
                        myLocationEnabled: false,
                        // trafficEnabled: !_isexpanded,
                        myLocationButtonEnabled: true,
                        // heatmaps: _heatmaps,
                        circles: !isStartLivetraking ? aqicircle : {},
                        onTap: (position) {
                          if (state is ShowOnTapMarkerWindorInfoState) {
                            locationBloc.add(HideMarkercustomInfoWindow());
                          }
                        },
                      ),
                      // Overlay UI -> SearchBox and filterOption
                      Positioned(
                        top: 10,
                        left: 16,
                        right: 16,
                        child: Column(
                          children: [
                            // widget.fromwhere == 0
                            _buildSearchCard(),
                            // : _buildSearchCardForAQICheck(),
                            5.toSpace,
                            if (context
                                    .read<LocationBloc>()
                                    .repository
                                    .polylines
                                    .isNotEmpty &&
                                !isStartLivetraking)
                              if (widget.fromwhere == 0)
                                FilterRowWidget(
                                  initialfilter: widget.initfilter,
                                  onFilterSelected: (selectedType) {
                                    if (selectedType != null) {
                                      locationBloc.add(
                                        OnFilterRuote(
                                          selectedFilter: selectedType,
                                          mode: widget.tMode,
                                        ),
                                      );
                                    } else {
                                      locationBloc.add(
                                        OnFilterRuote(
                                          selectedFilter: RouteFilterType.all,
                                          mode: widget.tMode,
                                        ),
                                      );
                                    }
                                  },
                                ),
                          ],
                        ),
                      ),

                      if (aqideatilfilter.isNotEmpty && !isStartLivetraking)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: _buildBottomInfoPanel(
                            aqideatilfilter,
                            true,
                            widget.tMode.name,
                          ),
                        ),
                      if (isStartLivetraking)
                        LiveTrackingBottomPanel(
                          aqiValue: nearestdetail['aqiValue'],
                          turnInstructionHtml:
                              nearestdetail['turnInstructionHtml'],
                          routeDetail: nearestdetail['routeDetail'],
                          onStopPressed: () {
                            locationBloc.add(
                              StopLiveLocationTracking(
                                ispreviousride: widget.fromwhere == 1,
                              ),
                            );
                          },
                          mode: widget.tMode.name,
                        ),

                      if (state is MapLoading || isloading)
                        LoadingWithHideback(title: "Map Initilizing..."),
                      if (state is ShowOnTapMarkerWindorInfoState)
                        Positioned(
                          top: MediaQuery.of(context).size.height * 0.3,
                          left: 16,
                          right: 16,
                          child: FuturisticInfoWindow(
                            type: state.type,
                            position: state.position,
                          ),
                        ),
                      Positioned(
                        top: SizeConfig.screenHeight * 0.02,
                        left: 0,
                        bottom: 0,
                        right: SizeConfig.screenWidth * 0.85,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          // onTap: () {
                          //   if (isStartLivetraking || isloading) {
                          //   UtilDialog().showExitConfirmationDialog(context, () {
                          //     locationBloc.add(
                          //     StopLiveLocationTracking(
                          //       ispreviousride: widget.fromwhere == 1,
                          //     ),
                          //     );
                          //     Navigator.pop(context);
                          //   });
                          //   } else {
                          //   Navigator.maybePop(context);
                          //   }
                          // },
                          onHorizontalDragUpdate: (details) {
                            // Detect a right swipe from the left edge
                            if (details.delta.dx > 10) {
                              if (isStartLivetraking || isloading) {
                                UtilDialog().showExitConfirmationDialog(
                                  context,
                                  () {
                                    locationBloc.add(
                                      StopLiveLocationTracking(
                                        ispreviousride: widget.fromwhere == 1,
                                      ),
                                    );
                                    Navigator.pop(context);
                                  },
                                );
                              } else {
                                Navigator.maybePop(context);
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return AnimatedContainer(
      height: !_isexpanded ? 75 : null,
      duration: Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child:
              _isexpanded
                  ? Column(
                    children: [
                      SizedBox(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                InkWell(
                                  onTap: () {
                                    locationBloc.add(PinLocation());
                                  },
                                  child: const Icon(
                                    Icons.my_location,
                                    size: 23,
                                    color: Colors.grey,
                                  ),
                                ),
                                1.toSpace,
                                Container(
                                  width: 2,
                                  height: 7,
                                  color: COLOR_CONST.borderColor,
                                ),
                              ],
                            ),
                            const SizedBox(width: 6),
                            Expanded(child: startpointTextField()),
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _startCtrl.clear(),
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                        height: 0.5,
                        thickness: 1.4,
                        indent: 32,
                        endIndent: 40,
                      ),
                      SizedBox(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                1.toSpace,
                                Container(
                                  width: 2,
                                  height: 7,
                                  color: COLOR_CONST.borderColor,
                                ),
                                1.toSpace,
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.green,
                                ),
                              ],
                            ),
                            const SizedBox(width: 6),
                            Expanded(child: endpointTextField()),
                            IconButton(
                              icon: const Icon(Icons.swap_vert),
                              onPressed: () {
                                final temp = _startCtrl.text;
                                _startCtrl.text = _endCtrl.text;
                                _endCtrl.text = temp;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildButtonDirection(),
                    ],
                  )
                  : SizedBox(
                    height: 50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions, color: Colors.green),
                        const SizedBox(width: 4),
                        Expanded(
                          child: IgnorePointer(
                            ignoring: !_isexpanded,
                            child: Text(
                              _endCtrl.text.isNotEmpty
                                  ? _endCtrl.text.toString()
                                  : 'Edit Text',
                              style: FONT_CONST.REGULAR.copyWith(
                                color: Colors.black45,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_location_alt),
                          onPressed: () {
                            setState(() {
                              _isexpanded = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildBottomInfoPanel(aqidetail, bool shownavigation, String mode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _infoTile(
                  "AQI",
                  aqidetail["route_avg_aqi"].round().toString(),
                  aqiinstring(aqidetail["route_avg_aqi"].round()),
                ),
              ),
              Expanded(
                child: _infoTile(
                  "Traffic",
                  classifyTraffic(
                    aqidetail['route_duration'] /
                        aqidetail['traffic_duration_weight'],
                  )[1],
                  classifyTraffic(
                    aqidetail['route_duration'] /
                        aqidetail['traffic_duration_weight'],
                  )[0],
                ),
              ),
              Expanded(
                child: _infoTile(
                  "Distance",
                  (aqidetail["route_total_distance"] / 1000).toStringAsFixed(2),
                  "Km",
                ),
              ),
              Expanded(
                child: _infoTile(
                  "Time",
                  "~${(aqidetail['route_duration'] / 60).round().toString()}",
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
                      locationBloc.add(
                        StartLiveLocationTracking(
                          tmode: widget.tMode.name.toString(),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,

                      children: [
                        Text(
                          'Start $mode'.toUpperCase(),
                          style: TextStyle(fontSize: 18, color: Colors.white),
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
    );
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

  _buildButtonDirection() {
    return SizedBox(
      width: double.infinity,
      height: SizeConfig.defaultSize * 4,
      child: TextButton(
        onPressed: () {
          _onLoadDirection();
        },
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: COLOR_CONST.backgroundColor,
        ),
        child: Text(
          Translate.of(context).translate('Direction').toUpperCase(),
          style: FONT_CONST.BOLD_WHITE_16,
        ),
      ),
    );
  }

  _onLoadDirection() {
    if (_startCtrl.text.isEmpty || _startPrediction!.latitude.isNaN) {
      UtilToast.showMessageForUser(
        context,
        "Please provide Start Point address",
      );
    } else if (_endCtrl.text.isEmpty || _endPrediction!.latitude.isNaN) {
      UtilToast.showMessageForUser(
        context,
        "Please provide Distination Point address",
      );
    } else {
      locationBloc.add(
        SearchRoute(_startPrediction!, _endPrediction!, widget.tMode),
      );
    }
  }

  _updatelocationondrag(id, LatLng position, newaddress) async {
    if (id == 'p0') {
      _startCtrl.text = newaddress;
      _startCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: newaddress.length),
      );
      _startPrediction = position;
    } else if (id == 'pn') {
      _endCtrl.text = newaddress;
      _startCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: newaddress.length),
      );
      _endPrediction = position;
    }
    _onLoadDirection();
  }

  startpointTextField() {
    return PlaceAutocompleteFieldWithOverlay(
      apiKey: Constantkey.GOOGLE_MAP_API_KEY,
      mytxtctrl: _startCtrl,
      hintText: "Start Point",
      biasLat: widget.cposition.latitude, // optional
      biasLng: widget.cposition.latitude,
      crossbtn: false,
      onPlaceSelected: (place) {
        _startCtrl.text = place.disp;
        _startCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: place.disp.length),
        );
        _startPrediction = LatLng(place.lat, place.lng);
        _startfocus.unfocus();
        debugPrint("start: ${place.name} (${place.lat}, ${place.lng})");
      },
    );
  }

  endpointTextField() {
    return PlaceAutocompleteFieldWithOverlay(
      apiKey: Constantkey.GOOGLE_MAP_API_KEY,
      mytxtctrl: _endCtrl,
      hintText: "Where do you want to go?",
      biasLat: widget.cposition.latitude, // optional
      biasLng: widget.cposition.latitude, // optional
      crossbtn: true,
      onPlaceSelected: (place) {
        _endCtrl.text = place.disp;
        _endCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: place.disp.length),
        );
        _endPrediction = LatLng(place.lat, place.lng);
        _endfocus.unfocus();
        debugPrint(
          "Destination: ${place.name} ${place.disp} (${place.lat}, ${place.lng})",
        );
      },
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
}
