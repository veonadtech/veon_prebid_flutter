import AppTrackingTransparency
import GoogleMobileAds
import PrebidMobile
import PrebidMobileGAMEventHandlers

class PrebidBannerView: NSObject {

    // MARK: - Properties

    /// Container view that holds ad views
    private var container: UIView

    /// Communication channel with Flutter
    private let channel: FlutterMethodChannel

    /// Prebid interstitial rendering ad unit
    private var prebidInterstitial: InterstitialRenderingAdUnit?

    /// Prebid interstitial ad unit
    private var interstitialAdUnit: InterstitialAdUnit?

    // MARK: - Constants

    private enum AdType {
        static let banner = "banner"
        static let interstitial = "interstitial"
    }

    private enum MethodNames {
        static let setParams = "setParams"
        static let demandFetched = "demandFetched"
    }

    private enum ErrorCodes {
        static let loadParameters = "LOAD_PARAMETERS"
    }

    // MARK: - Initialization

    init(frame: CGRect, viewIdentifier viewId: Int64, messenger: FlutterBinaryMessenger) {
        container = UIView(frame: frame)
        channel = FlutterMethodChannel(
            name: "setupad.plugin.setupad_prebid_flutter/ios",
            binaryMessenger: messenger
        )

        super.init()

        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            self.handleMethodCall(call, result: result)
        }
    }

    // MARK: - Private Methods

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case MethodNames.setParams:
            handleSetParams(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleSetParams(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any] else {
            result(
                FlutterError(
                    code: ErrorCodes.loadParameters,
                    message: "Invalid arguments",
                    details: nil
                )
            )
            return
        }

        let adParams = AdParameters(from: arguments)
        logAdParameters(adParams)

        switch adParams.adType {
        case AdType.banner:
            loadBanner(params: adParams)
        case AdType.interstitial:
            loadInterstitialRendering(params: adParams)
        default:
            result(
                FlutterError(
                    code: ErrorCodes.loadParameters,
                    message: "Unknown ad type: \(adParams.adType)",
                    details: arguments
                )
            )
            return
        }

        result(nil)
    }

    // MARK: - Logging

    private func logAdParameters(_ params: AdParameters) {
        NSLog("LOG: adUnit: \(params.adUnitId)")
        NSLog("LOG: configId: \(params.configId)")
        NSLog("LOG: adHeight: \(params.height)")
        NSLog("LOG: adWidth: \(params.width)")
        NSLog("LOG: adType: \(params.adType)")
    }

    // MARK: - Ad Loading Methods

    private func loadBanner(params: AdParameters) {
        let adSize = CGSize(width: params.width, height: params.height)
        let bannerUnit = BannerAdUnit(configId: params.configId, size: adSize)
        let bannerView = BannerView(adSize: adSizeFor(cgSize: adSize))

        bannerView.adUnitID = params.adUnitId
        bannerView.delegate = self
        bannerView.rootViewController = getRootViewController()
        bannerView.backgroundColor = UIColor.clear
        addBannerViewToView(bannerView)

        let request = Request()
        bannerUnit.fetchDemand(adObject: request) { [weak self] (resultCode) in
            guard let self = self else { return }

            self.channel.invokeMethod(MethodNames.demandFetched, arguments: ["name": resultCode.name()])
            if #available(iOS 14, *) {
                ATTrackingManager.requestTrackingAuthorization { [weak bannerView] _ in
                    bannerView?.load(request)
                }
            } else {
                bannerView.load(request)
            }
        }
    }

    private func loadInterstitialRendering(params: AdParameters) {
        let eventHandler = GAMInterstitialEventHandler(adUnitID: params.adUnitId)
        let size = CGSize(width: Int(params.width), height: Int(params.height))

        prebidInterstitial = InterstitialRenderingAdUnit(
            configID: params.configId,
            minSizePercentage: size,
            eventHandler: eventHandler
        )

        prebidInterstitial?.delegate = self

        prebidInterstitial?.loadAd()
    }

    // MARK: - Utility Methods

    private func getRootViewController() -> UIViewController {
        return UIApplication.shared.delegate?.window??.rootViewController ?? UIViewController()
    }

    private func addBannerViewToView(_ bannerView: GoogleMobileAds.BannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bannerView)

        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            bannerView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
    }
}

// MARK: - FlutterPlatformView

extension PrebidBannerView: FlutterPlatformView {
    func view() -> UIView {
        return container
    }
}

// MARK: - InterstitialAdUnitDelegate

extension PrebidBannerView: InterstitialAdUnitDelegate {

    func interstitialDidReceiveAd(_ interstitial: InterstitialRenderingAdUnit) {
        NSLog("LOG: Prebid interstitial has been loaded, we're showing it...")
        let rootViewController = getRootViewController()
        let controllerToPresent = rootViewController.presentedViewController ?? rootViewController
        interstitial.show(from: controllerToPresent)
    }

    func interstitial(_ interstitial: InterstitialRenderingAdUnit, didFailToReceiveAdWithError error: Error?) {
        NSLog("LOG: Error loading Prebid interstitial: \(error?.localizedDescription ?? "unknown error")")
    }

    func interstitialWillLeaveApplication(_ interstitial: InterstitialRenderingAdUnit) {
        NSLog("LOG: User leaves the app via interstitial ad")
    }

    func interstitialDidClickAd(_ interstitial: InterstitialRenderingAdUnit) {
        NSLog("LOG: User left via interstitial ad")
    }

    func interstitialDidCloseAd(_ interstitial: InterstitialRenderingAdUnit) {
        NSLog("LOG: Interstitial is closed")
    }

}

// MARK: - BannerViewDelegate

extension PrebidBannerView: GoogleMobileAds.BannerViewDelegate {

    func bannerViewPresentationController() -> UIViewController? {
        return getRootViewController()
    }

    func bannerView(_ bannerView: GoogleMobileAds.BannerView, didReceiveAdWithAdSize adSize: CGSize) {
        NSLog("LOG: Prebid banner loaded successfully")
    }

    func bannerView(_ bannerView: GoogleMobileAds.BannerView, didFailToReceiveAdWithError error: Error) {
        NSLog("LOG: Error loading Prebid banner: \(error.localizedDescription)")
    }

}

// MARK: - FullScreenContentDelegate

extension PrebidBannerView: FullScreenContentDelegate {

    func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error) {
        NSLog("LOG: GAM Interstitial failed \(error.localizedDescription)")
    }

}

// MARK: - Model

/// Struct to encapsulate ad parameters from Flutter
private struct AdParameters {

    let adUnitId: String
    let configId: String
    let width: Double
    let height: Double
    let adType: String

    init(from dictionary: [String: Any]) {
        adUnitId = dictionary["adUnitId"] as? String ?? ""
        configId = dictionary["configId"] as? String ?? ""
        height = dictionary["height"] as? Double ?? 0
        width = dictionary["width"] as? Double ?? 0
        adType = dictionary["adType"] as? String ?? ""
    }

}
