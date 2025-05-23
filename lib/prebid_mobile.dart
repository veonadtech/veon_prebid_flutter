import 'dart:io';

import 'package:flutter/services.dart';

///A class used to initialize Prebid Mobile SDK
class PrebidMobile {
  const PrebidMobile();

  ///initializeSDK() passes to the native side Prebid account ID
  Future<void> initializeSDK(
      String prebidHost,
      String prebidAccountID,
      int timeoutMillis,
      int creativeLoadingTimeout,
      int preRenderContentTimeout,
      bool pbsDebug
  ) {
    if(Platform.isAndroid){
      const MethodChannel channel = MethodChannel('setupad.plugin.setupad_prebid_flutter/android');
      return channel.invokeMethod('startPrebid', {
        "host": prebidHost,
        "accountID": prebidAccountID,
        "timeoutMillis": timeoutMillis,
        "creativeLoadingTimeout": creativeLoadingTimeout,
        "preRenderContentTimeout": preRenderContentTimeout,
        "pbsDebug": pbsDebug
      });
    }else{
      const MethodChannel channel = MethodChannel('setupad.plugin.setupad_prebid_flutter/ios_init');
      return channel.invokeMethod('startPrebid', {
        "accountID": prebidAccountID,
        "host": prebidHost,
        "timeoutMillis": timeoutMillis,
        "pbsDebug": pbsDebug
      });
    }
  }
}