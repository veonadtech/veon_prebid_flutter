import Flutter
import UIKit

public class SwiftSetupadPrebidFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    registrar.register(PrebidBannerFactory(messenger: registrar.messenger()), withId: "setupad.plugin.setupad_prebid_flutter")
//    registrar.register(PrebidBannerFactory(messenger: registrar.messenger()), withId: "setupad.plugin.setupad_prebid_flutter/ios")

    let channel = FlutterMethodChannel(name: "setupad_prebid_flutter", binaryMessenger: registrar.messenger())
    let instance = SwiftSetupadPrebidFlutterPlugin()

    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
