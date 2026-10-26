import 'package:aqi_app/data/models/user_model.dart';

import 'package:firebase_auth/firebase_auth.dart';

abstract class UserRepository {
  /// Stream of logged user model
  /// [loggedFirebaseUser] is user of firebase auth
  /// Created by JK
  Stream<UserModel> loggedUserStream(User loggedFirebaseUser);

  /// Get user by id
  /// [uid] is user id
  /// Created by JK
  Future<UserModel> getUserById(String uid);

  /// Add new doc to users collection
  /// [user] is data of new user
  /// Created by JK
  Future<void> addUserData(UserModel newUser);

  /// Update a doc in users collection
  /// [user] is updated data of user
  /// Created by JK
  Future<void> updateUserData(id, updatedUser);

  /// Created BY JK
  Future<bool> checkUserById(String uid);
}
