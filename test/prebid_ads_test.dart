import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setupad_prebid_flutter/ad_type.dart';
import 'package:setupad_prebid_flutter/event_listener.dart';
import 'package:setupad_prebid_flutter/prebid_ads.dart';

class _Events implements EventListener {
  final values = <String>[];
  @override
  void onAdLoaded(String id) => values.add('loaded:$id');
  @override
  void onAdDisplayed(String id) => values.add('displayed:$id');
  @override
  void onAdFailed(String error) => values.add('failed:$error');
  @override
  void onAdClicked(String id) => values.add('clicked:$id');
  @override
  void onAdClosed(String id) => values.add('closed:$id');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  test('controller commands before view creation are safe', () async {
    final controller = PrebidController();
    await controller.loadBanner();
    await controller.showBanner();
    await controller.hideBanner();
    await controller.loadInterstitial();
    await controller.showInterstitial();
    await controller.hideInterstitial();
    await controller.pauseAuction();
    await controller.resumeAuction();
    await controller.destroyAuction();
    expect(controller.isAttached, false);
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final adType in AdType.values) {
      testWidgets('$platform $adType sends parameters, commands and events',
          (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        final calls = <MethodCall>[];
        Future<void> recordCall(MethodCall call) async {
          calls.add(call);
        }

        MethodChannel? channel;
        if (platform == TargetPlatform.android) {
          messenger.setMockMethodCallHandler(SystemChannels.platform_views,
              (call) async {
            if (call.method == 'create') {
              final id = (call.arguments as Map<Object?, Object?>)['id'] as int;
              channel = MethodChannel(
                  'setupad.plugin.setupad_prebid_flutter/myChannel_$id');
              messenger.setMockMethodCallHandler(channel!, recordCall);
            }
            return null;
          });
        } else {
          channel =
              const MethodChannel('setupad.plugin.setupad_prebid_flutter/ios');
          messenger.setMockMethodCallHandler(channel, recordCall);
        }
        final controller = PrebidController();
        final events = _Events();
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
                body: PrebidAd(
          adType: adType,
          configId: 'config',
          adUnitId: 'unit',
          width: adType == AdType.banner ? 320 : 100,
          height: adType == AdType.banner ? 50 : 100,
          refreshInterval: adType == AdType.banner ? 30 : null,
          eventListener: events,
          prebidController: controller,
        ))));
        if (platform == TargetPlatform.iOS) {
          expect(controller.isAttached, false);
          tester
              .widget<UiKitView>(find.byType(UiKitView))
              .onPlatformViewCreated!(7);
        }
        await tester.pump();
        expect(controller.isAttached, true);
        expect(calls.first.method, 'setParams');
        expect(calls.first.arguments, {
          'adType': adType.name,
          'configId': 'config',
          'adUnitId': 'unit',
          'height': adType == AdType.banner ? 50 : 100,
          'width': adType == AdType.banner ? 320 : 100,
          'refreshInterval': adType == AdType.banner ? 30 : null,
        });
        final platformView = platform == TargetPlatform.android
            ? find.byType(PlatformViewLink)
            : find.byType(UiKitView);
        final box = tester.widget<SizedBox>(find
            .ancestor(
              of: platformView,
              matching: find.byType(SizedBox),
            )
            .first);
        expect(box.width, adType == AdType.banner ? 320.0 : 1.0);
        expect(box.height, adType == AdType.banner ? 50.0 : 1.0);

        if (adType == AdType.banner) {
          await controller.loadBanner();
          await controller.showBanner();
          await controller.hideBanner();
          expect(calls.skip(1).map((call) => call.method), [
            'loadBanner',
            'showBanner',
            'hideBanner',
          ]);
        } else if (adType == AdType.interstitial) {
          await controller.loadInterstitial();
          await controller.showInterstitial();
          await controller.hideInterstitial();
          expect(calls.skip(1).map((call) => call.method), [
            'loadInterstitial',
            'showInterstitial',
            'hideInterstitial',
          ]);
        }

        const codec = StandardMethodCodec();
        for (final method in [
          'onAdLoaded',
          'onAdDisplayed',
          'onAdFailed',
          'onAdClicked',
          'onAdClosed'
        ]) {
          await messenger.handlePlatformMessage(
            channel!.name,
            codec.encodeMethodCall(MethodCall(method, 'value')),
            (_) {},
          );
        }
        expect(events.values, [
          'loaded:value',
          'displayed:value',
          'failed:value',
          'clicked:value',
          'closed:value',
        ]);
        messenger.setMockMethodCallHandler(channel!, null);
        if (platform == TargetPlatform.android) {
          messenger.setMockMethodCallHandler(
              SystemChannels.platform_views, null);
        }
        debugDefaultTargetPlatformOverride = null;
      });
    }
  }
}
