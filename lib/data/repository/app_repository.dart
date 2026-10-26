import 'package:aqi_app/data/repository/auth_repository/firebase_auth_repo.dart';
import 'package:aqi_app/data/repository/user_repository/firebase_user_repo.dart';

class AppRepository {
  /// Repository
  static final authRepository = FirebaseAuthRepository();
  static final userRepository = FirebaseUserRepository();
  // static final storageRepository = StorageRepository();

  /// Singleton factory
  static final AppRepository _instance = AppRepository._internal();

  factory AppRepository() {
    return _instance;
  }
  AppRepository._internal();
}
