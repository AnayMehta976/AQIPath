import 'package:aqi_app/app_view.dart';
import 'package:aqi_app/configs/localNotificationServices.dart';
import 'package:aqi_app/configs/navigationservices.dart';
import 'package:aqi_app/configs/notification_services.dart';
import 'package:aqi_app/configs/size_config.dart';
import 'package:aqi_app/utils/Background_services/applifecycleobserver.dart';
// import 'package:background_locator_2/background_locator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/local/HiveLDB/Hive_base.dart';
import 'presentation/common_blocs/common_bloc.dart';
import 'presentation/common_blocs/simple_bloc_observer.dart';

final localNotificationService = LocalNotificationService();
void main() async {
  // NavigationService();
  WidgetsFlutterBinding.ensureInitialized();
  final lifecycleObserver = AppLifecycleObserver();
  WidgetsBinding.instance.addObserver(lifecycleObserver);
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await HiveBasemodel.initilizeHive();
  SystemUiOverlayStyle(statusBarColor: Colors.transparent);
  // Lock the app to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  Bloc.observer = SimpleBlocObserver();
  await Firebase.initializeApp();
  await NotificationService().init();

  await localNotificationService.create();
  runApp(MyApp());
}

// This widget is the root of your application.
class MyApp extends StatelessWidget {
  const MyApp({super.key}); // added key support

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: CommonBloc.blocProviders,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return OrientationBuilder(
            builder: (context, orientation) {
              SizeConfig().init(constraints, orientation);
              return AppView(); // use const if possible
            },
          );
        },
      ),
    );
  }
}
