import 'dart:async';
import 'dart:developer';

import 'package:aqi_app/configs/network.dart';
import 'package:aqi_app/data/local/HiveLDB/Hive_DataRetival.dart';
import 'package:aqi_app/data/repository/Home_repository.dart/Home_repository.dart';
import 'package:aqi_app/data/request/allAPIs.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final repository = HomeRepository();
  bool fastravel = false;
  HomeBloc() : super(HomeLoading()) {
    on<LoadHome>(_onLoadHome);
    on<RefreshHome>(_onRefreshHome);
    on<SwitchTravel>(_switchtravel);
  }

  Future<void> _onLoadHome(LoadHome event, Emitter<HomeState> emit) async {
    await _loadHomeData(emit);
  }

  Future<void> _onRefreshHome(
    RefreshHome event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    await _loadHomeData(emit);
  }

  Future<void> _loadHomeData(Emitter<HomeState> emit) async {
    try {
      final hasPermission =
          await repository.checkAndRequestLocationPermission();

      if (!hasPermission) {
        throw Exception("Location permission denied");
      }
      // emit(HomeLoading());
      final position = await repository.getCurrentPosition();
      log("currentposition: $position");
      final address = await repository.getAddressFromLatLng(position!);
      // final aqiData = await repository.fetchAqiByLocation(
      final aqiData = await AllAPIRequest.fetchAqiByLocationViaGoogle(
        lat: position.latitude,
        lng: position.longitude,
      );
      log(aqiData.toString());
      Map homeresponse = {
        'address': address,
        'position': position,
        "aqi_data": aqiData,
      };
      repository.homeResponse = homeresponse;
      repository.aqidata = homeresponse['aqi_data'];
      final pendingride = await DataReterival.getcurrentRide();
      if (pendingride != null) {
        final cposition = position;
        await repository.showRunningRideDialog(
          route: pendingride,
          cposition: cposition,
          onShowMap: () {},
          onCancelTracking: () {
            // cancel ride tracking
          },
        );
      } else {
        log("no pending ride");
      }
      emit(HomeLoaded(homeResponse: homeresponse));
    } catch (e) {
      if (Network.connected == false) {
        emit(HomeLoadFailure(HomeError.networkError, e.toString()));
        return;
      }
      emit(HomeLoadFailure(HomeError.locationError, e.toString()));
    }
  }

  Future<void> _switchtravel(
    SwitchTravel event,
    Emitter<HomeState> emit,
  ) async {
    fastravel = !fastravel;
    repository.travelswitch = fastravel;
    emit(HomeLoadSwitch(value: fastravel));
  }
}
