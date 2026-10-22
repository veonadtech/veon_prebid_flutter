import AppTrackingTransparency
import Flutter
import GoogleMobileAds
import PrebidMobile
import VeonPrebidMultiAdLoader
import VeonPrebidRemoteConfig
#if canImport(VeonPrebidMobileGAMEventHandlers)
import VeonPrebidMobileGAMEventHandlers
#else
import PrebidMobileGAMEventHandlers
#endif

class PrebidBannerView: NSObject {

    // MARK: - Properties

    /// Container view that holds ad views
    private var container: UIView

    private var gamBanner: AdManagerBannerView?

    /// Prebid banner view
    private var prebidBannerView: PrebidMobile.BannerView?

    /// Communication channel with Flutter
    private let channel: FlutterMethodChannel
    private let viewId: Int64

    /// Prebid interstitial rendering ad unit
    private var prebidInterstitial: InterstitialRenderingAdUnit?
    private var multiBannerLoader: VeonMultiBannerAdLoader?
    private var multiInterstitialLoader: VeonMultiInterstitialAdLoader?
    private var multiBannerView: UIView?
    private var multiBannerSdk: SdkType?
    private var isBannerVisible = false
    private var lastBannerError: String?
    private var lastInterstitialError: String?

    // Prebid reward ad unit
    private var rewardedAdUnit: RewardedAdUnit?

    private var adParams: AdParameters?
    private var adSize: CGSize?
    private var configId: String?
    private var refreshInterval: Double?

    // MARK: - Constants

    private enum AdType {
        static let banner = "banner"
        static let interstitial = "interstitial"
        static let rewardVideo = "rewardVideo"
    }

    private enum MethodNames {
        static let setParams = "setParams"
        static let demandFetched = "demandFetched"
        static let loadBanner = "loadBanner"
        static let showBanner = "showBanner"
        static let hideBanner = "hideBanner"
        static let loadInterstitial = "loadInterstitial"
        static let showInterstitial = "showInterstitial"
        static let hideInterstitial = "hideInterstitial"
    }

    private enum ErrorCodes {
        static let loadParameters = "LOAD_PARAMETERS"
    }

    // MARK: - Initialization

    init(frame: CGRect, viewIdentifier viewId: Int64, messenger: FlutterBinaryMessenger) {
        container = UIView(frame: frame)
        self.viewId = viewId
        channel = FlutterMethodChannel(
            name: "setupad.plugin.setupad_prebid_flutter/ios_\(viewId)",
            binaryMessenger: messenger
        )

        super.init()

        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            self.handleMethodCall(call, result: result)
        }
    }

    // MARK: - Deinit

    deinit {
        channel.setMethodCallHandler(nil)
        multiBannerLoader?.delegate = nil
        multiBannerLoader?.destroy()
        multiInterstitialLoader?.delegate = nil
        multiInterstitialLoader?.destroy()
        prebidBannerView?.delegate = nil
        prebidBannerView = nil
        gamBanner?.delegate = nil
        gamBanner = nil
        prebidInterstitial?.delegate = nil
        prebidInterstitial = nil
        rewardedAdUnit?.delegate = nil
        rewardedAdUnit = nil
        adParams = nil
    }

    // MARK: - Private Methods

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case MethodNames.setParams:
            handleSetParams(call, result: result)
        case MethodNames.loadBanner:
            handleLoadBanner(result: result)
        case MethodNames.showBanner:
            handleShowBanner(result: result)
        case MethodNames.hideBanner:
            handleHideBanner(result: result)
        case MethodNames.loadInterstitial:
            handleLoadInterstitial(result: result)
        case MethodNames.showInterstitial:
            handleShowInterstitial(result: result)
        case MethodNames.hideInterstitial:
            handleHideInterstitial(result: result)
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

        adParams = AdParameters(from: arguments)
        guard let adParams else { return }
        logAdParameters(adParams)
        configId = adParams.configId

        switch adParams.adType {
        case AdType.banner:
            loadBanner(params: adParams)
        case AdType.interstitial:
            loadInterstitial(params: adParams)
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

    private func handleLoadBanner(result: @escaping FlutterResult) {
        guard let adParams else {
            return result(nil)
        }
        loadBanner(params: adParams)
        result(nil)
    }

    private func handleShowBanner(result: @escaping FlutterResult) {
        isBannerVisible = true
        log("showBanner: loaded=\(multiBannerView != nil), winner=\(multiBannerSdk.map { String(describing: $0) } ?? "none")")
        if let multiBannerView {
            addMultiBannerViewToView(multiBannerView)
        }
        if let gamBanner {
            addGamBannerViewToView(gamBanner)
        }
        if let prebidBannerView {
            addPrebidBannerViewToView(prebidBannerView)
        }

        result(nil)
    }

    private func handleHideBanner(result: @escaping FlutterResult) {
        isBannerVisible = false
        multiBannerView?.removeFromSuperview()
        multiBannerView = nil
        multiBannerSdk = nil
        multiBannerLoader?.delegate = nil
        multiBannerLoader?.destroy()
        multiBannerLoader = nil
        prebidBannerView?.removeFromSuperview()
        gamBanner?.removeFromSuperview()
        prebidBannerView?.delegate = nil
        prebidBannerView = nil
        gamBanner?.delegate = nil
        gamBanner = nil

        result(nil)
    }

    private func handleLoadInterstitial(result: @escaping FlutterResult) {
        guard let adParams else {
            return result(nil)
        }
        loadInterstitial(params: adParams)
        result(nil)
    }

    private func handleShowInterstitial(result: @escaping FlutterResult) {
        if let multiInterstitialLoader {
            log("showInterstitial: ready=\(multiInterstitialLoader.isReady)")
            let rootViewController = getRootViewController()
            multiInterstitialLoader.show(from: rootViewController.presentedViewController ?? rootViewController)
        }
        if let prebidInterstitial {
            let rootViewController = getRootViewController()
            let controllerToPresent = rootViewController.presentedViewController ?? rootViewController
            prebidInterstitial.show(from: controllerToPresent)
        }

        result(nil)
    }

    private func handleHideInterstitial(result: @escaping FlutterResult) {
        multiInterstitialLoader?.delegate = nil
        multiInterstitialLoader?.destroy()
        multiInterstitialLoader = nil
        prebidInterstitial?.delegate = nil
        prebidInterstitial = nil

        result(nil)
    }

    // MARK: - Logging

    private func logAdParameters(_ params: AdParameters) {
        log("setParams: type=\(params.adType), size=\(params.width)x\(params.height), refresh=\(params.refreshInterval), prebid=\(params.configId), gam=\(params.gamAdUnitId), yandex=\(params.yandexAdUnitId.isEmpty ? "<empty>" : params.yandexAdUnitId)")
    }

    private func log(_ message: String) {
        NSLog("[Prebid iOS view=\(viewId)] \(message)")
    }

    private func errorDetails(_ error: Error?) -> String {
        guard let error else { return "<no error provided>" }
        let nsError = error as NSError
        return "domain=\(nsError.domain), code=\(nsError.code), description=\(nsError.localizedDescription)"
    }

    private func logSourceOrder(for format: String) {
        let order = SdkConfigStore.priorityOrder.map { String(describing: $0) }.joined(separator: ",")
        log("load \(format): configLoaded=\(SdkConfigStore.config != nil), sourceOrder=\(order), yandexInOrder=\(SdkConfigStore.priorityOrder.contains(.yandex))")
    }

    // MARK: - Ad Loading Methods

    private func loadBanner(params: AdParameters) {
        guard !params.yandexAdUnitId.isEmpty else {
            log("load banner: Yandex ID empty; using GAM path")
            loadGamBanner(params: params)
            return
        }
        logSourceOrder(for: "banner")
        multiBannerLoader?.delegate = nil
        multiBannerLoader?.destroy()
        multiBannerView?.removeFromSuperview()
        multiBannerView = nil
        multiBannerSdk = nil
        lastBannerError = nil
        let loader = VeonMultiBannerAdLoader(
            rootViewController: getRootViewController(),
            adSize: CGSize(width: params.width, height: params.height),
            refreshInterval: params.refreshInterval,
            configId: params.configId,
            gamAdUnitId: params.gamAdUnitId,
            yandexAdUnitId: params.yandexAdUnitId
        )
        multiBannerLoader = loader
        loader.delegate = self
        Task { @MainActor [weak self, weak loader] in
            guard let self, let loader, loader === self.multiBannerLoader else { return }
            self.log("starting multi banner loader")
            loader.loadAd()
        }
    }

    private func loadInterstitial(params: AdParameters) {
        guard !params.yandexAdUnitId.isEmpty else {
            log("load interstitial: Yandex ID empty; using GAM path")
            loadInterstitialRendering(params: params)
            return
        }
        logSourceOrder(for: "interstitial")
        multiInterstitialLoader?.delegate = nil
        multiInterstitialLoader?.destroy()
        lastInterstitialError = nil
        let loader = VeonMultiInterstitialAdLoader(
            configId: params.configId,
            gamAdUnitId: params.gamAdUnitId,
            yandexAdUnitId: params.yandexAdUnitId
        )
        multiInterstitialLoader = loader
        loader.delegate = self
        Task { @MainActor [weak self, weak loader] in
            guard let self, let loader, loader === self.multiInterstitialLoader else { return }
            self.log("starting multi interstitial loader")
            loader.loadAd()
        }
    }

    private func addMultiBannerViewToView(_ bannerView: UIView) {
        guard bannerView.superview !== container else { return }
        bannerView.removeFromSuperview()
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bannerView)
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            bannerView.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        if let multiBannerSdk {
            channel.invokeMethod("onAdDisplayed", arguments: adId(for: multiBannerSdk))
        }
    }

    private func loadGamBanner(params: AdParameters) {
        adSize = CGSize(width: Int(params.width), height: Int(params.height))
        configId = params.configId
        refreshInterval = params.refreshInterval
        guard let adSize, let configId else {
            print("Error: adSize or configId is nil")
            return
        }
        guard gamBanner == nil else { return }

        let adUnit = BannerAdUnit(configId: configId, size: adSize)

        // Configure banner parameters
        let parameters = BannerParameters()
        parameters.api = [Signals.Api.MRAID_2]
        adUnit.bannerParameters = parameters
        adUnit.setAutoRefreshMillis(time: params.refreshInterval * 1000)

        // Create a GAMBannerView
        gamBanner = AdManagerBannerView(adSize: adSizeFor(cgSize: adSize))
        gamBanner?.adUnitID = params.gamAdUnitId
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
        guard prebidBannerView == nil, let adSize, let configId else {
            return
        }

        prebidBannerView = BannerView(frame: CGRect(origin: .zero, size: adSize),
                                      configID: configId,
                                      adSize: adSize)

        // Configure the BannerView
        prebidBannerView?.delegate = self
        prebidBannerView?.adFormat = .banner
        if let refreshInterval {
            prebidBannerView?.refreshInterval = refreshInterval
        }

        // Load the banner ad
        prebidBannerView?.loadAd()
    }

    private func loadInterstitialRendering(params: AdParameters) {
        let eventHandler = GAMInterstitialEventHandler(adUnitID: params.gamAdUnitId)
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
        let eventHandler = GAMRewardedAdEventHandler(adUnitID: params.gamAdUnitId)
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

// MARK: - Multi-ad loader delegates

extension PrebidBannerView: VeonMultiBannerAdLoaderDelegate {
    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didLoad view: UIView, from sdk: SdkType) {
        guard loader === multiBannerLoader else { return }
        log("banner loaded: source=\(sdk), adUnit=\(adId(for: sdk)), visible=\(isBannerVisible)")
        multiBannerView?.removeFromSuperview()
        multiBannerView = view
        multiBannerSdk = sdk
        channel.invokeMethod("onAdLoaded", arguments: adId(for: sdk))
        if isBannerVisible { addMultiBannerViewToView(view) }
    }

    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didFailToLoad sdk: SdkType, error: Error?) {
        guard loader === multiBannerLoader else { return }
        log("banner failed: source=\(sdk), adUnit=\(adId(for: sdk)), \(errorDetails(error))")
        lastBannerError = error?.localizedDescription
    }

    func bannerLoaderDidFailAll(_ loader: VeonMultiBannerAdLoader) {
        guard loader === multiBannerLoader else { return }
        log("all banner sources failed; lastError=\(lastBannerError ?? "none")")
        channel.invokeMethod("onAdFailed", arguments: lastBannerError ?? "All banner sources failed")
    }

    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didRecordImpressionFrom sdk: SdkType) {
        guard loader === multiBannerLoader else { return }
        channel.invokeMethod("onImpression", arguments: adId(for: sdk))
    }

    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didRecordClickFrom sdk: SdkType) {
        guard loader === multiBannerLoader else { return }
        channel.invokeMethod("onAdClicked", arguments: adId(for: sdk))
    }

    func bannerLoader(_ loader: VeonMultiBannerAdLoader, didDismissScreenFrom sdk: SdkType) {
        guard loader === multiBannerLoader else { return }
        channel.invokeMethod("onAdClosed", arguments: adId(for: sdk))
    }

    private func adId(for sdk: SdkType) -> String {
        guard let adParams else { return "" }
        switch sdk {
        case .prebid: return adParams.configId
        case .gam: return adParams.gamAdUnitId
        case .yandex: return adParams.yandexAdUnitId
        }
    }
}

extension PrebidBannerView: VeonMultiInterstitialAdLoaderDelegate {
    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didLoadFrom sdk: SdkType) {
        guard loader === multiInterstitialLoader else { return }
        log("interstitial loaded: source=\(sdk), adUnit=\(adId(for: sdk))")
        channel.invokeMethod("onAdLoaded", arguments: adId(for: sdk))
    }

    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didFailToLoad sdk: SdkType, error: Error?) {
        guard loader === multiInterstitialLoader else { return }
        log("interstitial failed: source=\(sdk), adUnit=\(adId(for: sdk)), \(errorDetails(error))")
        lastInterstitialError = error?.localizedDescription
    }

    func interstitialLoaderDidFailAll(_ loader: VeonMultiInterstitialAdLoader) {
        guard loader === multiInterstitialLoader else { return }
        log("all interstitial sources failed; lastError=\(lastInterstitialError ?? "none")")
        channel.invokeMethod("onAdFailed", arguments: lastInterstitialError ?? "All interstitial sources failed")
    }

    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, willPresent sdk: SdkType) {
        guard loader === multiInterstitialLoader else { return }
        channel.invokeMethod("onAdDisplayed", arguments: adId(for: sdk))
    }

    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didDismiss sdk: SdkType) {
        guard loader === multiInterstitialLoader else { return }
        channel.invokeMethod("onAdClosed", arguments: adId(for: sdk))
    }

    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didClick sdk: SdkType) {
        guard loader === multiInterstitialLoader else { return }
        channel.invokeMethod("onAdClicked", arguments: adId(for: sdk))
    }

    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didFailToShow sdk: SdkType, error: Error?) {
        guard loader === multiInterstitialLoader else { return }
        log("interstitial show failed: source=\(sdk), \(errorDetails(error))")
        channel.invokeMethod("onAdFailed", arguments: error?.localizedDescription ?? "Interstitial failed to show")
    }

    func interstitialLoader(_ loader: VeonMultiInterstitialAdLoader, didTrackImpression sdk: SdkType) {
        guard loader === multiInterstitialLoader else { return }
        channel.invokeMethod("onImpression", arguments: adId(for: sdk))
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

    let gamAdUnitId: String
    let yandexAdUnitId: String
    let configId: String
    let width: Double
    let height: Double
    let adType: String
    let refreshInterval: Double

    init(from dictionary: [String: Any]) {
        gamAdUnitId = dictionary["gamAdUnitId"] as? String ?? ""
        yandexAdUnitId = dictionary["yandexAdUnitId"] as? String ?? ""
        configId = dictionary["configId"] as? String ?? ""
        height = dictionary["height"] as? Double ?? 0
        width = dictionary["width"] as? Double ?? 0
        adType = dictionary["adType"] as? String ?? ""
        refreshInterval = dictionary["refreshInterval"] as? Double ?? 0
    }

}
