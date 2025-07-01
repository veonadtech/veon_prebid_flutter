import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:setupad_prebid_flutter/ad_type.dart';
import 'package:setupad_prebid_flutter/event_listener.dart';

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
  }) : super(key: key);

  final AdType adType;
  final String configId;
  final String adUnitId;
  final int? width;
  final int? height;
  final int? refreshInterval;
  final EventListener eventListener;

  @override
  State<PrebidAd> createState() => _PrebidAdState();
}

class _PrebidAdState extends State<PrebidAd> {
  bool _isAdLoaded = false;
  bool _hasError = false;
  MethodChannel? _channel;
  int? _viewId;

  @override
  Widget build(BuildContext context) {
    SizedBox sizedBox;
    if (_hasError) {
      sizedBox = const SizedBox.shrink();
    } else if (!_isAdLoaded) {
      // width and height should not be equal 0.
      sizedBox = SizedBox(
        width: 0.001,
        height: 0.001,
        child: _buildPlatformView(),
      );
    } else
      sizedBox = SizedBox(
        width: widget.adType == AdType.banner ? widget.width?.toDouble() : 0,
        height: widget.adType == AdType.banner ? widget.height?.toDouble() : 0,
        child: _buildPlatformView(),
      );

    return sizedBox;
  }

  Widget _buildPlatformView() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidView(
          viewType: 'setupad.plugin.setupad_prebid_flutter',
          onPlatformViewCreated: (int id) {
            _onViewCreated(id, 'setupad.plugin.setupad_prebid_flutter/myChannel_$id');
          },
        );
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: 'setupad.plugin.setupad_prebid_flutter',
          onPlatformViewCreated: (int id) {
            _onViewCreated(id, 'setupad.plugin.setupad_prebid_flutter/ios');
          },
        );
      default:
        return Text(
          '$defaultTargetPlatform is not yet supported by the plugin',
        );
    }
  }

  ///A method that passes ad parameters to the PassParameters class
  ///The unique ID is used for method channel communication
  void _onViewCreated(int id, String chanelName) {
    _viewId = id;

    _channel = MethodChannel(chanelName);
    debugPrint("PrebidPluginLog view created");
    _channel!.invokeMethod('setParams', {
      "adType": widget.adType.name,
      "configId": widget.configId,
      "adUnitId": widget.adUnitId,
      "height": widget.height,
      "width": widget.width,
      "refreshInterval": widget.refreshInterval
    });

    _channel!.setMethodCallHandler(_methodCallHandler);
  }

  Future<dynamic> _methodCallHandler(MethodCall call) async {
    final configId = call.arguments.toString();

    switch (call.method) {
      case "onAdLoaded":
        if (!_isAdLoaded) {
          setState(() {
            _isAdLoaded = true;
          });
        }
        widget.eventListener.onAdLoaded(configId);
        break;
      case "onAdDisplayed":
        widget.eventListener.onAdDisplayed(configId);
        break;
      case "onAdFailed":
        if (!_isAdLoaded) {
          setState(() {
            _hasError = true;
          });
        }
        widget.eventListener.onAdFailed(configId);
        break;
      case "onAdClicked":
        widget.eventListener.onAdClicked(configId);
        break;
      case "onAdUrlClicked":
        widget.eventListener.onAdUrlClicked(configId);
        break;
      case "onAdClosed":
        widget.eventListener.onAdClosed(configId);
        break;
    }
  }

  ///A method that pauses Prebid auction
  void pauseAuction() {
    if (_viewId != null) {
      debugPrint("PrebidPluginLog pauseAuction");
      _channel?.invokeMethod('pauseAuction');
    }
  }

  ///A method that resumes Prebid auction
  void resumeAuction() {
    if (_viewId != null) {
      debugPrint("PrebidPluginLog resumeAuction");
      _channel?.invokeMethod('resumeAuction');
    }
  }

  ///A method that destroys Prebid auction
  void destroyAuction() {
    if (_viewId != null) {
      debugPrint("PrebidPluginLog destroyAuction");
      _channel?.invokeMethod('destroyAuction');
    }
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }
}