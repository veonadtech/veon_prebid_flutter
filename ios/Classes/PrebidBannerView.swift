import AdSupport
import AppTrackingTransparency
import Foundation
import GoogleMobileAds
import PrebidMobile
import PrebidMobileGAMEventHandlers
import os.log

class PrebidBannerView: NSObject, FlutterPlatformView {
    private var container: UIView!
    private let channel: FlutterMethodChannel!
    private var prebidInterstitial: InterstitialRenderingAdUnit?
    private var interstitialAdUnit: InterstitialAdUnit?

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

        NSLog("LOG: adUnit: \(adUnitId)")
        NSLog("LOG: configId: \(configId)")
        NSLog("LOG: adHeight: \(adHeight)")
        NSLog("LOG: adWidth: \(adWidth)")
        NSLog("LOG: adType: \(adType)")

        switch adType {
        case "banner":
            loadBanner(configId: configId, width: adWidth, height: adHeight, adUnitId: adUnitId)
        case "interstitial":
      //      loadPrebidInterstitialAd(configId: configId, width: adWidth, height: adHeight, adUnitId: adUnitId)
            loadInterstitialRendering(configId: configId, width: adWidth, height: adHeight, adUnitId: adUnitId)
      //      loadGAMInterstitial(configId: configId, width: adWidth, height: adHeight, adUnitId: adUnitId)
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
        adUnitId: String,
    ) {
        let adSize = CGSize(width: width, height: height)
        let bannerUnit = BannerAdUnit(configId: configId, size: adSize)
        let bannerView = BannerView(adSize: adSizeFor(cgSize: adSize))
        let request = Request()
        bannerView.adUnitID = adUnitId
        bannerView.delegate = self
        bannerView.rootViewController = UIApplication.shared.delegate!.window!!.rootViewController!
        addBannerViewToView(bannerView)
        bannerView.backgroundColor = UIColor.clear

        bannerUnit.fetchDemand(adObject: request) { (ResultCode) in
            self.channel.invokeMethod("demandFetched", arguments: ["name": ResultCode.name()])
            if #available(iOS 14, *) {
                ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
                    bannerView.load(request)
                })
            } else {
                bannerView.load(request)
            }
        }
    }

    private func loadPrebidInterstitialAd(
        configId: String,
        width: Double,
        height: Double,
        adUnitId: String
    ) {
        prebidInterstitial = InterstitialRenderingAdUnit(
            configID: configId,
            minSizePercentage: CGSize(width: Int(width), height: Int(height))
        )
        prebidInterstitial?.delegate = self

        NSLog("LOG: Starting load Prebid interstitial...")
        prebidInterstitial?.loadAd()

    }

    private func loadInterstitialRendering(
        configId: String,
        width: Double,
        height: Double,
        adUnitId: String
    ) {
        let eventHandler = GAMInterstitialEventHandler(adUnitID: adUnitId)
        prebidInterstitial = InterstitialRenderingAdUnit(
            configID: configId,
            minSizePercentage: CGSize(width: Int(width), height: Int(height)),
            eventHandler: eventHandler
        )
        prebidInterstitial?.delegate = self

        NSLog("LOG: Starting load Prebid interstitial...")
        prebidInterstitial?.loadAd()

    }

    private func loadGAMInterstitial(
        configId: String,
        width: Double,
        height: Double,
        adUnitId: String
    ) {
        interstitialAdUnit = InterstitialAdUnit(configId: configId, minWidthPerc: Int(width), minHeightPerc: Int(height))
        interstitialAdUnit?.adFormats = [.banner]
        let gamRequest = AdManagerRequest()

        interstitialAdUnit?.fetchDemand(adObject: gamRequest) { [weak self] resultCode in
            NSLog("LOG: Prebid demand fetch for GAM \(resultCode.name())")

            InterstitialAd.load(with: adUnitId, request: gamRequest) { ad, error in
                guard let self else { return }

                if let error {
                    NSLog("LOG: Failed to load interstitial ad with error: \(error.localizedDescription)")
                } else if let ad {

                    ad.fullScreenContentDelegate = self
                    ad.present(from: self.getRootViewController())
                }
            }

        }

    }

    private func getRootViewController() -> UIViewController {
        return UIApplication.shared.delegate?.window??.rootViewController ?? UIViewController()
    }

    private func addBannerViewToView(_ bannerView: GoogleMobileAds.BannerView) {
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

// Add this extension to implement BannerViewDelegate
extension PrebidBannerView: GoogleMobileAds.BannerViewDelegate {
    func bannerViewPresentationController() -> UIViewController? {
        return UIApplication.shared.delegate?.window??.rootViewController
    }

    func bannerView(_ bannerView: GoogleMobileAds.BannerView, didReceiveAdWithAdSize adSize: CGSize) {
        NSLog("LOG: Prebid banner loaded successfully")
    }

    func bannerView(_ bannerView: GoogleMobileAds.BannerView, didFailToReceiveAdWith error: Error) {
        NSLog("LOG: Error loading Prebid banner: \(error.localizedDescription)")
    }
}

extension PrebidBannerView: FullScreenContentDelegate {
    func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error) {
        NSLog("LOG: GAM Interstitial failed \(error.localizedDescription)")
    }
}
