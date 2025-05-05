import Flutter
import UIKit
import AdSupport
import AppTrackingTransparency
import Foundation
import GoogleMobileAds
import PrebidMobile
import os

public class SwiftSetupadPrebidFlutterPlugin: NSObject, FlutterPlugin {

  public static func register(with registrar: FlutterPluginRegistrar) {
    registrar.register(PrebidBannerFactory(messenger: registrar.messenger()), withId: "setupad.plugin.setupad_prebid_flutter")

    let channel = FlutterMethodChannel(name: "setupad_prebid_flutter", binaryMessenger: registrar.messenger())
    let instance = SwiftSetupadPrebidFlutterPlugin()

    let iosChannel = FlutterMethodChannel(name: "setupad.plugin.setupad_prebid_flutter/ios_init", binaryMessenger: registrar.messenger())

    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addMethodCallDelegate(instance, channel: iosChannel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
          if call.method == "startPrebid" {
              guard let arguments = call.arguments as? [String: Any] else {
                  result(FlutterError(
                      code: "INVALID_ARGUMENTS",
                      message: "Arguments are not a dictionary",
                      details: nil
                  ))
                  return
              }

              let serverHost = arguments["host"] as? String ?? ""
              let accountId = arguments["accountID"] as? String ?? ""

              if serverHost.isEmpty || accountId.isEmpty {
                  result(FlutterError(
                      code: "MISSING_ARGUMENTS",
                      message: "Missing 'host' or 'accountID'",
                      details: [
                          "host": serverHost,
                          "accountID": accountId
                      ]
                  ))
                  return
              }

              Prebid.shared.prebidServerAccountId = accountId

              do {
                  try Prebid.initializeSDK(
                      serverURL: serverHost,
                      gadMobileAdsVersion: String(describing: MobileAds.shared.versionNumber)
                  ) { status, error in
                      switch status {
                      case .succeeded:
                          result("Prebid SDK initialized successfully")
                      case .failed:
                          result(FlutterError(
                              code: "INIT_FAILED",
                              message: "Prebid SDK initialization failed",
                              details: error?.localizedDescription
                          ))
                      case .serverStatusWarning:
                      print("Prebid SDK Server Status warning")
//                           result(FlutterError(
//                               code: "INIT_WARNING",
//                               message: "Prebid SDK Server Status warning",
//                               details: error?.localizedDescription
//                           ))
                      default:
                          result(FlutterError(
                              code: "INIT_UNKNOWN",
                              message: "Unknown initialization status",
                              details: [
                                  "host": serverHost,
                                  "accountID": accountId
                              ]
                          ))
                      }
                  }
              } catch {
                  result(FlutterError(
                      code: "INIT_EXCEPTION",
                      message: "Exception during Prebid SDK initialization",
                      details: error.localizedDescription
                  ))
              }

              MobileAds.shared.start()

          } else {
              result(FlutterMethodNotImplemented)
          }
      }

}
