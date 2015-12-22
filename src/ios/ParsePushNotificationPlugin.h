#import <Cordova/CDV.h>
#import "AppDelegate.h"

@interface ParsePushNotificationPlugin: CDVPlugin

@property NSString *callbackIdKeepCallback;
@property NSString *applicationId;
@property NSString *clientKey;
@property NSMutableDictionary *notifications;

- (void)setUp: (CDVInvokedUrlCommand*)command;
- (void)getDeviceToken: (CDVInvokedUrlCommand *)command;
- (void)subscribeToChannel: (CDVInvokedUrlCommand *)command;
- (void)unsubscribe: (CDVInvokedUrlCommand *)command;
- (void)parseSetupError: (NSString *) msg;

- (CDVPlugin *)getCommandDelegate;
- (NSMutableDictionary *)getStoredNotifications;
- (void)readNotifications: (NSDictionary *)notifications;
- (void)performNotificationCB;
@end

@interface AppDelegate (ParsePushNotificationPlugin)

@property (strong, nonatomic) ParsePushNotificationPlugin* instance;
@property NSString* stringInstance;

@end
