import GoogleMobileAds
import PrebidMobile

public class SwiftSetupadPrebidFlutterPlugin: NSObject {
    
    // MARK: - Constants
    private enum ChannelNames {
        static let main = "setupad_prebid_flutter"
        static let platformSpecific = "setupad.plugin.setupad_prebid_flutter/ios_init"
        static let factory = "setupad.plugin.setupad_prebid_flutter"
    }
    
    // MARK: - Private Methods
    func handleStartPrebid(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any] else {
            NSLog("LOG: Invalid arguments for startPrebid")
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        let serverHost = arguments["host"] as? String ?? ""
        let accountId = arguments["accountID"] as? String ?? ""
        let timeoutMills = arguments["timeoutMillis"] as? Int ?? 30000
        
        NSLog("LOG: init iOS SDK")
        NSLog("LOG: host: \(serverHost)")
        NSLog("LOG: accountId: \(accountId)")
        NSLog("LOG: timeoutMills: \(timeoutMills)")
        
        Prebid.shared.prebidServerAccountId = accountId
        Prebid.shared.timeoutMillis = timeoutMills
        Prebid.shared.logLevel = .debug
        
        do {
            try Prebid.initializeSDK(
                serverURL: serverHost,
                gadMobileAdsVersion: string(for: MobileAds.shared.versionNumber)
            ) { status, error in
                self.handlePrebidInitializationResult(status: status, error: error)
                result(nil) // Return success
            }
        } catch {
            NSLog("LOG: ERROR initializing Prebid SDK: \(error.localizedDescription)")
            result(FlutterError(code: "INIT_ERROR", message: "Failed to initialize Prebid SDK", details: error.localizedDescription))
        }
    }
    
    func handlePrebidInitializationResult(status: PrebidInitializationStatus, error: Error?) {
        switch status {
        case .succeeded:
            NSLog("LOG: Prebid SDK successfully initialized")
        case .failed:
            if let error {
                NSLog("LOG: An error occurred during Prebid SDK initialization: \(error.localizedDescription)")
            }
        case .serverStatusWarning:
            if let error {
                NSLog("LOG: Prebid Server status checking failed: \(error.localizedDescription)")
            }
        default:
            break
        }
    }
    
}

// MARK: - FlutterPlugin Extension
extension SwiftSetupadPrebidFlutterPlugin: FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        // Register platform view factory
        registrar.register(
            PrebidBannerFactory(messenger: registrar.messenger()),
            withId: ChannelNames.factory
        )
        
        // Setup method channels
        let mainChannel = FlutterMethodChannel(
            name: ChannelNames.main,
            binaryMessenger: registrar.messenger()
        )
        
        let iosChannel = FlutterMethodChannel(
            name: ChannelNames.platformSpecific,
            binaryMessenger: registrar.messenger()
        )
        
        // Register instance as delegate for both channels
        let instance = SwiftSetupadPrebidFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: mainChannel)
        registrar.addMethodCallDelegate(instance, channel: iosChannel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "startPrebid" {
            handleStartPrebid(call: call, result: result)
        } else {
            NSLog("LOG: Method not implemented: \(call.method)")
            result(FlutterMethodNotImplemented)
        }
    }
    
}
