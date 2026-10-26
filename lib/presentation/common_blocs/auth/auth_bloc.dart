import 'package:aqi_app/configs/navigationservices.dart';
import 'package:aqi_app/configs/network.dart';
import 'package:aqi_app/configs/router.dart';
import 'package:aqi_app/data/local/pref.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import '../../../data/repository/repository.dart';
import 'auth_state.dart';
import 'bloc.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  final AuthRepository _authRepository = AppRepository.authRepository;

  AuthenticationBloc() : super(Uninitialized()) {
    on<AuthenticationStarted>(_onAuthenticationStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
  }

  Future<void> _onAuthenticationStarted(
    AuthenticationStarted event,
    Emitter<AuthenticationState> emit,
  ) async {
    try {
      // Optional splash delay
      if (await Network.isConnected()) {
        await Future.delayed(Duration(seconds: 2));
        final isLoggedIn = _authRepository.isLoggedIn();
        if (isLoggedIn) {
          final user = _authRepository.loggedFirebaseUser;
          emit(Authenticated(user));
        } else {
          emit(Unauthenticated());
        }
      } else {
        debugPrint("No Internet Connection found");
        if (NavigationService.navigatorKey.currentContext != null) {
          Navigator.pushNamed(
            NavigationService.navigatorKey.currentContext!,
            AppRouter.NetworkErrorScreen,
          ).then((value) {
            add(AuthenticationStarted());
          });
        } else {
          debugPrint(
            "Context is null, cannot navigate to Network Error Screen",
          );
        }

        // UtilDialog.showRetry(
        //   title: "Network Issue ?",
        //   content: "NO Internet Connection found. Please Connect with internet",
        //   onClose: () {
        //     add(AuthenticationStarted());
        //   },
        // );
      }
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  void _onLoggedIn(LoggedIn event, Emitter<AuthenticationState> emit) async {
    if (await Network.isConnected()) {
      final user = _authRepository.loggedFirebaseUser;
      emit(Authenticated(user));
    } else {
      Navigator.pushNamed(
        NavigationService.navigatorKey.currentContext!,
        AppRouter.NetworkErrorScreen,
      ).then((value) {
        add(AuthenticationStarted());
      });
      // UtilDialog.showRetry(
      //   title: "Network Issue ?",
      //   content: "NO Internet Connection found. Please Connect with internet",
      //   onClose: () {
      //     // return getSystemConfig();
      //     add(LoggedIn());
      //   },
      // );
    }
  }

  void _onLoggedOut(LoggedOut event, Emitter<AuthenticationState> emit) async {
    if (await Network.isConnected()) {
      await _authRepository.logOut();
      LocalPref.clear();
      onNavigateremoveuntil(AppRouter.SPLASH);
      await Future.delayed(Duration(seconds: 2));
      emit(Unauthenticated());
    } else {
      Navigator.pushNamed(
        NavigationService.navigatorKey.currentContext!,
        AppRouter.NetworkErrorScreen,
      ).then((value) {
        add(AuthenticationStarted());
      });
      // UtilDialog.showRetry(
      //   title: "Network Issue ?",
      //   content: "NO Internet Connection found. Please Connect with internet",
      //   onClose: () {
      //     // return getSystemConfig();
      //     add(LoggedOut());
      //   },
      // );
    }
  }

  void onNavigateremoveuntil(String route) {
    final _navigator = NavigationService.navigatorKey.currentState;
    _navigator!.pushNamedAndRemoveUntil(route, ModalRoute.withName('/'));
  }
}
