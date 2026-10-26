import 'package:firebase_auth/firebase_auth.dart';

import '../../models/models.dart';

abstract class AuthRepository {
  User get loggedFirebaseUser;
  String get authException;

  /// Creates a new user with the provided [information]
  /// Created by jk
  Future<void> signUp(UserModel newUser, String password);

  /// Signs in with the provided [email] and [password].
  /// Created by jk
  Future<void> logInWithEmailAndPassword(String email, String password);

  /// Starts the Sign In with Google Flow.
  /// Created by JK
  Future<void> logInWithGoogle();

  /// Starts the Sign In with Apple Flow.
  /// Created by JK
  Future<void> logInWithApple();
  /// Returns true if there is a user currently logged in.
  bool isLoggedIn();

  /// Signs out the current user
  /// Created by jk
  Future<void> logOut();
}
