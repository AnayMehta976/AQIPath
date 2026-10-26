
import 'package:aqi_app/utils/toast.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';

// import 'package:app_settings/app_settings.dart';
// import '../routes/app_router.dart';

class NetworkErrorPage extends StatelessWidget {
  // final VoidCallback? onConnected;

  const NetworkErrorPage({super.key});

  Future<void> _retry(BuildContext context) async {
    final result = await Connectivity().checkConnectivity();
    print("Connectivity Result: $result");
    if (result[0] != ConnectivityResult.none) {
      // Notify caller that connection is established
      try {
        // onConnected?.call();
        Navigator.pop(context, true);
      } catch (e) {
        // swallow callback errors but log them
        debugPrint('onConnected callback error: $e');
      }

      // Navigator.pushReplacementNamed(context, AppRouter.SPLASH);
      // CommonBloc.applicationBloc.add(SetupApplication());
    } else {
      UtilToast.showMessageForUser(
        context,
        'Still no connection. Please try again.',
        tostgravity: ToastGravity.BOTTOM,
      );
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text(''),
      //     behavior: SnackBarBehavior.floating,
      //   ),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mock AQI data (to show even when offline)
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🔴 Offline Icon
                const Icon(Icons.wifi_off, size: 100, color: Colors.redAccent),
                const SizedBox(height: 24),

                const Text(
                  'No Internet Connection',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                const Text(
                  'We couldn’t connect to the network.\nCheck your internet or Wi-Fi settings and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),

                const SizedBox(height: 32),

                // 🔁 Retry Button
                FractionallySizedBox(
                  widthFactor: 0.8,
                  child: ElevatedButton.icon(
                    onPressed: () => _retry(context),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Connection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ⚙️ Open Network Settings
                // OutlinedButton.icon(
                //   onPressed: () {
                //     if (Platform.isIOS) {
                //       AppSettings.openAppSettings(type: AppSettingsType.wifi);
                //     } else {
                //       AppSettings.openAppSettingsPanel(AppSettingsPanelType.wifi);
                //     }
                //   },
                //   icon: const Icon(Icons.settings),
                //   label: const Text('Open Network Settings'),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
