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
const _gamAdUnitId = '/21775744923/example/fixed-size-banner';
const _host = 'http://10.0.2.2:8000';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android displays the local Prebid banner', (tester) async {
    expect(Platform.isAndroid, isTrue);

    final sdkReady = Completer<String>();
    await const PrebidMobile().initializeSDK(
      '$_host/openrtb2/auction',
      '$_host/static/e2e-config.json',
      'test',
      30000,
      true,
      false,
      _SdkListener(sdkReady),
    );
    final status = await sdkReady.future.timeout(const Duration(seconds: 30));
    expect(status, 'successfully');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 2)),
    );

    final controller = PrebidController();
    final displayed = Completer<void>();
    final clicked = Completer<void>();
    final errors = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xffdddddd),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Local PBS banner'),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: PrebidAd(
                    adType: AdType.banner,
                    configId: _configId,
                    adUnitId: _gamAdUnitId,
                    width: 300,
                    height: 250,
                    refreshInterval: 30,
                    eventListener:
                        _BannerListener(controller, displayed, clicked, errors),
                    prebidController: controller,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final shown = await tester.runAsync(() async {
      try {
        await displayed.future.timeout(const Duration(seconds: 60));
        return true;
      } on TimeoutException {
        return false;
      }
    });
    expect(shown, isTrue, reason: 'Prebid banner was not displayed: $errors');
    debugPrint('PBS_CREATIVE_DISPLAYED');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 7)),
    );
    await tester.tap(find.byType(PrebidAd));
    await tester.pump();
    final didClick = await tester.runAsync(() async {
      try {
        await clicked.future.timeout(const Duration(seconds: 20));
        return true;
      } on TimeoutException {
        return false;
      }
    });
    expect(didClick, isTrue,
        reason: 'Banner click callback was not received: $errors');
    debugPrint('PBS_CREATIVE_CLICKED');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 8)),
    );
  });
}

class _SdkListener implements PrebidSdkListener {
  _SdkListener(this.ready);

  final Completer<String> ready;

  @override
  void onSdkInitialized(String status) => ready.complete(status);

  @override
  void onSdkInitializeFailed(String errorMessage) =>
      ready.completeError(StateError(errorMessage));
}

class _BannerListener implements EventListener {
  _BannerListener(this.controller, this.displayed, this.clicked, this.errors);

  final PrebidController controller;
  final Completer<void> displayed;
  final Completer<void> clicked;
  final List<String> errors;

  @override
  void onAdLoaded(String configId) {
    if (configId == _configId) {
      controller.showBanner().catchError((Object error) {
        errors.add('showBanner: $error');
      });
    }
  }

  @override
  void onAdFailed(String errorMessage) {
    errors.add(errorMessage);
    debugPrint('Native banner error: $errorMessage');
  }

  @override
  void onAdDisplayed(String configId) {
    if (configId == _configId && !displayed.isCompleted) displayed.complete();
  }

  @override
  void onAdClicked(String configId) {
    if (configId == _configId && !clicked.isCompleted) clicked.complete();
  }

  @override
  void onAdClosed(String configId) {}
}
