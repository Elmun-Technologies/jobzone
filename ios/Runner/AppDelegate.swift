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
    YMKMapKit.setApiKey("1d02f6b0-05d4-4eb6-ae5b-eea72724a6ff")
    YMKMapKit.setLocale("ru_RU")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
