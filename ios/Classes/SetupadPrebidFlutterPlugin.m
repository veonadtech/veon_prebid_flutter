#import "SetupadPrebidFlutterPlugin.h"
#if __has_include(<setupad_prebid_flutter/setupad_prebid_flutter-Swift.h>)
#import <setupad_prebid_flutter/setupad_prebid_flutter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "setupad_prebid_flutter-Swift.h"
#endif

@implementation SetupadPrebidFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftSetupadPrebidFlutterPlugin registerWithRegistrar:registrar];
}
@end