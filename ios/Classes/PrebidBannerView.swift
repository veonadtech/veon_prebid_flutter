import AdSupport
import AppTrackingTransparency
import Foundation
import GoogleMobileAds
import PrebidMobile
import os.log

class PrebidBannerView: NSObject, FlutterPlatformView {
    private var container: UIView!
    private let channel: FlutterMethodChannel!
    private var prebidInterstitial: InterstitialRenderingAdUnit?

    init(frame: CGRect, viewIdentifier viewId: Int64, messenger: FlutterBinaryMessenger) {
        container = UIView(frame: frame)
        channel = FlutterMethodChannel(
            name: "setupad.plugin.setupad_prebid_flutter/ios",
            binaryMessenger: messenger
        )

        super.init()

        channel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            self.handle(call, result: result)
        })
    }

    func view() -> UIView {
        return container
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setParams":
            load(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func load(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let argument = call.arguments as! [String: Any]
        let adUnitId = argument["adUnitId"] as? String ?? ""
        let configId = argument["configId"] as? String ?? ""
        let adHeight = argument["height"] as? Double ?? 0
        let adWidth = argument["width"] as? Double ?? 0
        let adType = argument["adType"] as? String ?? ""

        print("adUnit \(adUnitId)")
        print("configId \(configId)")
        print("adHeight \(adHeight)")
        print("adWidth \(adWidth)")
        print("adType \(adType)")
        NSLog("LOG \(adUnitId), \(configId), \(adHeight), \(adHeight), \(adType)")
        
        switch adType {
        case "banner":
            loadBanner(configId: configId, width: adWidth, height: adHeight, adUnitId: adUnitId)
        case "interstitial":
            loadInterstitialAd(configId: configId, width: adWidth, height: adHeight, adUnitId: adUnitId)
        default:
            result(
                FlutterError(
                    code: "LOAD_PARAMETERS",
                    message: "Unknown initialization status",
                    details: [
                        "adUnitId": adUnitId,
                        "configId": configId,
                        "adHeight": adHeight,
                        "adWidth": adWidth,
                        "adType": adType,
                    ]
                )
            )
        }

        result(nil)
    }

    private func loadBanner(
        configId: String,
        width: Double,
        height: Double,
        adUnitId: String
    ) {
        let adSize = CGSize(width: width, height: height)
        // Use fully qualified class name to resolve ambiguity
        let bannerView = PrebidMobile.BannerView(
            frame: CGRect(origin: .zero, size: adSize),
            configID: configId,
            adSize: adSize
        )
        bannerView.delegate = self
        bannerView.adFormat = .banner
        bannerView.loadAd()
        addBannerViewToView(bannerView)
    }

    private func loadInterstitialAd(
        configId: String,
        width: Double,
        height: Double,
        adUnitId: String
    ) {
        prebidInterstitial = InterstitialRenderingAdUnit(configID: configId)
        prebidInterstitial?.delegate = self

        print("Starting load Prebid interstitial...")
        prebidInterstitial?.loadAd()

    }

    private func getRootViewController() -> UIViewController {
        return UIApplication.shared.delegate?.window??.rootViewController ?? UIViewController()
    }

    private func addBannerViewToView(_ bannerView: PrebidMobile.BannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bannerView)
        container.addConstraints([
            NSLayoutConstraint(
                item: bannerView,
                attribute: .centerX,
                relatedBy: .equal,
                toItem: container,
                attribute: .centerX,
                multiplier: 1,
                constant: 0
            ),
            NSLayoutConstraint(
                item: bannerView,
                attribute: .centerY,
                relatedBy: .equal,
                toItem: container,
                attribute: .centerY,
                multiplier: 1,
                constant: 0
            ),
        ])
    }
}

// MARK: - InterstitialAdUnitDelegate
extension PrebidBannerView: InterstitialAdUnitDelegate {
    func interstitialDidReceiveAd(_ interstitial: InterstitialRenderingAdUnit) {
        print("Prebid interstitial успешно загружен, показываем...")
        // Get a valid UIViewController to present the ad
        let rootViewController = getRootViewController()
        interstitial.show(from: rootViewController)
    }

    func interstitial(_ interstitial: InterstitialRenderingAdUnit, didFailToReceiveAdWithError error: Error?) {
        print("Ошибка загрузки Prebid interstitial: \(error?.localizedDescription ?? "неизвестная ошибка")")
    }

    func interstitialWillLeaveApplication(_ interstitial: InterstitialRenderingAdUnit) {
        print("Пользователь покидает приложение через interstitial")
    }

    func interstitialDidClickAd(_ interstitial: InterstitialRenderingAdUnit) {
        print("Пользователь кликнул по interstitial")
    }

    func interstitialDidCloseAd(_ interstitial: InterstitialRenderingAdUnit) {
        print("Interstitial закрыт")
        // Если хотите загрузить новую рекламу после закрытия
        // addInterstitialAdUnit()
    }
}

// Add this extension to implement BannerViewDelegate
extension PrebidBannerView: PrebidMobile.BannerViewDelegate {
    func bannerViewPresentationController() -> UIViewController? {
        return UIApplication.shared.delegate?.window??.rootViewController
    }

    func bannerView(_ bannerView: PrebidMobile.BannerView, didReceiveAdWithAdSize adSize: CGSize) {
        print("Prebid banner успешно загружен")
    }

    func bannerView(_ bannerView: PrebidMobile.BannerView, didFailToReceiveAdWith error: Error) {
        print("Ошибка загрузки Prebid banner: \(error.localizedDescription)")
    }
}
