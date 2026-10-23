import AppTrackingTransparency
import Flutter
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

    /// Communication channel with Flutter
    private let channel: FlutterMethodChannel
    private let viewId: Int64

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
    private var configId: String?

    // MARK: - Constants

    private enum AdType {
        static let banner = "banner"
        static let interstitial = "interstitial"
        static let rewardVideo = "rewardvideo"
    }

    private enum MethodNames {
        static let setParams = "setParams"
        static let loadBanner = "loadBanner"
        static let showBanner = "showBanner"
        static let hideBanner = "hideBanner"
        static let loadInterstitial = "loadInterstitial"
        static let showInterstitial = "showInterstitial"
        static let hideInterstitial = "hideInterstitial"
        static let destroyAuction = "destroyAuction"
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
        case MethodNames.destroyAuction:
            destroyAuction()
            result(nil)
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

        let params = AdParameters(from: arguments)
        logAdParameters(params)
        let adType = params.adType.lowercased()

        guard !params.gamAdUnitId.isEmpty || !params.yandexAdUnitId.isEmpty || !params.configId.isEmpty else {
            log("setParams: GAM, Yandex and Prebid IDs are empty")
            result(nil)
            return
        }
        if adType == AdType.banner && !(30...120).contains(params.refreshInterval) {
            log("setParams: banner refreshInterval must be between 30 and 120 seconds")
            result(nil)
            return
        }
        adParams = params
        configId = params.configId

        switch adType {
        case AdType.banner:
            container.isHidden = false
            loadBanner(params: params)
        case AdType.interstitial:
            container.isHidden = true
            loadInterstitial(params: params)
        case AdType.rewardVideo:
            container.isHidden = true
            loadRewardVideo(params: params)
        default:
            result(
                FlutterError(
                    code: ErrorCodes.loadParameters,
                    message: "Unknown ad type: \(params.adType)",
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

        result(nil)
    }

    private func handleHideBanner(result: @escaping FlutterResult) {
        destroyBanner()
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

        result(nil)
    }

    private func handleHideInterstitial(result: @escaping FlutterResult) {
        destroyInterstitial()
        result(nil)
    }

    private func destroyBanner() {
        isBannerVisible = false
        multiBannerView?.removeFromSuperview()
        multiBannerView = nil
        multiBannerSdk = nil
        multiBannerLoader?.delegate = nil
        multiBannerLoader?.destroy()
        multiBannerLoader = nil
    }

    private func destroyInterstitial() {
        multiInterstitialLoader?.delegate = nil
        multiInterstitialLoader?.destroy()
        multiInterstitialLoader = nil
    }

    private func destroyAuction() {
        destroyBanner()
        destroyInterstitial()
        rewardedAdUnit?.delegate = nil
        rewardedAdUnit = nil
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
        logSourceOrder(for: "banner")
        multiBannerLoader?.delegate = nil
        multiBannerLoader?.destroy()
        multiBannerView?.removeFromSuperview()
        multiBannerView = nil
        multiBannerSdk = nil
        lastBannerError = nil
        let loader = VeonMultiBannerAdLoader(
            rootViewController: getRootViewController(),
            adSize: CGSize(width: CGFloat(params.width), height: CGFloat(params.height)),
            refreshInterval: Double(params.refreshInterval),
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
        destroyInterstitial()
        logSourceOrder(for: "interstitial")
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

    private func loadRewardVideo(params: AdParameters) {
        rewardedAdUnit?.delegate = nil
        rewardedAdUnit = nil
        let eventHandler = GAMRewardedAdEventHandler(adUnitID: params.gamAdUnitId)
        rewardedAdUnit = RewardedAdUnit(configID: params.configId, eventHandler: eventHandler)
        rewardedAdUnit?.delegate = self
        rewardedAdUnit?.loadAd()
    }

    // MARK: - Utility Methods

    private func getRootViewController() -> UIViewController {
        return UIApplication.shared.delegate?.window??.rootViewController ?? UIViewController()
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
        channel.invokeMethod("onUserEarnedReward", arguments: configId)
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

// MARK: - Model

/// Struct to encapsulate ad parameters from Flutter
private struct AdParameters {

    let gamAdUnitId: String
    let yandexAdUnitId: String
    let configId: String
    let width: Int
    let height: Int
    let adType: String
    let refreshInterval: Int

    init(from dictionary: [String: Any]) {
        gamAdUnitId = dictionary["gamAdUnitId"] as? String ?? ""
        yandexAdUnitId = dictionary["yandexAdUnitId"] as? String ?? ""
        configId = dictionary["configId"] as? String ?? ""
        height = dictionary["height"] as? Int ?? 0
        width = dictionary["width"] as? Int ?? 0
        adType = dictionary["adType"] as? String ?? ""
        refreshInterval = dictionary["refreshInterval"] as? Int ?? 0
    }

}
