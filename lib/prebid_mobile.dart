import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:setupad_prebid_flutter/prebid_sdk_listener.dart';

///A class used to initialize Prebid Mobile SDK
class PrebidMobile {
  const PrebidMobile();
  static late PrebidSdkListener _sdkListener;
  static const MethodChannel _pluginChannel =
  MethodChannel('setupad.plugin.setupad_prebid_flutter/sdk');

  ///initializeSDK() passes to the native side Prebid account ID
  Future<void> initializeSDK(
      String prebidHost,
      String configHost,
      String prebidAccountID,
      int timeoutMillis,
      bool pbsDebug,
      PrebidSdkListener sdkListener
  ) {
    _sdkListener = sdkListener;
    _pluginChannel.setMethodCallHandler(_methodCallHandler);

    if(Platform.isAndroid){
      const MethodChannel channel = MethodChannel('setupad.plugin.setupad_prebid_flutter/android_init');
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

  static Future<dynamic> _methodCallHandler(MethodCall call) async {
    switch (call.method) {
      case "prebidSdkInitialized":
        debugPrint("PrebidSdkListener: prebidSdkInitialized ${call.arguments}");
        _sdkListener.onSdkInitialized(call.arguments);
        break;
      case "prebidSdkInitializeFailed":
        debugPrint("PrebidSdkListener: prebidSdkInitializeFailed ${call.arguments}");
        _sdkListener.onSdkInitializeFailed(call.arguments);
        break;
      default:
        debugPrint("PrebidSdkListener: unknown call ${call.method}");
    }
  }
}