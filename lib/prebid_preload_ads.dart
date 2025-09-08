import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:setupad_prebid_flutter/ad_type.dart';
import 'package:setupad_prebid_flutter/event_listener.dart';
import 'package:setupad_prebid_flutter/prebid_preload_ad_listener.dart';

class PrebidPreloadAd {
  const PrebidPreloadAd();
  static late PrebidPreloadAdListener _preloadAdListener;
  static const MethodChannel _pluginChannel =
  MethodChannel('setupad.plugin.setupad_prebid_flutter/preload_ad');

  // void _sendParams(MethodChannel channel) {
  //   debugPrint("PrebidPluginLog setParams");
  //   channel.invokeMethod('setParams', {
  //     "adType": widget.adType.name,
  //     "configId": widget.configId,
  //     "adUnitId": widget.adUnitId,
  //     "height": widget.height,
  //     "width": widget.width,
  //     "refreshInterval": widget.refreshInterval,
  //   });
  // }

  ///initializeSDK() passes to the native side Prebid account ID
  Future<void> loadAd(
      String adType,
      String configId,
      String adUnitId,
      String height,
      int width,
      PrebidPreloadAdListener preloadAdListener
      ) {

    _preloadAdListener = preloadAdListener;
    _pluginChannel.setMethodCallHandler(_methodCallHandler);

    if(Platform.isAndroid){
      const MethodChannel channel = MethodChannel('setupad.plugin.setupad_prebid_flutter/load_ad');
      return channel.invokeMethod('startLoadAd', {
        "adType": adType,
        "configId": configId,
        "adUnitId": adUnitId,
        "height": height,
        "width": width
      });
    }else{
      return Future.value();
      // const MethodChannel channel = MethodChannel('setupad.plugin.setupad_prebid_flutter/ios_init');
      // return channel.invokeMethod('startPrebid', {
      //   "accountID": prebidAccountID,
      //   "host": prebidHost,
      //   "timeoutMillis": timeoutMillis,
      //   "pbsDebug": pbsDebug
      // });
    }
  }

  static Future<dynamic> _methodCallHandler(MethodCall call) async {
    switch (call.method) {
      case "prebidAdLoaded":
        debugPrint("PrebidSdkListener: prebidSdkInitialized ${call.arguments}");
        _preloadAdListener.onAdLoaded(call.arguments);
        break;
      case "prebidAdLoadFailed":
        debugPrint("PrebidPreloadAdListener: prebidAdLoadFailed ${call.arguments}");
        _preloadAdListener.onAdLoadFailed(call.arguments);
        break;
      default:
        debugPrint("PrebidPreloadAdListener: unknown call ${call.method}");
    }
  }

}





/// Controller to drive a single PrebidAd instance via its platform MethodChannel.
class PrebidPreloadController {

  MethodChannel? _channel;

  /// Internal: attached by PrebidAd when the platform view is created.
  void _attachChannel(MethodChannel channel) {
    _channel = channel;
  }

  bool get isAttached => _channel != null;

  Future<void> loadBanner() async {
    if (_channel == null) return;
    await _channel!.invokeMethod('loadBanner');
  }

  Future<void> showBanner() async {
    if (_channel == null) return;
    await _channel!.invokeMethod('showBanner');
  }

}

class PrebidPreloadAd {
  PrebidPreloadAd({
    required this.adType,
    required this.configId,
    required this.adUnitId,
    required this.width,
    required this.height,
    required this.refreshInterval,
    required this.eventListener,
    required this.prebidController,
  });

  AdType adType;
  String configId;
  String adUnitId;
  int? width;
  int? height;
  int? refreshInterval;
  EventListener eventListener;
  PrebidPreloadController prebidController;

  bool get isBanner => adType == AdType.banner;
  double get w => isBanner ? (width?.toDouble() ?? 0) : 1.0;
  double get h => isBanner ? (height?.toDouble() ?? 0) : 1.0;

  final channel = MethodChannel('setupad.plugin.setupad_prebid_flutter/myChannel/android');
  _wireChannel(channel);
  _sendParams(channel);
}


class _PrebidPreloadAdState extends State<PrebidPreloadAd> {
  MethodChannel? _channel;

  @override
  Widget build(BuildContext context) {
    final isBanner = widget.adType == AdType.banner;
    final w = isBanner ? widget.width?.toDouble() : 1.0;
    final h = isBanner ? widget.height?.toDouble() : 1.0;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return SizedBox(
          width: w,
          height: h,
          child: AndroidView(
            viewType: 'setupad.plugin.setupad_prebid_flutter',
            onPlatformViewCreated: _onAndroidViewCreated,
          ),
        );
      case TargetPlatform.iOS:
        return SizedBox(
          width: w,
          height: h,
          child: UiKitView(
            viewType: 'setupad.plugin.setupad_prebid_flutter',
            onPlatformViewCreated: _oniOSViewCreated,
          ),
        );
      default:
        return Text('$defaultTargetPlatform is not yet supported by the plugin');
    }
  }

  /// Android: create channel, send params, attach controller, set callbacks.
  void _onAndroidViewCreated(int id) {
    final channel = MethodChannel('setupad.plugin.setupad_prebid_flutter/myChannel_$id');
    _wireChannel(channel);
    _sendParams(channel);
  }

  /// iOS: if your iOS side uses a per-view channel, replace with that.
  void _oniOSViewCreated(int id) {
    // If iOS uses per-view channels, mirror Android naming with id.
    // If your native iOS implementation uses a single channel, keep as below.
    final channel = const MethodChannel('setupad.plugin.setupad_prebid_flutter/ios');
    _wireChannel(channel);
    _sendParams(channel);
  }

  void _wireChannel(MethodChannel channel) {
    _channel = channel;
    widget.prebidController._attachChannel(channel);

    channel.setMethodCallHandler((call) async {
      final configId = call.arguments.toString();
      switch (call.method) {
        case "onAdLoaded":
          widget.eventListener.onAdLoaded(configId);
          break;
        case "onAdDisplayed":
          widget.eventListener.onAdDisplayed(configId);
          break;
        case "onAdFailed":
          widget.eventListener.onAdFailed(configId);
          break;
        case "onAdClicked":
          widget.eventListener.onAdClicked(configId);
          break;
        case "onAdClosed":
          widget.eventListener.onAdClosed(configId);
          break;
      }
    });
  }

  void _sendParams(MethodChannel channel) {
    debugPrint("PrebidPluginLog setParams");
    channel.invokeMethod('setParams', {
      "adType": widget.adType.name,
      "configId": widget.configId,
      "adUnitId": widget.adUnitId,
      "height": widget.height,
      "width": widget.width,
      "refreshInterval": widget.refreshInterval,
    });
  }

  @override
  void dispose() {
    // Optionally destroy on dispose:
    // widget.prebidController.destroyAuction();
    super.dispose();
  }
}
