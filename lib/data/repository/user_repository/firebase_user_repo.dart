import 'dart:async';
import 'package:aqi_app/data/models/user_model.dart';
import 'package:aqi_app/data/repository/user_repository/user_repo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseUserRepository implements UserRepository {
  final _userCollection = FirebaseFirestore.instance.collection("users");

  /// Stream of logged user model
  /// [loggedFirebaseUser] is user of firebase auth
  /// Created by NDH
  Stream<UserModel> loggedUserStream(User loggedFirebaseUser) {
    return _userCollection
        .doc(loggedFirebaseUser.uid)
        .snapshots()
        .map((doc) => UserModel.fromMap(doc.data()!));
  }

  /// Get user by id
  /// [uid] is user id
  /// Created by NDH
  @override
  Future<UserModel> getUserById(String uid) async {
    return await _userCollection
        .doc(uid)
        .get()
        .then((doc) => UserModel.fromMap(doc.data()!))
        .catchError((error) {
          return null;
        });
  }

  @override
  Future<bool> checkUserById(String uid) async {
    try {
      final doc = await _userCollection.doc(uid).get();
      return doc.exists;
    } catch (e) {
      print("❌ Error checking user existence: $e");
      return false;
    }
  }

  /// Add new doc to users collection
  /// [user] is data of new user
  /// Created by NDH
  Future<void> addUserData(UserModel newUser) async {
    await _userCollection
        .doc(newUser.id)
        .set(newUser.toMap())
        .catchError((error) => print(error));
  }

  /// Update a doc in users collection
  /// [user] is updated data of user
  /// Created by NDH
  @override
  Future<void> updateUserData(id, updatedUser) async {
    await _userCollection
        .doc(id)
        .get()
        .then((doc) async {
          if (doc.exists) {
            // update
            await doc.reference.update(updatedUser);
          }
        })
        .catchError((error) {});
  }

  ///Singleton factory
  static final FirebaseUserRepository _instance =
      FirebaseUserRepository._internal();

  factory FirebaseUserRepository() {
    return _instance;
  }

  FirebaseUserRepository._internal();
}
