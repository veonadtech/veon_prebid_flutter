import AppTrackingTransparency
import GoogleMobileAds
import PrebidMobile
import VeonPrebidMobileGAMEventHandlers

class PrebidBannerView: NSObject {

    // MARK: - Properties

    /// Container view that holds ad views
    private var container: UIView

    private var gamBanner: AdManagerBannerView?

    /// Prebid banner view
    private var prebidBannerView: PrebidMobile.BannerView?

    /// Communication channel with Flutter
    private let channel: FlutterMethodChannel

    /// Prebid interstitial rendering ad unit
    private var prebidInterstitial: InterstitialRenderingAdUnit?

    // Prebid reward ad unit
    private var rewardedAdUnit: RewardedAdUnit?

    private var adSize: CGSize?
    private var configId: String?

    // MARK: - Constants

    private enum AdType {
        static let banner = "banner"
        static let interstitial = "interstitial"
        static let rewardVideo = "rewardVideo"
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
        configId = adParams.configId

        switch adParams.adType {
        case AdType.banner:
            loadGamBanner(params: adParams)
        case AdType.interstitial:
            loadInterstitialRendering(params: adParams)
        case AdType.rewardVideo:
            loadRewardVideo(params: adParams)
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
    
    private func loadGamBanner(params: AdParameters) {
        adSize = CGSize(width: Int(params.width), height: Int(params.height))
        configId = params.configId
        guard let adSize, let configId else {
            print("Error: adSize or configId is nil")
            return
        }
        
        let adUnit = BannerAdUnit(configId: configId, size: adSize)
        
        // Configure banner parameters
        let parameters = BannerParameters()
        parameters.api = [Signals.Api.MRAID_2]
        adUnit.bannerParameters = parameters
        
        // Create a GAMBannerView
        gamBanner = AdManagerBannerView(adSize: adSizeFor(cgSize: adSize))
        gamBanner?.adUnitID = params.adUnitId
        gamBanner?.delegate = self
        
        // Make a bid request to Prebid Server
        let gamRequest = AdManagerRequest()
        adUnit.fetchDemand(adObject: gamRequest) { [weak self] resultCode in
            guard let self, let gamBanner = self.gamBanner else { return }
            print("Prebid demand fetch for GAM \(resultCode.name())")
            
            // Load GAM Ad
            gamBanner.load(gamRequest)
        }
    }

    private func loadPrebidBanner() {
        guard let adSize, let configId else { return }
        
        prebidBannerView = BannerView(frame: CGRect(origin: .zero, size: adSize),
                                      configID: configId,
                                      adSize: adSize)
        
        // Configure the BannerView
        prebidBannerView?.delegate = self
        prebidBannerView?.adFormat = .banner
        
        // Load the banner ad
        prebidBannerView?.loadAd()
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

    private func loadRewardVideo(params: AdParameters) {
        let eventHandler = GAMRewardedAdEventHandler(adUnitID: params.adUnitId)
        rewardedAdUnit = RewardedAdUnit(configID: params.configId, eventHandler: eventHandler)
        rewardedAdUnit?.delegate = self
        rewardedAdUnit?.loadAd()
    }

    // MARK: - Utility Methods

    private func getRootViewController() -> UIViewController {
        return UIApplication.shared.delegate?.window??.rootViewController ?? UIViewController()
    }

    private func addGamBannerViewToView(_ bannerView: AdManagerBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bannerView)

        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            bannerView.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
    }

    private func addPrebidBannerViewToView(_ bannerView: PrebidMobile.BannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bannerView)

        NSLayoutConstraint.activate([
            bannerView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 5),
            bannerView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -5),

            bannerView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            bannerView.centerYAnchor.constraint(equalTo: container.centerYAnchor)
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
        channel.invokeMethod("onAdLoaded", arguments: configId)

        let rootViewController = getRootViewController()
        let controllerToPresent = rootViewController.presentedViewController ?? rootViewController
        interstitial.show(from: controllerToPresent)
    }

    func interstitial(_ interstitial: InterstitialRenderingAdUnit, didFailToReceiveAdWithError error: Error?) {
        NSLog("LOG: Error loading Prebid interstitial: \(error?.localizedDescription ?? "unknown error")")
        channel.invokeMethod("onAdFailed", arguments: error?.localizedDescription ?? "unknown error")
    }

    func interstitialWillLeaveApplication(_ interstitial: InterstitialRenderingAdUnit) {
        NSLog("LOG: User leaves the app via interstitial ad")
        channel.invokeMethod("onAdUrlClicked", arguments: configId)
    }

    func interstitialDidClickAd(_ interstitial: InterstitialRenderingAdUnit) {
        NSLog("LOG: User clicked interstitial ad")
        channel.invokeMethod("onAdClicked", arguments: configId)
    }

    func interstitialDidCloseAd(_ interstitial: InterstitialRenderingAdUnit) {
        NSLog("LOG: Interstitial is closed")
        channel.invokeMethod("onAdClosed", arguments: configId)
    }

    func interstitialWillPresentAd(_ interstitial: InterstitialRenderingAdUnit) {
        NSLog("LOG: Interstitial ad displayed")
        channel.invokeMethod("onAdDisplayed", arguments: configId)
    }

}

// MARK: - BannerViewDelegate

extension PrebidBannerView: PrebidMobile.BannerViewDelegate {

    func bannerViewPresentationController() -> UIViewController? {
        return getRootViewController()
    }

    func bannerView(_ bannerView: PrebidMobile.BannerView, didReceiveAdWithAdSize adSize: CGSize) {
        NSLog("LOG: Prebid banner loaded successfully")
        let configId = bannerView.configID
        channel.invokeMethod("onAdLoaded", arguments: configId)
        addPrebidBannerViewToView(bannerView)
    }

    func bannerView(_ bannerView: PrebidMobile.BannerView, didFailToReceiveAdWith error: any Error) {
        NSLog("LOG: Error loading Prebid banner: \(error.localizedDescription)")
        channel.invokeMethod("onAdFailed", arguments: error.localizedDescription)
    }

    func bannerViewDidRecordImpression(_ bannerView: PrebidMobile.BannerView) {
        NSLog("LOG: Banner did record impression")
    }

    func bannerViewWillLeaveApplication(_ bannerView: PrebidMobile.BannerView) {
        NSLog("LOG: Banner will leave application")
        let configId = bannerView.configID
        channel.invokeMethod("onAdClicked", arguments: configId)
    }

    func bannerViewWillPresentModal(_ bannerView: PrebidMobile.BannerView) {
        let configId = bannerView.configID
        channel.invokeMethod("onAdDisplayed", arguments: configId)
    }

}

extension PrebidBannerView: RewardedAdUnitDelegate {

    func rewardedAdDidReceiveAd(_ rewardedAd: RewardedAdUnit) {
        NSLog("LOG: Rewarded ad unit received ad")
        channel.invokeMethod("onAdLoaded", arguments: configId)

        if rewardedAd.isReady {
            rewardedAd.show(from: self.getRootViewController())
        }
    }

    func rewardedAd(_ rewardedAd: RewardedAdUnit, didFailToReceiveAdWithError error: Error?) {
        NSLog("LOG: Rewarded ad unit failed to receive ad with error: \(error?.localizedDescription ?? "")")
        channel.invokeMethod("onAdFailed", arguments: error?.localizedDescription ?? "unknown error")
    }

    func rewardedAdUserDidEarnReward(_ rewardedAd: RewardedAdUnit, reward: PrebidReward) {
        NSLog("LOG: User did earn reward: type - \(reward.type ?? ""), count - \(reward.count ?? 0)")
    }

    func rewardedAdWillPresentAd(_ rewardedAd: RewardedAdUnit) {
        NSLog("LOG: Rewarded ad will present ad")
        channel.invokeMethod("onAdDisplayed", arguments: configId)
    }

    func rewardedAdDidDismissAd(_ rewardedAd: RewardedAdUnit) {
        NSLog("LOG: Rewarded ad did dismiss ad")
        channel.invokeMethod("onAdClosed", arguments: configId)
    }

    func rewardedAdDidClickAd(_ rewardedAd: RewardedAdUnit) {
        NSLog("LOG: Rewarded ad did click ad")
        channel.invokeMethod("onAdClicked", arguments: configId)
    }

    func rewardedAdWillLeaveApplication(_ rewardedAd: RewardedAdUnit) {
        NSLog("LOG: Rewarded ad will leave application ad")
        channel.invokeMethod("onAdUrlClicked", arguments: configId)
    }

}

// MARK: - GADBannerViewDelegate

extension PrebidBannerView: GoogleMobileAds.BannerViewDelegate {
    
    func bannerViewDidReceiveAd(_ bannerView: GoogleMobileAds.BannerView) {
        if let gamBanner {
            addGamBannerViewToView(gamBanner)
        }
        self.channel.invokeMethod("onAdLoaded", arguments: bannerView.adUnitID)
    }
    
    func bannerView(_ bannerView: GoogleMobileAds.BannerView,
                    didFailToReceiveAdWithError error: Error) {
        print("GAM did fail to receive ad with error: \(error)")
        channel.invokeMethod("onAdFailed", arguments: error.localizedDescription)
        // Fallback to Prebid ad when GAM fails
        gamBanner = nil
        loadPrebidBanner()
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
    let refreshInterval: Double

    init(from dictionary: [String: Any]) {
        adUnitId = dictionary["adUnitId"] as? String ?? ""
        configId = dictionary["configId"] as? String ?? ""
        height = dictionary["height"] as? Double ?? 0
        width = dictionary["width"] as? Double ?? 0
        adType = dictionary["adType"] as? String ?? ""
        refreshInterval = dictionary["refreshInterval"] as? Double ?? 0
    }

}
