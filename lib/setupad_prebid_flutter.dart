import 'setupad_prebid_flutter_platform_interface.dart';

class SetupadPrebidFlutter {
  Future<String?> getPlatformVersion() {
    return SetupadPrebidFlutterPlatform.instance.getPlatformVersion();
  }
}
