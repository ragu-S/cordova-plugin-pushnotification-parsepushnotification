#import <Cordova/CDV.h>
#import "AppDelegate.h"

@interface ParsePushNotificationPlugin: CDVPlugin

@property NSString *callbackIdKeepCallback;
@property NSString *applicationId;
@property NSString *clientKey;

- (void)setUp: (CDVInvokedUrlCommand*)command;
- (void)getDeviceToken: (CDVInvokedUrlCommand *)command;
- (void)subscribeToChannel: (CDVInvokedUrlCommand *)command;
- (void)unsubscribe: (CDVInvokedUrlCommand *)command;
- (void)parseSetupError: (NSString *) msg;
- (NSMutableDictionary *)getStoredNotifications;
- (void)readNotifications: (NSDictionary *)notifications;
- (void)performNotificationCB;
@end

@interface AppDelegate (ParsePushNotificationPlugin)
@end
