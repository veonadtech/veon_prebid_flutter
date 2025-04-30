import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ad_size.dart';

class PrebidBanner extends StatefulWidget {
  final PrebidAdSize adSize;
  final String publisherId;
  final String configId;
  final String adUnitId;
  final String serverHost;
  final void Function(String status)? onDemandFetched;
  final Color? backgroundColor;

  /// Size
  /// publisherID
  /// configId
  /// adUnitId
  const PrebidBanner({
    Key? key,
    required this.adSize,
    required this.adUnitId,
    required this.configId,
    required this.publisherId,
    required this.serverHost,
    this.onDemandFetched,
    this.backgroundColor,
  }) : super(key: key);

  @override
  _PrebidBannerState createState() => _PrebidBannerState();
}

class _PrebidBannerState extends State<PrebidBanner> {
  late DFPBannerViewController _controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor ?? Colors.grey[300],
      child: SizedBox(
        height: widget.adSize.height,
        width: widget.adSize.width,
        child: _build(context),
      ),
    );
  }

  Widget _build(BuildContext context) {
    if (Platform.isAndroid) {
      return AndroidView(
        viewType: 'plugins.capolista.se/prebid_mobile_flutter/banner',
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        viewType: 'plugins.capolista.se/prebid_mobile_flutter/banner',
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }
    // Platform not supported
    return const SizedBox.shrink();
  }

  void _onPlatformViewCreated(int id) {
    _controller = DFPBannerViewController._internal(
      id: id,
      publisherId: widget.publisherId,
      adSize: widget.adSize,
      configId: widget.configId,
      adUnitId: widget.adUnitId,
      serverHost: widget.serverHost,
      onDemandFetched: widget.onDemandFetched,
    );

    _controller._init();
  }
}

class DFPBannerViewController {
  final void Function(DFPBannerViewController controller)? onAdViewCreated;
  final Map<String, dynamic>? customTargeting;
  final String publisherId;
  final PrebidAdSize adSize;
  final String configId;
  final String adUnitId;
  final String serverHost;
  final void Function(String status)? onDemandFetched;
  final MethodChannel _channel;

  DFPBannerViewController._internal({
    this.onAdViewCreated,
    this.customTargeting,
    required this.adSize,
    required this.adUnitId,
    required this.configId,
    required this.serverHost,
    required this.publisherId,
    this.onDemandFetched,
    required int id,
  }) : _channel = MethodChannel(
          Platform.isIOS
              ? 'plugins.capolista.se/prebid_mobile_flutter/banner/$id'
              : 'plugins.capolista.se/prebid_mobile_flutter/banner/$id',
        );

  Future<void> reload() {
    return _load();
  }

  Future<void> _init() async {
    _channel.setMethodCallHandler(_handler);
    await _load();
  }

  Future<void> _load() {
    return _channel.invokeMethod('load', {
      "publisherId": publisherId,
      "adHeight": adSize.height,
      "adWidth": adSize.width,
      "configId": configId,
      "adUnitId": adUnitId,
      "serverHost": serverHost,
    });
  }

  Future<void> _handler(MethodCall call) async {
    switch (call.method) {
      case "demandFetched":
        if (onDemandFetched != null) {
          onDemandFetched!(call.arguments['name']);
        }
        break;
    }
  }
}
