//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<idwise_flutter_sdk/IdwiseFlutterPlugin.h>)
#import <idwise_flutter_sdk/IdwiseFlutterPlugin.h>
#else
@import idwise_flutter_sdk;
#endif

#if __has_include(<shared_preferences_foundation/SharedPreferencesPlugin.h>)
#import <shared_preferences_foundation/SharedPreferencesPlugin.h>
#else
@import shared_preferences_foundation;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [IdwiseFlutterPlugin registerWithRegistrar:[registry registrarForPlugin:@"IdwiseFlutterPlugin"]];
  [SharedPreferencesPlugin registerWithRegistrar:[registry registrarForPlugin:@"SharedPreferencesPlugin"]];
}

@end
