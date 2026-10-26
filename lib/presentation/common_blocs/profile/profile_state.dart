import 'package:aqi_app/data/local/HiveLDB/HiveModel/MainNavigationHistory.dart';
import 'package:equatable/equatable.dart';

import '../../../data/models/models.dart';

abstract class ProfileState extends Equatable {
  @override
  List<Object> get props => [];
}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserModel loggedUser;
  final List? aqidata;
  ProfileLoaded(this.loggedUser, {this.aqidata});

  List<Object> get props => [loggedUser];

  @override
  String toString() {
    return "{ProfileLoaded: loggedUser:${this.loggedUser.toString()}}";
  }
}

class ProfileLoadFailure extends ProfileState {
  final String error;

  ProfileLoadFailure(this.error);

  List<Object> get props => [error];
}

class Fetchlast7daysaqiState extends ProfileState {
  final List aqi;

  Fetchlast7daysaqiState(this.aqi);

  List<Object> get props => [aqi];
}

class FetchHistoryNavDataState extends ProfileState {
  final List<MainNavigationHistory> mainHistory;

  FetchHistoryNavDataState(this.mainHistory);

  List<Object> get props => [mainHistory];
}
