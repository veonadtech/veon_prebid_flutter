import 'package:flutter_test/flutter_test.dart';
import 'package:setupad_prebid_flutter/setupad_prebid_flutter.dart';
import 'package:setupad_prebid_flutter/setupad_prebid_flutter_platform_interface.dart';
import 'package:setupad_prebid_flutter/setupad_prebid_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSetupadPrebidFlutterPlatform
    with MockPlatformInterfaceMixin
    implements SetupadPrebidFlutterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SetupadPrebidFlutterPlatform initialPlatform = SetupadPrebidFlutterPlatform.instance;

  test('$MethodChannelSetupadPrebidFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSetupadPrebidFlutter>());
  });

  test('getPlatformVersion', () async {
    SetupadPrebidFlutter setupadPrebidFlutterPlugin = SetupadPrebidFlutter();
    MockSetupadPrebidFlutterPlatform fakePlatform = MockSetupadPrebidFlutterPlatform();
    SetupadPrebidFlutterPlatform.instance = fakePlatform;

    expect(await setupadPrebidFlutterPlugin.getPlatformVersion(), '42');
  });
}
