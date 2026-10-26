import Flutter
import UIKit
import GoogleMaps
import background_locator_2
import flutter_local_notifications

func registerPlugins(registry: FlutterPluginRegistry) -> () {
    if (!registry.hasPlugin("BackgroundLocatorPlugin")) {
        GeneratedPluginRegistrant.register(with: registry)
    }
}
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      // Maps key comes from ios/Flutter/Secrets.xcconfig via the GMSApiKey entry in Info.plist
      let mapsKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String ?? ""
      GMSServices.provideAPIKey(mapsKey)
//      FirebaseApp.configure()
      if #available(iOS 10.0, *) {
        UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
      }
      
      GeneratedPluginRegistrant.register(with: self)
      BackgroundLocatorPlugin.setPluginRegistrantCallback(registerPlugins)
      
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    @available(iOS 12.0, *)
     override func userNotificationCenter(
         _ center: UNUserNotificationCenter,
         openSettingsFor notification: UNNotification?
     ) {
         let controller = window?.rootViewController as! FlutterViewController
         let channel = FlutterMethodChannel(
             name: "com.example.flutter_local_notifications_example/settings",
             binaryMessenger: controller.binaryMessenger)
         channel.invokeMethod("showNotificationSettings", arguments: nil)
     }
}
