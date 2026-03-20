import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Add your Google Maps API key. Get from https://console.cloud.google.com/
    // Enable: Maps SDK for iOS
    GMSServices.provideAPIKey(Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String ?? "")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
