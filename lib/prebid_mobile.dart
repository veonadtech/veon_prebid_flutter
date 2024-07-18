import 'package:flutter/services.dart';

///A class used to initialize Prebid Mobile SDK
class PrebidMobile {
  const PrebidMobile();

  ///initializeSDK() passes to the native side Prebid account ID
  Future<void> initializeSDK(
      String prebidAccountID, int timeoutMillis, bool pbsDebug) {
    const MethodChannel channel =
        MethodChannel('setupad.plugin.setupad_prebid_flutter/myChannel_0');
    return channel.invokeMethod('startPrebid', {
      "accountID": prebidAccountID,
      "timeoutMillis": timeoutMillis,
      "pbsDebug": pbsDebug
    });
  }
}
