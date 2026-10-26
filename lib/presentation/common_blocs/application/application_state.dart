import 'package:equatable/equatable.dart';

import 'package:aqi_app/data/models/systemConfigmodel.dart';

abstract class ApplicationState extends Equatable {
  const ApplicationState();

  @override
  List<Object> get props => [];
}

class ApplicationInitial extends ApplicationState {}

class ApplicationCompleted extends ApplicationState {}

class ApplicationUpdateDialog extends ApplicationState {
  SystemConfig systemConfig;
  final String pkgName;
  ApplicationUpdateDialog({required this.systemConfig, required this.pkgName});

  @override
  // TODO: implement props
  List<Object> get props => [systemConfig, pkgName];
}
