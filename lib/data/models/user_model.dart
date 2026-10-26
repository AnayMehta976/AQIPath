import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'models.dart';

/// User model
class UserModel extends Equatable {
  /// The current user's id.
  final String id;

  /// The current user's email address.
  final String email;

  /// The current user's name (display name).
  final String name;

  /// Url for the current user's photo.
  // final String avatar;

  /// The user's phone number
  final String phoneNumber;

  // final List<DeliveryAddressModel> addresses;
  final String passward;
  // final List<DeliveryAddressModel> addresses;
  final String? fbtoken;
  final String? appversion;

  /// Get default address
  // DeliveryAddressModel? get defaultAddress {
  //   return addresses.isEmpty
  //       ? null
  //       : addresses.firstWhere((address) => address.isDefault);
  // }

  /// Constructor
  const UserModel({
    required this.email,
    required this.id,
    required this.name,
    // required this.avatar,
    required this.phoneNumber,
    required this.passward,
    this.fbtoken,
    this.appversion,
    // required this.addresses,
  });

  /// Json data from server turns into model data
  static UserModel fromMap(Map<String, dynamic> data) {
    List<DeliveryAddressModel> addresses = [];
    if (data["addresses"] != null) {
      data["addresses"].forEach((item) {
        addresses.add(DeliveryAddressModel.fromMap(item));
      });
    }
    return UserModel(
      id: data["id"] ?? "",
      name: data["name"] ?? "",
      email: data["email"] ?? "",
      // avatar: data["avatar"] ?? "",
      phoneNumber: data["phoneNumber"] ?? "",
      passward: data["passward"] ?? "",
      fbtoken: data['firebaseToken'] ?? "",
      appversion: data['app_version'] ?? "",
      // addresses: addresses,
    );
  }

  /// From model data turns into json data => server
  Map<String, dynamic> toMap() {
    return {
      "id": this.id,
      "email": this.email,
      "name": this.name,
      // "avatar": this.avatar,
      "phoneNumber": this.phoneNumber,
      "password": this.passward,
      "app_version": this.appversion,
      "firebaseToken": this.fbtoken,
      // "addresses":
      //     List<dynamic>.from(this.addresses.map((item) => item.toMap()))
    };
  }

  /// Clone and update
  UserModel cloneWith({
    email,
    id,
    addresses,
    phoneNumber,
    name,
    avatar,
    passward,
    fbtoken,
    appversion,
  }) {
    return UserModel(
      email: email ?? this.email,
      id: id ?? this.id,
      name: name ?? this.name,
      // avatar: avatar ?? this.avatar,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      passward: passward ?? this.passward,
      appversion: appversion ?? this.appversion ?? "",
      fbtoken: fbtoken ?? this.fbtoken ?? "",
      // addresses: addresses ?? this.addresses,
    );
  }

  @override
  String toString() {
    return "UserModel:{email:${this.email},name:${this.name},phoneNumber:${this.phoneNumber}} ";
  }

  /// Compare two users
  @override
  List<Object?> get props => [email, id, name, phoneNumber, fbtoken];
}
