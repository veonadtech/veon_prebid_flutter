import AdSupport
import AppTrackingTransparency
import Foundation
import Google_Mobile_Ads_SDK
import PrebidMobile
import os.log

class PrebidBannerView: NSObject, FlutterPlatformView {
    private var container: UIView!
    private let channel: FlutterMethodChannel!

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
        let bannerView = BannerView(
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
        adUnitId:String
    ) {
        let gamRequest = AdManagerRequest()
        let interstitialAdUnit = InterstitialAdUnit(
            configId: "test_interstitial",
            minWidthPerc: 50,
            minHeightPerc: 50
        )

        interstitialAdUnit.fetchDemand(adObject: gamRequest) { [weak self] bidInfo in
            Logger().info("Prebid demand fetch result \(bidInfo.name)")

            InterstitialAd.load(with: adUnitId, request: gamRequest) { ad, error in
                guard let self = self else { return }

                if let error = error {
                    Logger().info("Failed to load interstitial ad with error: \(error.localizedDescription)")
                } else if let ad = ad {
                    ad.fullScreenContentDelegate = self
                    ad.present(from: self)
                }
            }
        }
        
        interstitialAdUnit.adFormats

    }

    private func addBannerViewToView(_ bannerView: BannerView) {
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

extension PrebidBannerView: BannerViewDelegate {

    func bannerViewPresentationController() -> UIViewController? {
        return UIApplication.shared.delegate?.window??.rootViewController
    }

    func bannerView(_ bannerView: BannerView, didReceiveAdWithAdSize adSize: CGSize) {
        NSLog("LOG: Prebid: Ad loaded successfully")
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWith error: Error) {
        NSLog("LOG: Prebid: Ad failed to load - \(error.localizedDescription)")
    }

}
