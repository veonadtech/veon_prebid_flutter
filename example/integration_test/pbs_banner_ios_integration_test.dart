import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:setupad_prebid_flutter/ad_type.dart';
import 'package:setupad_prebid_flutter/event_listener.dart';
import 'package:setupad_prebid_flutter/prebid_ads.dart';
import 'package:setupad_prebid_flutter/prebid_mobile.dart';
import 'package:setupad_prebid_flutter/prebid_sdk_listener.dart';

const _configId = 'test-imp-id';
const _host = 'http://127.0.0.1:8000';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('iOS loads the local DSP banner', (tester) async {
    expect(Platform.isIOS, isTrue);

    await const PrebidMobile().initializeSDK(
      '$_host/openrtb2/auction',
      '$_host/static/e2e-config.json',
      'test',
      30000,
      true,
      false,
      _SdkListener(),
    );

    final controller = PrebidController();
    final loaded = Completer<void>();
    final errors = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PrebidAd(
              adType: AdType.banner,
              configId: _configId,
              gamAdUnitId: 'invalid-gam-ad-unit-for-e2e',
              width: 300,
              height: 250,
              refreshInterval: 30,
              eventListener: _BannerListener(loaded, errors),
              prebidController: controller,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final didLoad = await tester.runAsync(() async {
      try {
        await loaded.future.timeout(const Duration(seconds: 90));
        return true;
      } on TimeoutException {
        return false;
      }
    });
    expect(didLoad, isTrue, reason: 'Prebid banner was not loaded: $errors');
    await controller.showBanner();
    debugPrint('PBS_IOS_CREATIVE_DISPLAYED');
  });
}

class _SdkListener implements PrebidSdkListener {
  @override
  void onSdkInitialized(String status) {}

  @override
  void onSdkInitializeFailed(String errorMessage) =>
      throw StateError(errorMessage);
}

class _BannerListener implements EventListener {
  _BannerListener(this.loaded, this.errors);

  final Completer<void> loaded;
  final List<String> errors;

  @override
  void onAdLoaded(String configId) {
    if (configId == _configId && !loaded.isCompleted) loaded.complete();
  }

  @override
  void onAdFailed(String errorMessage) {
    errors.add(errorMessage);
    debugPrint('Native banner error: $errorMessage');
  }

  @override
  void onAdDisplayed(String configId) {}

  @override
  void onAdClicked(String configId) {}

  @override
  void onAdClosed(String configId) {}

  @override
  void onAdImpression(String configId) {}
}
