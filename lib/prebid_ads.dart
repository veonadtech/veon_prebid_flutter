import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:setupad_prebid_flutter/ad_type.dart';
import 'package:setupad_prebid_flutter/event_listener.dart';

class PrebidAd extends StatelessWidget {
  const PrebidAd({
    Key? key,
    required this.adType,
    required this.configId,
    required this.adUnitId,
    required this.width,
    required this.height,
    required this.refreshInterval,
    required this.eventListener,
  }) : super(key: key);

  final AdType adType;
  final String configId;
  final String adUnitId;
  final int? width;
  final int? height;
  final int? refreshInterval;
  final EventListener eventListener;

  @override
  Widget build(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return SizedBox(
          width: adType == AdType.banner ? width?.toDouble() : 1,
          height: adType == AdType.banner ? height?.toDouble() : 1,
          child: AndroidView(
              viewType: 'setupad.plugin.setupad_prebid_flutter',
              onPlatformViewCreated: (int id) {
                onAndroidViewCreated(id);
              }),
        );
      case TargetPlatform.iOS:
        return SizedBox(
          width: adType == AdType.banner ? width?.toDouble() : 1,
          height: adType == AdType.banner ? height?.toDouble() : 1,
          child: UiKitView(
              viewType: 'setupad.plugin.setupad_prebid_flutter',
              onPlatformViewCreated: (int id) {
                onIOSViewCreated(id);
              }),
        );
      default:
        return Text(
            '$defaultTargetPlatform is not yet supported by the plugin');
    }
  }

  ///A method that passes ad parameters to the PassParameters class
  ///The unique ID is used for method channel communication
  void onAndroidViewCreated(int id) {
    // PassParameters( adType, configId, adUnitId, height, width, refreshInterval, id);
    MethodChannel _channel = MethodChannel('setupad.plugin.setupad_prebid_flutter/myChannel_$id');
    debugPrint("PrebidPluginLog view created");
    _channel.invokeMethod('setParams', {
      "adType": adType.name,
      "configId": configId,
      "adUnitId": adUnitId,
      "height": height,
      "width": width,
      "refreshInterval": refreshInterval
    });

    _channel.setMethodCallHandler(_methodCallHandler);
  }

  Future<dynamic> _methodCallHandler(MethodCall call) async {
    final configId = call.arguments.toString();
    switch (call.method) {
      case "onAdLoaded":
        eventListener.onAdLoaded(configId);
        break;
      case "onAdDisplayed":
        eventListener.onAdDisplayed(configId);
        break;
      case "onAdFailed":
        eventListener.onAdFailed(configId);
        break;
      case "onAdClicked":
        eventListener.onAdClicked(configId);
        break;
      case "onAdClosed":
        eventListener.onAdClosed(configId);
        break;
    }
  }

  void onIOSViewCreated(int id) {
    const MethodChannel _channel = MethodChannel('setupad.plugin.setupad_prebid_flutter/ios');
    debugPrint("ios set parameters");
    _channel.invokeMethod('setParams', {
      "adType": adType.name,
      "configId": configId,
      "adUnitId": adUnitId,
      "height": height,
      "width": width,
      "refreshInterval": refreshInterval
    });

    _channel.setMethodCallHandler(_methodCallHandler);
  }

  ///A method that pauses Prebid auction
  void pauseAuction(){
    int id=0;
    debugPrint("PrebidPluginLog pauseAuction");
    MethodChannel _channel = MethodChannel(
        'setupad.plugin.setupad_prebid_flutter/myChannel_$id');
    _channel.invokeMethod('pauseAuction');
  }

  ///A method that resumes Prebid auction
  void resumeAuction(){
    int id=0;
    debugPrint("PrebidPluginLog resumeAuction");
    MethodChannel _channel = MethodChannel(
        'setupad.plugin.setupad_prebid_flutter/myChannel_$id');
    _channel.invokeMethod('resumeAuction');
  }

  ///A method that destroys Prebid auction
  void destroyAuction(){
    int id=0;
    debugPrint("PrebidPluginLog destroyAuction");
    MethodChannel _channel = MethodChannel(
        'setupad.plugin.setupad_prebid_flutter/myChannel_$id');
    _channel.invokeMethod('destroyAuction');
  }
}