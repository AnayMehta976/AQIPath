import 'package:aqi_app/configs/network.dart';
import 'package:aqi_app/configs/notification_services.dart';
import 'package:aqi_app/data/models/models.dart';
import 'package:aqi_app/data/repository/repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rxdart/rxdart.dart';

import 'package:aqi_app/data/repository/app_repository.dart';
import 'package:aqi_app/data/repository/auth_repository/auth_repo.dart';
import '../../../../utils/utils.dart';
import 'bloc.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository _authRepository = AppRepository.authRepository;
  final UserRepository _userrepo = FirebaseUserRepository();
  LoginBloc() : super(LoginState.empty()) {
    on<EmailChanged>(
      _onEmailChanged,
      transformer: debounce(const Duration(milliseconds: 300)),
    );
    on<PasswordChanged>(
      _onPasswordChanged,
      transformer: debounce(const Duration(milliseconds: 300)),
    );
    on<LoginWithCredential>(_onLoginWithCredential);
    on<LoginWithGoogleSign>(_onLoginWithGoogle);
    on<LoginWithAppleSign>(_onLoginWithApple);
  }

  void _onEmailChanged(EmailChanged event, Emitter<LoginState> emit) {
    final isValid = UtilValidators.isValidEmail(event.email);
    emit(state.update(isEmailValid: isValid));
  }

  void _onPasswordChanged(PasswordChanged event, Emitter<LoginState> emit) {
    final isValid = UtilValidators.isValidPassword(event.password);
    emit(state.update(isPasswordValid: isValid));
  }

  Future<void> _onLoginWithCredential(
    LoginWithCredential event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginState.logging());
    try {
      if (await Network.isConnected()) {
        await _authRepository.logInWithEmailAndPassword(
          event.email,
          event.password,
        );

        final isLoggedIn = _authRepository.isLoggedIn();

        if (isLoggedIn) {
          try {
            final appversion = await PackageInfo.fromPlatform();
            await _userrepo
                .updateUserData(_authRepository.loggedFirebaseUser.uid, {
                  "firebaseToken": await NotificationService().generateToken(),
                  "app_version": appversion.version,
                });
          } catch (e) {}
          emit(LoginState.success());
        } else {
          final message = _authRepository.authException;
          emit(LoginState.failure(message));
        }
      } else {
        UtilDialog.showRetry(
          title: "No Internet Connection ?",
          content: "NO Internet Connection found. Please Connect with internet",
          onClose: () {
            // return getSystemConfig();
            add(event);
          },
        );
      }
    } catch (_) {
      emit(LoginState.failure("Login Failure"));
    }
  }

  Future<void> _onLoginWithGoogle(event, Emitter<LoginState> emit) async {
    emit(LoginState.logging());
    try {
      if (await Network.isConnected()) {
        await _authRepository.logInWithGoogle();
        final isLoggedIn = _authRepository.isLoggedIn();

        if (isLoggedIn) {
          try {
            final appversion = await PackageInfo.fromPlatform();
            await _userrepo
                .updateUserData(_authRepository.loggedFirebaseUser.uid, {
                  "firebaseToken": await NotificationService().generateToken(),
                  "app_version": appversion.version,
                });
          } catch (e) {}
          emit(LoginState.success());
        } else {
          final message = _authRepository.authException;
          emit(LoginState.failure(message));
        }
      } else {
        UtilDialog.showRetry(
          title: "No Internet Connection ?",
          content: "NO Internet Connection found. Please Connect with internet",
          onClose: () {
            // return getSystemConfig();
            add(event);
          },
        );
      }
    } catch (_) {
      final message = _authRepository.authException;
      emit(LoginState.failure("Login Failure\n$message"));
    }
  }

  Future<void> _onLoginWithApple(event, Emitter<LoginState> emit) async {
    emit(LoginState.logging());
    try {
      if (await Network.isConnected()) {
        await _authRepository.logInWithApple();
        final isLoggedIn = _authRepository.isLoggedIn();

        if (isLoggedIn) {
          try {
            final appversion = await PackageInfo.fromPlatform();
            await _userrepo
                .updateUserData(_authRepository.loggedFirebaseUser.uid, {
                  "firebaseToken": await NotificationService().generateToken(),
                  "app_version": appversion.version,
                });
          } catch (e) {}
          emit(LoginState.success());
        } else {
          final message = _authRepository.authException;
          emit(LoginState.failure(message));
        }
      } else {
        UtilDialog.showRetry(
          title: "No Internet Connection ?",
          content: "NO Internet Connection found. Please Connect with internet",
          onClose: () {
            // return getSystemConfig();
            add(event);
          },
        );
      }
    } catch (_) {
      final message = _authRepository.authException;
      emit(LoginState.failure("Login Failure\n$message"));
    }
  }

  /// Debounce helper for BLoC 8
  EventTransformer<T> debounce<T>(Duration duration) {
    return (events, mapper) => events.debounceTime(duration).switchMap(mapper);
  }
}
