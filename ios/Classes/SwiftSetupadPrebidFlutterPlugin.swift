import AdSupport
import AppTrackingTransparency
import Flutter
import Foundation
import GoogleMobileAds
import PrebidMobile
import UIKit
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
            //         throw Error("Method not implemented")
            let argument = call.arguments as! [String: Any]
            let serverHost = argument["host"] as? String ?? ""
            let accountId = argument["accountID"] as? String ?? ""
            print("init iOS SDK")
            print("host: \(serverHost)")
            print("accountId: \(accountId)")
            NSLog("host: \(serverHost)")
            NSLog("accountId: \(accountId)")
            Prebid.shared.prebidServerAccountId = accountId
            do {
                try Prebid.initializeSDK(
                    serverURL: serverHost,
                    gadMobileAdsVersion: string(for: MobileAds.shared.versionNumber)
                ) { status, error in
                    switch status {
                    case .succeeded:
                        print("Prebid SDK successfully initialized")
                    case .failed:
                        if let error = error {
                            print("An error occurred during Prebid SDK initialization: \(error.localizedDescription)")
                        }
                    case .serverStatusWarning:
                        if let error = error {
                            print("Prebid Server status checking failed: \(error.localizedDescription)")
                        }
                    default:
                        break
                    }
                }
            } catch {
                print("ERROR")
            }
        }
        // other methods
        else {
            NSLog("init ios channel failed")
            result(FlutterMethodNotImplemented)
        }
    }

}
