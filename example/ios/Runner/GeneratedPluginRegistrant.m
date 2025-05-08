//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<app_tracking_transparency/AppTrackingTransparencyPlugin.h>)
#import <app_tracking_transparency/AppTrackingTransparencyPlugin.h>
#else
@import app_tracking_transparency;
#endif

#if __has_include(<integration_test/IntegrationTestPlugin.h>)
#import <integration_test/IntegrationTestPlugin.h>
#else
@import integration_test;
#endif

#if __has_include(<setupad_prebid_flutter/SetupadPrebidFlutterPlugin.h>)
#import <setupad_prebid_flutter/SetupadPrebidFlutterPlugin.h>
#else
@import setupad_prebid_flutter;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [AppTrackingTransparencyPlugin registerWithRegistrar:[registry registrarForPlugin:@"AppTrackingTransparencyPlugin"]];
  [IntegrationTestPlugin registerWithRegistrar:[registry registrarForPlugin:@"IntegrationTestPlugin"]];
  [SetupadPrebidFlutterPlugin registerWithRegistrar:[registry registrarForPlugin:@"SetupadPrebidFlutterPlugin"]];
}

@end
