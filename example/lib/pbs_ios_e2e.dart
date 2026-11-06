import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:setupad_prebid_flutter/ad_type.dart';
import 'package:setupad_prebid_flutter/event_listener.dart';
import 'package:setupad_prebid_flutter/prebid_ads.dart';
import 'package:setupad_prebid_flutter/prebid_mobile.dart';
import 'package:setupad_prebid_flutter/prebid_sdk_listener.dart';

const _configId = 'test-imp-id';
const _host = 'http://127.0.0.1:8000';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await const PrebidMobile().initializeSDK(
    '$_host/openrtb2/auction',
    '$_host/static/e2e-config.json',
    'test',
    30000,
    true,
    false,
    _SdkListener(),
  );
  runApp(const _BannerApp());
}

class _BannerApp extends StatefulWidget {
  const _BannerApp();

  @override
  State<_BannerApp> createState() => _BannerAppState();
}

class _BannerAppState extends State<_BannerApp> implements EventListener {
  final controller = PrebidController();

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: PrebidAd(
              adType: AdType.banner,
              configId: _configId,
              adUnitId: 'invalid-gam-ad-unit-for-e2e',
              width: 300,
              height: 250,
              refreshInterval: 30,
              eventListener: this,
              prebidController: controller,
            ),
          ),
        ),
      );

  @override
  void onAdLoaded(String configId) {
    if (configId == _configId) unawaited(_showBanner());
  }

  Future<void> _showBanner() async {
    try {
      await controller.showBanner();
      final client = HttpClient();
      try {
        final request = await client.postUrl(Uri.parse('$_host/__e2e/ready'));
        final response = await request.close();
        if (response.statusCode != HttpStatus.ok) {
          throw StateError('Ready endpoint returned ${response.statusCode}');
        }
        await response.drain<void>();
      } finally {
        client.close();
      }
      debugPrint('PBS_IOS_CREATIVE_DISPLAYED');
    } catch (error) {
      debugPrint('Failed to show iOS E2E banner: $error');
    }
  }

  @override
  void onAdFailed(String errorMessage) =>
      debugPrint('Native banner error: $errorMessage');

  @override
  void onAdClicked(String configId) =>
      debugPrint('PBS_IOS_CREATIVE_CLICKED: $configId');

  @override
  void onAdDisplayed(String configId) {}

  @override
  void onAdClosed(String configId) {}
}

class _SdkListener implements PrebidSdkListener {
  @override
  void onSdkInitialized(String status) {}

  @override
  void onSdkInitializeFailed(String errorMessage) =>
      throw StateError(errorMessage);
}
