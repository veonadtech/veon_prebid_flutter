import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setupad_prebid_flutter/prebid_mobile.dart';
import 'package:setupad_prebid_flutter/prebid_sdk_listener.dart';

class _Listener implements PrebidSdkListener {
  final initialized = <String>[];
  final failed = <String>[];

  @override
  void onSdkInitialized(String status) => initialized.add(status);

  @override
  void onSdkInitializeFailed(String errorMessage) => failed.add(errorMessage);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const sdk = MethodChannel('setupad.plugin.setupad_prebid_flutter/sdk');
  const android = MethodChannel('setupad.plugin.setupad_prebid_flutter/android_init');
  const ios = MethodChannel('setupad.plugin.setupad_prebid_flutter/ios_init');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(android, null);
    messenger.setMockMethodCallHandler(ios, null);
    messenger.setMockMethodCallHandler(sdk, null);
    debugDefaultTargetPlatformOverride = null;
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    test('initializeSDK sends $platform arguments and forwards callbacks', () async {
      debugDefaultTargetPlatformOverride = platform;
      final calls = <MethodCall>[];
      final channel = platform == TargetPlatform.android ? android : ios;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
      final listener = _Listener();
      await const PrebidMobile().initializeSDK(
        'https://bid.example/auction',
        'https://config.example/config.json',
        'account',
        30000,
        true,
        false,
        listener,
      );
      expect(calls, hasLength(1));
      expect(calls.single.method, 'startPrebid');
      final args = Map<String, Object?>.from(calls.single.arguments as Map);
      expect(args['accountID'], 'account');
      expect(args['prebidHost'], 'https://bid.example/auction');
      expect(args['timeoutMillis'], 30000);
      expect(args['pbsDebug'], true);
      if (platform == TargetPlatform.android) {
        expect(args['configHost'], 'https://config.example/config.json');
        expect(args['externalBrowser'], false);
      }

      Future<void> callback(String method, String value) async {
        const codec = StandardMethodCodec();
        await messenger.handlePlatformMessage(
          sdk.name,
          codec.encodeMethodCall(MethodCall(method, value)),
          (_) {},
        );
      }

      await callback('prebidSdkInitialized', 'ready');
      await callback('prebidSdkInitializeFailed', 'failed');
      expect(listener.initialized, ['ready']);
      expect(listener.failed, ['failed']);
    });
  }
}
