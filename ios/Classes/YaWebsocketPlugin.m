#import "YaWebsocketPlugin.h"
#if __has_include(<ya_websocket/ya_websocket-Swift.h>)
#import <ya_websocket/ya_websocket-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "ya_websocket-Swift.h"
#endif

@implementation YaWebsocketPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftYaWebsocketPlugin registerWithRegistrar:registrar];
}
@end
