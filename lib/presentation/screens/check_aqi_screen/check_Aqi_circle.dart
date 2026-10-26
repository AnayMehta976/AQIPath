import 'dart:async';
import 'dart:developer' as dev;
import 'package:aqi_app/configs/network.dart';
import 'package:aqi_app/configs/size_config.dart';
import 'package:aqi_app/constants/key_constant.dart';
import 'package:aqi_app/data/repository/MapScreen_repositry/check_Aqi_repo.dart';
import 'package:aqi_app/presentation/screens/location_screen/location_widget/buttom_Aqi_analizing.dart';
import 'package:aqi_app/presentation/widgets/custom_widgets.dart';
import 'package:aqi_app/presentation/widgets/others/radarscanerwidget.dart';
import 'package:aqi_app/utils/toast.dart';
import 'package:aqi_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../constants/constants.dart';
import '../location_screen/location_widget/Custom_Place_search.dart';

class AqiScreenCircle extends StatefulWidget {
  final Position clatlng;
  final caqidetail;
  const AqiScreenCircle({super.key, required this.clatlng, this.caqidetail});
  @override
  State<AqiScreenCircle> createState() => MapScreenState();
}

class MapScreenState extends State<AqiScreenCircle> {
  final CheckAqiRepo _checkAqiRepo = CheckAqiRepo();
  // --- State Variables ---
  final Completer<GoogleMapController> _controller = Completer();
  int heatmapRadius = 0;
  int radiusPixels = 100; // initial
  bool initilized = false;
  LatLng? selectedlatlng;
  bool _isexpanded = true;

  String loadingMessage = "Loading Location...";
  List<String> _randomStepMessages = [
    'Scanning air pockets...',
    'Collecting samples...',
    'Analyzing particulates...',
    'Computing AQI map...',
    'Finalizing results...',
  ];

  bool _isRunningRandomSteps = false;

  /// Starts a 5-step sequence of random messages with variable millisecond delays.
  /// Can be called whenever you want to show the sequence (for example when loading starts).
  Future<void> startFiveStepRandomMessages() async {
    if (_isRunningRandomSteps) return;
    _isRunningRandomSteps = true;
    try {
      while (_isRunningRandomSteps) {
        for (int i = 0; i < 5 && _isRunningRandomSteps; i++) {
          final idx =
              DateTime.now().millisecondsSinceEpoch %
              _randomStepMessages.length;
          loadingMessage = _randomStepMessages[idx];
          if (mounted) setState(() {});

          final delayMs = 250 + (DateTime.now().millisecondsSinceEpoch % 800);
          await Future.delayed(Duration(milliseconds: delayMs));
        }
        // small pause between cycles to avoid a tight loop
        if (_isRunningRandomSteps) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
    } finally {
      _isRunningRandomSteps = false;
    }
  }

  @override
  void dispose() {
    _isRunningRandomSteps = false;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // _requestLocationPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            minMaxZoomPreference: MinMaxZoomPreference(12.18, 18),
            initialCameraPosition: CameraPosition(
              target: _checkAqiRepo.centerLocation,
              zoom: 12,
            ),
            onMapCreated: (GoogleMapController controller) async {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
                await _controller.future.then((controller) {
                  controller.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: _checkAqiRepo.centerLocation,
                        zoom:
                            3, // Make sure this zoom level is valid (between ~2 and 21)
                      ),
                    ),
                  );
                });
                await Future.delayed(Duration(seconds: 1));
                _checkAqiRepo.checkpermissionNgetUserLocation().then((e) {
                  initilized = true;
                  selectedlatlng = LatLng(
                    widget.clatlng.latitude,
                    widget.clatlng.longitude,
                  );
                  setState(() {});
                  _onLoadAqi();
                });
              }
            },
            onCameraMove: _onCameraMove,
            markers: _checkAqiRepo.markers,
            circles: _checkAqiRepo.circles,
            heatmaps: _checkAqiRepo.heatmaps,
            onTap: (latlng) async {
              if (_checkAqiRepo.circles.isNotEmpty) {
                _checkAqiRepo.ispointloading = true;

                setState(() {});
                await _checkAqiRepo.onTapMapPoint(latlng, context);
                setState(() {});
              }
            },
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: SafeArea(child: _buildSearchCardForAQICheck()),
          ),
          if (initilized && _checkAqiRepo.ispointloading)
            Align(
              alignment: Alignment.center,
              child: Container(
                width: SizeConfig.screenWidth,
                height: SizeConfig.screenHeight,
                color: Colors.black26.withOpacity(0.3),
                child: Center(
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: SizeConfig.screenWidth * 0.8,
                          height: SizeConfig.screenWidth * 0.8,
                          child: RadarScanWidget(
                            size: SizeConfig.screenWidth * 0.8,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: SizeConfig.screenHeight * 0.15,
                        left: 12,
                        right: 0,
                        child: Text(
                          loadingMessage,
                          textAlign: TextAlign.center,
                          style: FONT_CONST.BOLD_DEFAULT_18.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_checkAqiRepo.pointsGenerated)
            ValueListenableBuilder(
              valueListenable: _checkAqiRepo.curIndexHorList,
              builder: (_, v, _) {
                return BtmAnalizeAqi(
                  message: _checkAqiRepo.statusMessage,
                  isloading: _checkAqiRepo.ispointloading,
                  data: _checkAqiRepo.datastate,
                  pinpointdetail: _checkAqiRepo.pinpointdetail,
                  cindex: v,
                );
              },
            ),
          if (!initilized) LoadingWithHideback(),
        ],
      ),

      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSearchCardForAQICheck() {
    return AnimatedContainer(
      height: !_isexpanded ? 75 : null,
      duration: Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child:
              _isexpanded
                  ? Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // IconButton(
                          //   icon: Icon(Icons.arrow_back, color: Colors.grey),
                          //   color: COLOR_CONST.backgroundColor,
                          //   onPressed: () {
                          //     Navigator.of(context).pop();
                          //   },
                          // ),
                          // SizedBox(width: 6), // Optional spacing
                          Text(
                            "Check Air Insights Around You",
                            style: FONT_CONST.BOLD_DEFAULT_16.copyWith(
                              color: COLOR_CONST.backgroundColor,
                            ),
                          ),
                        ],
                      ),
                      // Divider(height: 3),
                      SizedBox(height: 6),
                      SizedBox(
                        height: 46,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.only(top: 16),
                              child: const Icon(
                                Icons.location_on_outlined,
                                size: 27,
                                color: Colors.grey,
                              ),
                            ),
                            if (_checkAqiRepo.centerLocation != null)
                              Expanded(
                                child: checkpointTextField(
                                  _checkAqiRepo.centerLocation,
                                ),
                              ),
                            IconButton(
                              padding: EdgeInsets.all(0),
                              icon: Container(
                                width: 40,
                                height: 40,
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: COLOR_CONST.backgroundColor
                                      .withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.gps_fixed,
                                      size: 18,
                                      color: COLOR_CONST.borderColor,
                                    ),
                                    Text(
                                      "current",
                                      style: TextStyle(
                                        color: COLOR_CONST.borderColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onPressed: () {
                                _checkAqiRepo.checkpermissionNgetUserLocation();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildButtonCheckAqi(),
                    ],
                  )
                  : SizedBox(
                    height: 45,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions, color: Colors.green),
                        const SizedBox(width: 4),
                        Expanded(
                          child: IgnorePointer(
                            ignoring: !_isexpanded,
                            child: Text(
                              _checkAqiRepo.startCtrl.text.isNotEmpty
                                  ? _checkAqiRepo.startCtrl.text.toString()
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

  _buildButtonCheckAqi() {
    return SizedBox(
      width: double.infinity,
      height: SizeConfig.defaultSize * 4,
      child: TextButton(
        onPressed: () async {
          _onLoadAqi();
          // _onLoadDirection();
        },
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: COLOR_CONST.accentTintColor,
        ),
        child: Text(
          Translate.of(context).translate('Check AQI').toUpperCase(),
          style: FONT_CONST.BOLD_WHITE_16,
        ),
      ),
    );
  }

  checkpointTextField(cposition) {
    return PlaceAutocompleteFieldWithOverlay(
      apiKey: Constantkey.GOOGLE_MAP_API_KEY,
      mytxtctrl: _checkAqiRepo.startCtrl,
      hintText: "Search Place To Check Aqi",
      isborder: true,
      biasLat: cposition.latitude, // optional
      biasLng: cposition.latitude, // optional
      crossbtn: true,
      onPlaceSelected: (place) {
        _checkAqiRepo.startCtrl.text = place.disp;
        _checkAqiRepo.startCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: place.disp.length),
        );
        selectedlatlng = LatLng(place.lat, place.lng);
        _checkAqiRepo.centerLocation = selectedlatlng!;
        debugPrint(
          "Destination: ${place.name} ${place.disp} (${selectedlatlng!.latitude}, ${selectedlatlng!.longitude})",
        );
        setState(() {});
      },
    );
  }

  void _onCameraMove(CameraPosition position) {
    final zoom = position.zoom;
    final lat = position.target.latitude;

    final newRadius = _checkAqiRepo.heatmapHelper.radiusInPixels(lat, zoom);
    dev.log("new radius:$newRadius $zoom");
    if (newRadius != radiusPixels) {
      radiusPixels = newRadius;
      if (_checkAqiRepo.heatmapPoints.isNotEmpty) {
        _checkAqiRepo.heatmaps.add(
          _checkAqiRepo.heatmapHelper.buildHeatmap(
            data: _checkAqiRepo.heatmapPoints,
            radiusPixels: radiusPixels,
          ),
        );
      }
      setState(() {});
    }
  }

  Future<void> _setupMapWithCenter() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _checkAqiRepo.centerLocation, zoom: 10),
      ),
    );
    _checkAqiRepo.markers.clear();
    _checkAqiRepo.circles.clear();
    _checkAqiRepo.heatmaps.clear();
    // Add a circle representing the 5km radius
    _checkAqiRepo.circles.add(
      Circle(
        circleId: CircleId('radius_circle'),
        center: _checkAqiRepo.centerLocation,
        radius: CheckAqiRepo.totalRadiusInMeters,
        fillColor: Colors.blue.withOpacity(0.1),
        strokeColor: Colors.blue.withOpacity(0.5),
        strokeWidth: 2,
      ),
    );
    _checkAqiRepo.ispointloading = true;
    setState(() {});
  }

  void _onLoadAqi() async {
    if (await Network.isConnected()) {
      if (selectedlatlng != null &&
          initilized &&
          _checkAqiRepo.startCtrl.text.isNotEmpty) {
        await _checkAqiRepo.disposemyTempData();
        setState(() {});
        _checkAqiRepo.statusMessage =
            "Location found. Ready to generate AQI Status";
        startFiveStepRandomMessages();
        await _setupMapWithCenter();
        await _checkAqiRepo.generatePointsAndHeatmap(
          _checkAqiRepo.centerLocation,
        );
        _isRunningRandomSteps = false;
        _isexpanded = !_isexpanded;

        await _controller.future.then((controller) {
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _checkAqiRepo.centerLocation,
                zoom:
                    13, // Make sure this zoom level is valid (between ~2 and 21)
              ),
            ),
          );
        });

        setState(() {});
      } else {
        UtilToast.showMessageForUser(
          context,
          initilized
              ? "Please Provide Valid Address"
              : "Google Map Initilizing",
        );
      }
    } else {
      UtilDialog.showRetry(
        title: "No Internet Connection ?",
        content: "NO Internet Connection found. Please Connect with internet",
        onClose: () {
          // return getSystemConfig();
          Navigator.pop(context);
        },
      );
    }
  }
}
