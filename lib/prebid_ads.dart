import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:setupad_prebid_flutter/ad_type.dart';
import 'package:setupad_prebid_flutter/event_listener.dart';

/// Controller to drive a single PrebidAd instance via its platform MethodChannel.
class PrebidController {
  MethodChannel? _channel;

  /// Internal: attached by PrebidAd when the platform view is created.
  void _attachChannel(MethodChannel channel) {
    _channel = channel;
  }

  bool get isAttached => _channel != null;

  Future<void> loadInterstitial() async {
    if (_channel == null) return;
    await _channel!.invokeMethod('loadInterstitial');
  }

  Future<void> showInterstitial() async {
    if (_channel == null) return;
    await _channel!.invokeMethod('showInterstitial');
  }

  Future<void> hideInterstitial() async {
    if (_channel == null) return;
    await _channel!.invokeMethod('hideInterstitial');
  }

  Future<void> hideBanner() async {
    if (_channel == null) return;
    await _channel!.invokeMethod('hideBanner');
  }

  Future<void> pauseAuction() async {
    if (_channel == null) return;
    await _channel!.invokeMethod('pauseAuction');
  }

  Future<void> resumeAuction() async {
    if (_channel == null) return;
    await _channel!.invokeMethod('resumeAuction');
  }

  Future<void> destroyAuction() async {
    if (_channel == null) return;
    await _channel!.invokeMethod('destroyAuction');
  }
}

class PrebidAd extends StatefulWidget {
  const PrebidAd({
    Key? key,
    required this.adType,
    required this.configId,
    required this.adUnitId,
    required this.width,
    required this.height,
    required this.refreshInterval,
    required this.eventListener,
    required this.prebidController,
  }) : super(key: key);

  final AdType adType;
  final String configId;
  final String adUnitId;
  final int? width;
  final int? height;
  final int? refreshInterval;
  final EventListener eventListener;
  final PrebidController prebidController;

  @override
  State<PrebidAd> createState() => _PrebidAdState();
}

class _PrebidAdState extends State<PrebidAd> {
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
