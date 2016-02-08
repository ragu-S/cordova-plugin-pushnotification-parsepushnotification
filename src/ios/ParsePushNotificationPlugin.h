#import <Cordova/CDV.h>
#import "AppDelegate.h"

@interface ParsePushNotificationPlugin: CDVPlugin

@property NSString *callbackIdKeepCallback;
@property NSString *notificationRecievedCb;
@property NSString *notificationOpenedCb;

- (void)getDeviceToken: (CDVInvokedUrlCommand *)command;
- (void)subscribeToChannel: (CDVInvokedUrlCommand *)command;
- (void)unsubscribe: (CDVInvokedUrlCommand *)command;
- (void) onNotificationReceived: (CDVInvokedUrlCommand *)command;
- (void) onNotificationOpened: (CDVInvokedUrlCommand *)command;
@end

@interface AppDelegate (ParsePushNotificationPlugin)
@end
