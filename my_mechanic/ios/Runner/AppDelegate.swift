import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Get API key from environment or use a placeholder
    // You'll need to replace this with your actual Google Maps API key
    GMSServices.provideAPIKey("AIzaSyA2za4xMdxNTbpHcBAbV2gIfSE0mn9eKQk")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
