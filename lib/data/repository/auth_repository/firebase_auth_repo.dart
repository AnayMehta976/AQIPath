import 'dart:convert';
import 'dart:math';

import 'package:aqi_app/configs/notification_services.dart';
import 'package:aqi_app/data/models/user_model.dart';
import 'package:aqi_app/data/repository/repository.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseUserRepository _userRepository = FirebaseUserRepository();
  String _authException = "Authentication Failure";
  @override
  User get loggedFirebaseUser => _firebaseAuth.currentUser!;
  @override
  String get authException => _authException;

  /// Don't use onAuthChange

  /// Creates a new user with the provided [information]
  /// Created by jk
  @override
  Future<void> signUp(UserModel newUser, String password) async {
    try {
      var userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: newUser.email,
        password: password,
      );
      // Add id for new user
      final appversion = await PackageInfo.fromPlatform();
      newUser = newUser.cloneWith(
        id: userCredential.user!.uid,
        passward: password,
        fbtoken: await NotificationService().generateToken(),
        appversion: appversion.version,
      );

      // Create new doc in users collection
      await _userRepository.addUserData(newUser);
    } on FirebaseAuthException catch (e) {
      _authException = e.message.toString();
    }
  }

  /// Signs in with the provided [email] and [password].
  /// Created by jk
  @override
  Future<void> logInWithEmailAndPassword(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      _authException = e.message.toString();
    }
  }

  // /// Starts the Sign In with Google Flow.
  // /// Created by jk
  @override
  Future<void> logInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();

      final googleAuth = await googleUser!.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential authResult = await _firebaseAuth
          .signInWithCredential(credential);

      final User? user = authResult.user;

      if (user != null) {
        final String userId = user.uid;
        final String? email = user.email;
        final String? name = user.displayName;
        final String? phoneNumber = user.phoneNumber;

        final existingUser = await _userRepository.checkUserById(userId);

        if (!existingUser) {
          final appversion = await PackageInfo.fromPlatform();
          // User doesn't exist, create a new one
          final newUser = UserModel(
            id: userId,
            email: email ?? '',
            name: name ?? '',
            phoneNumber: phoneNumber ?? '',
            passward: '', // Or null if not used
            fbtoken: await NotificationService().generateToken(),
            appversion: appversion.version,
          );
          await _userRepository.addUserData(newUser);
          print("✅ User added");
        } else {
          print("✅ Existing user logged in.");
        }
      }
    } on FirebaseAuthException catch (e) {
      _authException = e.message.toString();
    }
  }

  /// ---------Sign In With Apple ---------
  ///
  // Step 1: Generate nonce
  String generateNonce([int length = 32]) {
    final charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Future<void> logInWithApple() async {
    try {
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      // Step 2: Trigger Apple Sign-In
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        // nonce: nonce,
      );

      // Step 3: Create Firebase credential
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        // rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      // Step 4: Sign in with Firebase
      final UserCredential authResult = await _firebaseAuth
          .signInWithCredential(oauthCredential);

      final User? user = authResult.user;

      if (user != null) {
        print(
          "✅ Apple user logged in. UID: ${user.uid} name: ${user.displayName} email: ${user.email} givenName: ${appleCredential.givenName} familyName: ${appleCredential.familyName}",
        );
        final String userId = user.uid;
        final String? email = user.email;
        final String? name =
            user.displayName ??
            '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                .trim();
        final String? phoneNumber = user.phoneNumber;

        // Step 5: Check user existence
        final existingUser = await _userRepository.checkUserById(userId);

        if (!existingUser) {
          final appversion = await PackageInfo.fromPlatform();
          final newUser = UserModel(
            id: userId,
            email: email ?? '',
            name: name ?? '',
            phoneNumber: phoneNumber ?? '',
            passward: '', // not used
            fbtoken: await NotificationService().generateToken(),
            appversion: appversion.version,
          );
          await _userRepository.addUserData(newUser);
          print("✅ Apple user added");
        } else {
          print("✅ Existing Apple user logged in.");
        }
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      _authException = e.message;
      print("❌ Apple Sign-In error: ${e.message}");
    } on FirebaseAuthException catch (e) {
      _authException = e.message.toString();
      print("❌ Firebase Auth error: ${e.message}");
    } catch (e) {
      print("❌ Unknown Apple Sign-In error: $e");
    }
  }

  bool isLoggedIn() => _firebaseAuth.currentUser != null;

  /// Signs out the current user
  /// Created by jk
  Future<void> logOut() async {
    await _firebaseAuth.signOut().catchError((error) {
      print(error);
    });
  }

  ///Singleton factory
  static final FirebaseAuthRepository _instance =
      FirebaseAuthRepository._internal();

  factory FirebaseAuthRepository() {
    return _instance;
  }

  FirebaseAuthRepository._internal();
}
