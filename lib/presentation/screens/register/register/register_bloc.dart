import 'dart:async';

import 'package:aqi_app/configs/network.dart';
import 'package:aqi_app/utils/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../utils/validator.dart';
import 'bloc.dart';
import 'package:aqi_app/data/repository/app_repository.dart';
import 'package:aqi_app/data/repository/auth_repository/auth_repo.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthRepository _authRepository = AppRepository.authRepository;

  RegisterBloc() : super(RegisterState.empty()) {
    // Debounced handlers
    on<EmailChanged>(_onEmailChanged, transformer: debounce());
    on<NumberChanged>(_onNumberChanged, transformer: debounce());
    on<NameChanged>(_onNameChanged, transformer: debounce());
    on<PasswordChanged>(_onPasswordChanged, transformer: debounce());
    on<ConfirmPasswordChanged>(
      _onConfirmPasswordChanged,
      transformer: debounce(),
    );

    // Immediate handlers
    on<Submitted>(_onFormSubmitted);
  }

  /// Debounce transformer (300ms)
  EventTransformer<T> debounce<T>() {
    return (events, mapper) => events
        .debounceTime(const Duration(milliseconds: 300))
        .switchMap(mapper);
  }

  /// Handle email input
  Future<void> _onEmailChanged(
    EmailChanged event,
    Emitter<RegisterState> emit,
  ) async {
    emit(state.update(isEmailValid: UtilValidators.isValidEmail(event.email)));
  }

  /// Handle email input
  Future<void> _onNameChanged(
    NameChanged event,
    Emitter<RegisterState> emit,
  ) async {
    emit(state.update(isNameValid: UtilValidators.isValidName(event.name)));
  }

  /// Handle email input
  Future<void> _onNumberChanged(
    NumberChanged event,
    Emitter<RegisterState> emit,
  ) async {
    emit(
      state.update(
        isNumberValid: UtilValidators.isVietnamesePhoneNumber(event.number),
      ),
    );
  }

  /// Handle password input
  Future<void> _onPasswordChanged(
    PasswordChanged event,
    Emitter<RegisterState> emit,
  ) async {
    final isPasswordValid = UtilValidators.isValidPassword(event.password);
    emit(state.update(isPasswordValid: isPasswordValid));
  }

  /// Handle confirm password input
  Future<void> _onConfirmPasswordChanged(
    ConfirmPasswordChanged event,
    Emitter<RegisterState> emit,
  ) async {
    final isConfirmPasswordValid = UtilValidators.isValidPassword(
      event.confirmPassword,
    );
    final isMatched =
        event.password.isNotEmpty && event.password == event.confirmPassword;

    emit(
      state.update(isConfirmPasswordValid: isConfirmPasswordValid && isMatched),
    );
  }

  /// Handle form submission
  Future<void> _onFormSubmitted(
    Submitted event,
    Emitter<RegisterState> emit,
  ) async {
    try {
      if (await Network.isConnected()) {
        emit(RegisterState.loading());
        await _authRepository.signUp(event.newUser, event.password);

        final isLoggedIn = _authRepository.isLoggedIn();
        if (isLoggedIn) {
          debugPrint("Is login");
          emit(RegisterState.success());
        } else {
          debugPrint("Not login");
          emit(RegisterState.failure(_authRepository.authException));
        }
      } else {
        UtilDialog.showRetry(
          title: "Please Check your Internet Connection",
          content: "NO Internet Connection found. Please Connect with internet",
          onClose: () {
            // return getSystemConfig();
            add(event);
          },
        );
      }
    } catch (_) {
      emit(RegisterState.failure("Register Failure"));
    }
  }
}
