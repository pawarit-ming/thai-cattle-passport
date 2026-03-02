import Flutter
import UIKit
import GoogleMaps // <--- 1. เพิ่มบรรทัดนี้ (ต้อง import เสมอถ้าใช้แผนที่)

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // <--- 2. เพิ่มบรรทัดนี้ และนำ API Key ของ iOS จาก Google Cloud Console มาใส่
    GMSServices.provideAPIKey("ใส่_API_KEY_ของ_GOOGLE_MAPS_ที่นี่")
      
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}