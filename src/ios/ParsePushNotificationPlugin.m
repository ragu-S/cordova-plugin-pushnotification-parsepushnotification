#import "ParsePushNotificationPlugin.h"
#import <Cordova/CDV.h>
#import <Parse/Parse.h>
#import <objc/runtime.h>
#import <objc/message.h>

@implementation ParsePushNotificationPlugin

@synthesize callbackIdKeepCallback;
@synthesize notificationRecievedCb;
@synthesize notificationOpenedCb;

- (void) pluginInitialize {
    NSLog(@"%@", @"Plugin initalized");
    
    NSString * appId  = [[NSBundle mainBundle].infoDictionary objectForKey:@"parse_app_id"];
    NSString * clientKey  = [[NSBundle mainBundle].infoDictionary objectForKey:@"parse_client_key"];
    
    if (appId.length == 0 || clientKey.length == 0) {
        NSLog(@"%@", @"Error! appId or clientKey not found");
        return;
    }
    
    [Parse setApplicationId:appId clientKey:clientKey];
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation save];
}

- (void)getDeviceToken: (CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        [self _getDeviceToken: command.callbackId];
    }];
}

- (void)subscribeToChannel: (CDVInvokedUrlCommand *)command {
    NSString* channel = [command.arguments objectAtIndex:0];
    NSLog(@"%@", channel);

    [self.commandDelegate runInBackground:^{
        [self _subscribeToChannel: channel callbackId:command.callbackId];
    }];
}

- (void)unsubscribe: (CDVInvokedUrlCommand *)command {
    NSString* channel = [command.arguments objectAtIndex:0];
    NSLog(@"%@", channel);

    [self.commandDelegate runInBackground:^{
        [self _unsubscribe:channel callbackId:command.callbackId];
    }];
}

- (void) onNotificationReceived: (CDVInvokedUrlCommand *)command {
    self.notificationRecievedCb = command.callbackId;
    
}
- (void) onNotificationOpened: (CDVInvokedUrlCommand *)command {
    self.notificationOpenedCb = command.callbackId;
    
}
- (void) _getDeviceToken: (NSString *) callbackId {
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    NSString *deviceToken = [currentInstallation deviceToken];
    CDVPluginResult* pr;
    
    if (!deviceToken) {
        deviceToken = @"";
        
        pr = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"Error unable to find device token, check if certificate or provisioning profile is setup correctly"];
    }
    else {
        
        NSDictionary *deviceInfo = @{
            @"getTokenCall" : @"YES",
            @"deviceToken" : deviceToken,
        };
        
        pr = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:deviceInfo];
    }
    
    [self.commandDelegate sendPluginResult:pr callbackId:callbackId];
}

- (void) _subscribeToChannel:(NSString *)channel callbackId: (NSString *) callbackId {
    // Register for Push Notitications iOS 8
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                        UIUserNotificationTypeBadge |
                                                        UIUserNotificationTypeSound);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes categories:nil];

        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        // Register for Push Notifications before iOS 8
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
    }

    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation addUniqueObject:channel forKey:@"channels"];
    [currentInstallation save];

    CDVPluginResult* pr = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"onSubscribeToChannelSucceeded"];

    [self.commandDelegate sendPluginResult:pr callbackId: callbackId];
}

- (void) _unsubscribe:(NSString *)channel callbackId: (NSString *) callbackId {
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation removeObject:channel forKey:@"channels"];
    [currentInstallation save];

    CDVPluginResult* pr = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"onUnsubscribeSucceeded"];
    [pr setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pr callbackId:callbackId];
}

- (void) _notificationOpened:(NSDictionary *) notificationData applicationState: (NSString *) appState {
    NSMutableDictionary* notifications = [notificationData mutableCopy];
    [notifications setObject:@"true" forKey:@"notificationOpened"];
    [notifications setObject:appState forKey:@"applicationState"];

    CDVPluginResult* pr = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary: [NSDictionary dictionaryWithDictionary:notifications]];
    
    [pr setKeepCallbackAsBool:YES];
    
    [self.commandDelegate sendPluginResult: pr callbackId: self.notificationOpenedCb];
}

- (void) _notificationReceived:(NSDictionary*) notificationData applicationState: (NSString *) appState {
    NSMutableDictionary* notifications = [notificationData mutableCopy];
    [notifications setObject:appState forKey:@"applicationState"];
    
    CDVPluginResult* pr = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary: [NSDictionary dictionaryWithDictionary:notifications]];
    
    [pr setKeepCallbackAsBool:YES];
    
    [self.commandDelegate sendPluginResult: pr callbackId: self.notificationRecievedCb];
}
@end

@implementation AppDelegate (ParsePushNotificationPlugin)

#pragma mark Push Notifications
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];

    [PFPush subscribeToChannelInBackground:@"" block:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"ParseStarterProject successfully subscribed to push notifications on the broadcast channel.");
        } else {
            NSLog(@"ParseStarterProject failed to subscribe to push notifications on the broadcast channel.");
        }
    }];
}
- (void)application:(UIApplication *)application
didFailToRegisterForRemoteNotificationsWithError:(NSError *)error

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSMutableString* errorMsg = [NSMutableString stringWithString:@""];
    if (error.code == 3010) {
        [errorMsg appendString:@"Push notifications are not supported in the iOS Simulator."];
    } else {
        // show some alert or otherwise handle the failure to register.
        [errorMsg appendString:@"application:didFailToRegisterForRemoteNotificationsWithError: %@"];
        // [errorMsg appendString:error.localizedDescription];
    }
    NSLog(errorMsg);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"Received Notification in background!");
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    NSString* appState;
    if (state == UIApplicationStateBackground || state == UIApplicationStateInactive) {
        appState = @"background";
    }
    else {
        appState = @"foreground";
    }
    
    [PFPush handlePush:userInfo];
    [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    ParsePushNotificationPlugin* plug = [appDelegate.viewController.pluginObjects objectForKey:@"ParsePushNotificationPlugin"];
    
    [plug.commandDelegate runInBackground:^{
        [plug _notificationReceived: userInfo applicationState:appState];
    }];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler: (void (^)(UIBackgroundFetchResult result))completionHandler {
    NSLog(@"notification clicked");
    NSString* appState;
    
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if (state == UIApplicationStateBackground || state == UIApplicationStateInactive) {
        appState = @"background";
    }
    else {
        appState = @"foreground";
    }
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    ParsePushNotificationPlugin* plug = [appDelegate.viewController.pluginObjects objectForKey:@"ParsePushNotificationPlugin"];
    
    [plug.commandDelegate runInBackground:^{
        [plug _notificationOpened: userInfo applicationState:appState];
    }];
    
    completionHandler(UIBackgroundFetchResultNewData);
}
@end
