import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:geodesy/geodesy.dart';

import '../../../data/models/models.dart';
import 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Load profile of logged firebase user in firestore
class LoadProfile extends ProfileEvent {
  final List? data;
  LoadProfile({this.data});
}

/// Upload user avatar
class UploadAvatar extends ProfileEvent {
  final File imageFile;

  UploadAvatar(this.imageFile);

  List<Object> get props => [imageFile];
}

/// Delivery addresses changed
class AddressListChanged extends ProfileEvent {
  final DeliveryAddressModel deliveryAddress;
  final ListMethod method;

  AddressListChanged({required this.deliveryAddress, required this.method});

  List<Object> get props => [deliveryAddress, method];
}

/// Profile was updated
class ProfileUpdated extends ProfileEvent {
  final UserModel updatedUser;
  final List? aqidata;

  ProfileUpdated(this.updatedUser, {this.aqidata});

  List<Object> get props => [updatedUser, aqidata!];
}

/// Profile was updated
class GetLast7DaysAqiEvent extends ProfileEvent {
  final LatLng clatlng;

  GetLast7DaysAqiEvent({required this.clatlng});

  List<Object> get props => [clatlng];
}

/// Profile was updated
class GetNavHistoryAqiEvent extends ProfileEvent {
  final bool frominit;
  GetNavHistoryAqiEvent({required this.frominit});
}
