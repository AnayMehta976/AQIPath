import 'dart:async';
import 'dart:developer';
import 'package:aqi_app/configs/network.dart';
import 'package:aqi_app/data/local/HiveLDB/HiveModel/MainNavigationHistory.dart';
import 'package:aqi_app/data/local/HiveLDB/Hive_DataRetival.dart';
import 'package:aqi_app/data/models/aqi_responses.dart';
import 'package:aqi_app/data/models/comman_aqi_model.dart';
import 'package:aqi_app/data/repository/MapScreen_repositry/MapScreen_repositary.dart';
import 'package:aqi_app/data/repository/MapScreen_repositry/check_Aqi_repo.dart';
import 'package:aqi_app/data/request/allAPIs.dart';
import 'package:aqi_app/utils/dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/user_model.dart';
import '../../../data/repository/repository.dart';
import 'bloc.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AuthRepository _authRepository = AppRepository.authRepository;
  final UserRepository _userRepository = AppRepository.userRepository;
  // final StorageRepository _storageRepository = AppRepository.storageRepository;

  StreamSubscription? _profileStreamSub;
  UserModel? _loggedUser;

  ProfileBloc() : super(ProfileLoading()) {
    on<LoadProfile>(_onLoadProfile);
    // on<UploadAvatar>(_onUploadAvatar);
    // on<AddressListChanged>(_onAddressListChanged);
    on<ProfileUpdated>(_onProfileUpdated);
    on<GetLast7DaysAqiEvent>(_getaqihistorydetail);
    on<GetNavHistoryAqiEvent>(_getNavHistoryDetailData);
  }

  /// Handle LoadProfile event
  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      if (await Network.isConnected()) {
        await _profileStreamSub?.cancel();
        _profileStreamSub = _userRepository
            .loggedUserStream(_authRepository.loggedFirebaseUser)
            .listen(
              (updatedUser) =>
                  add(ProfileUpdated(updatedUser, aqidata: event.data ?? [])),
            );
      } else {
        UtilDialog.showRetry(
          title: "NO INTERNET CONNECTION",
          content: "NO Internet Connection found. Please Connect with internet",
          onClose: () {
            // return getSystemConfig();
            add(event);
          },
        );
      }
    } catch (e) {
      emit(ProfileLoadFailure(e.toString()));
    }
  }

  /// Handle UploadAvatar event
  Future<void> _onUploadAvatar(
    UploadAvatar event,
    Emitter<ProfileState> emit,
  ) async {
    // try {
    //   if (_loggedUser == null) return;

    //   final imageUrl = await _storageRepository.uploadImageFile(
    //     "users/profile/${_loggedUser!.id}",
    //     event.imageFile,
    //   );

    //   final updatedUser = _loggedUser!.cloneWith(avatar: imageUrl);
    //   await _userRepository.updateUserData(updatedUser);
    // } catch (_) {
    //   // Optionally: emit(ProfileLoadFailure(e.toString()));
    // }
  }

  /// Handle AddressListChanged event
  Future<void> _onAddressListChanged(
    AddressListChanged event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      if (_loggedUser == null) return;
      // final updatedUser = _loggedUser!.cloneWith(addresses: addresses);
      // await _userRepository.updateUserData(updatedUser);
    } catch (_) {
      // Optionally: emit(ProfileLoadFailure(e.toString()));
    }
  }

  /// Handle ProfileUpdated event
  Future<void> _onProfileUpdated(
    ProfileUpdated event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      _loggedUser = event.updatedUser;
      emit(ProfileLoaded(event.updatedUser, aqidata: event.aqidata));
    } catch (e) {
      emit(ProfileLoadFailure(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _profileStreamSub?.cancel();
    _loggedUser = null;
    return super.close();
  }

  Future<void> _getaqihistorydetail(
    GetLast7DaysAqiEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    // MapScreenRepository mapScreenRepository = MapScreenRepository();
    //     final aqi = await AllAPIRequest.fetchAqiByLocationViaGoogle(
    //     lat: point.latitude,
    //     lng: point.longitude,
    //     detailedResponse: true,
    //   );
    final AqiResponse data = await AllAPIRequest.fetchAqiByLocationViaGoogle(
      lat: event.clatlng.latitude,
      lng: event.clatlng.longitude,
    );
    log("my data: $data");
    final CommanDetailAqiModel datafield = CommanDetailAqiModel.fromGoogleNew(
      data,
    );
    log("my datafireld: ${datafield.forcast}");
    final aqipridictpreportlist = CheckAqiRepo().generateUpcomingAqiForecast(
      datafield.forcast,
    );
    add(LoadProfile(data: aqipridictpreportlist));
    // emit(Fetchlast7daysaqiState(aqipridictpreportlist));
  }

  Future<void> _getNavHistoryDetailData(
    GetNavHistoryAqiEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final List<MainNavigationHistory> history =
        event.frominit
            ? DataReterival.getNavLastNRecords(2)
            : DataReterival.getNavAllRecords();
    history.sort((a, b) => b.dateOfSync.compareTo(a.dateOfSync));

    emit(FetchHistoryNavDataState(history));
  }
}

enum ListMethod { ADD, DELETE, UPDATE }
