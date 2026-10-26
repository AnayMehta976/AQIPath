import 'package:equatable/equatable.dart';

enum HomeError { networkError, locationError }

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

/// Loading
class HomeLoading extends HomeState {}

/// Adready data
class HomeLoaded extends HomeState {
  final Map homeResponse;

  const HomeLoaded({required this.homeResponse});

  @override
  List<Object?> get props => [homeResponse];
}

/// Cange of tag
class HomeLoadSwitch extends HomeState {
  final bool value;

  const HomeLoadSwitch({required this.value});
  @override
  List<Object?> get props => [value];
}

/// Failure
class HomeLoadFailure extends HomeState {
  final HomeError errorType;
  final String error;

  const HomeLoadFailure(this.errorType, this.error);
}
