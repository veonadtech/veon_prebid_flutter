import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'setupad_prebid_flutter_method_channel.dart';

abstract class SetupadPrebidFlutterPlatform extends PlatformInterface {
  /// Constructs a SetupadPrebidFlutterPlatform.
  SetupadPrebidFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static SetupadPrebidFlutterPlatform _instance = MethodChannelSetupadPrebidFlutter();

  /// The default instance of [SetupadPrebidFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelSetupadPrebidFlutter].
  static SetupadPrebidFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SetupadPrebidFlutterPlatform] when
  /// they register themselves.
  static set instance(SetupadPrebidFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
