import Flutter
import UIKit
import YandexMapsMobile

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Yandex MapKit. Get a free "MapKit Mobile SDK" key at
    // https://developer.tech.yandex.ru/ and restrict it to this bundle id.
    YMKMapKit.setApiKey("PASTE_YOUR_YANDEX_MAPKIT_API_KEY")
    YMKMapKit.setLocale("ru_RU")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
