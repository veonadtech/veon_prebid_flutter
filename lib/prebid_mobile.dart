import 'dart:io';

import 'package:flutter/services.dart';

///A class used to initialize Prebid Mobile SDK
class PrebidMobile {
  const PrebidMobile();

  ///initializeSDK() passes to the native side Prebid account ID
  Future<void> initializeSDK(
      String prebidHost,
      String configHost,
      String prebidAccountID,
      int timeoutMillis,
      bool pbsDebug
  ) {
    if(Platform.isAndroid){
      const MethodChannel channel = MethodChannel('setupad.plugin.setupad_prebid_flutter/android');
      return channel.invokeMethod('startPrebid', {
        "prebidHost": prebidHost,
        "configHost": configHost,
        "accountID": prebidAccountID,
        "timeoutMillis": timeoutMillis,
        "pbsDebug": pbsDebug
      });
    }else{
      const MethodChannel channel = MethodChannel('setupad.plugin.setupad_prebid_flutter/ios_init');
      return channel.invokeMethod('startPrebid', {
        "accountID": prebidAccountID,
        "prebidHost": prebidHost,
        "timeoutMillis": timeoutMillis,
        "pbsDebug": pbsDebug
      });
    }
  }
}