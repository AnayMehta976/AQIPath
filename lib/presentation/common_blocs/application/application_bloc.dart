import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aqi_app/configs/navigationservices.dart';
import 'package:aqi_app/configs/network.dart';

import 'package:aqi_app/configs/router.dart';
import 'package:aqi_app/constants/key_constant.dart';
import 'package:aqi_app/data/models/systemConfigmodel.dart';
import 'package:aqi_app/utils/dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:aqi_app/configs/application.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../data/local/pref.dart';
import '../auth/bloc.dart';
import '../common_bloc.dart';
import '../language/bloc.dart';
import 'application_event.dart';
import 'application_state.dart';

class ApplicationBloc extends Bloc<ApplicationEvent, ApplicationState> {
  final Application application = Application();

  ApplicationBloc() : super(ApplicationInitial()) {
    on<SetupApplication>(_onSetupApplication);
    on<SetuplaterApplication>(_onsetuplaterApplication);
  }

  Future<void> _onSetupApplication(
    SetupApplication event,
    Emitter<ApplicationState> emit,
  ) async {
    /// Setup SharedPreferences
    await application.setPreferences();

    /// Get old settings
    final oldLanguage = LocalPref.getString("language");

    if (oldLanguage != null) {
      CommonBloc.languageBloc.add(LanguageChanged(Locale(oldLanguage)));
    }
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version; // App version
    String buildNumber = packageInfo.buildNumber; // Build number
    String packageName = packageInfo.packageName;
    // String systemsource = packageInfo.
    debugPrint("I am herein Package Info $packageInfo");
    SystemConfig? scnfg = await getSystemConfig();
    debugPrint("here:  " + scnfg.toString());
    if (scnfg != null) {
      // debugPrint("here change:  " + scnfg.changeLog.toString());
      if (scnfg.versionName != version.toString() &&
          int.parse(buildNumber) < scnfg.versionCode! &&
          Platform.isAndroid) {
        // Show dialog if the current version is not the latest
        emit(
          ApplicationUpdateDialog(systemConfig: scnfg, pkgName: packageName),
        );
      } else if (scnfg.versionNameIos != version.toString() &&
          int.parse(buildNumber) < scnfg.versionCodeIos! &&
          Platform.isIOS) {
        // Show dialog if the current version is not the latest
        emit(
          ApplicationUpdateDialog(systemConfig: scnfg, pkgName: packageName),
        );
      } else {
        /// Authentication begin check
        CommonBloc.authencationBloc.add(AuthenticationStarted());

        emit(ApplicationCompleted());
      }
    } else {
      /// Authentication begin check
      CommonBloc.authencationBloc.add(AuthenticationStarted());

      emit(ApplicationCompleted());
    }
  }

  static Future<SystemConfig?> getSystemConfig() async {
    try {
      debugPrint("i am here in syscnfg start");
      final String? lastFetch = LocalPref.getString(SavedKey.LASTSYNC);
      final DateTime now = DateTime.now();

      if (lastFetch != null) {
        final lastDate = DateTime.tryParse(lastFetch);
        if (lastDate != null && now.difference(lastDate).inMinutes < 5) {
          final cachedData = LocalPref.getString(SavedKey.CONFIG_DATA);
          if (cachedData != null) {
            debugPrint("i am here in backup");
            return SystemConfig.fromJson(jsonDecode(cachedData));
          }
        }
      }

      if (await Network.isConnected()) {
        final doc =
            await FirebaseFirestore.instance
                .collection("SystemConfig")
                .doc("V1fzgfJhDItQRxDbCV6x")
                .get();
        debugPrint("my firnbase data: ${doc.data()}");
        if (doc.exists && doc.data() != null) {
          final configData = SystemConfig.fromJson(doc.data()!);

          LocalPref.setString(
            SavedKey.CONFIG_DATA,
            jsonEncode(configData.toJson()),
          );
          LocalPref.setString(SavedKey.LASTSYNC, now.toIso8601String());
          return configData;
        }
      } else {
        Navigator.pushNamed(
          NavigationService.navigatorKey.currentContext!,
          AppRouter.NetworkErrorScreen,
        ).then((value) {
          // CommonBloc.applicationBloc.add(SetupApplication());
          getSystemConfig();
        });
        // UtilDialog.showRetry(
        //   title: "Network Error ?",
        //   content: "NO Internet Connection found. Please Connect with internet",
        //   onClose: () {
        //     return getSystemConfig();
        //   },
        // );
      }
    } catch (e) {
      UtilDialog.showRetry(
        title: "Something Wnet Wrong?",
        content:
            "Please Make Sure are Connected with Internet. Then Please Retry!",
        onClose: () {
          return getSystemConfig();
        },
      );
    }

    return null;
  }

  FutureOr<void> _onsetuplaterApplication(
    SetuplaterApplication event,
    Emitter<ApplicationState> emit,
  ) {
    /// Authentication begin check
    CommonBloc.authencationBloc.add(AuthenticationStarted());

    emit(ApplicationCompleted());
  }
}
