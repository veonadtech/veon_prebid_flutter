import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'setupad_prebid_flutter_platform_interface.dart';

/// An implementation of [SetupadPrebidFlutterPlatform] that uses method channels.
class MethodChannelSetupadPrebidFlutter extends SetupadPrebidFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('setupad_prebid_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
