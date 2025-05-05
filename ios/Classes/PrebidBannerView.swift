import AdSupport
import AppTrackingTransparency
import Foundation
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

//         result(FlutterError(
//                               code: "LOAD_PARAMETERS",
//                               message: "Unknown initialization status",
//                               details: [
//                                   "adUnitId": adUnitId,
//                                   "configId": configId,
//                                   "adHeight": adHeight,
//                                   "adWidth": adWidth,
//                                   "adType": adType
//                               ]
//                           ))
        let adSize = CGSize(width: adWidth, height: adHeight)
        let bannerView = BannerView(frame: CGRect(origin: .zero, size: adSize),
                                          configID: configId,
                                          adSize: adSize)
        bannerView.delegate = self
        bannerView.adFormat = .banner
        bannerView.loadAd()
        addBannerViewToView(bannerView)

        result(nil)
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
                constant: 0),
            NSLayoutConstraint(
                item: bannerView,
                attribute: .centerY,
                relatedBy: .equal,
                toItem: container,
                attribute: .centerY,
                multiplier: 1,
                constant: 0),
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
