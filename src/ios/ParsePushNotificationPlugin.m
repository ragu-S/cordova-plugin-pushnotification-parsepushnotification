#import "ParsePushNotificationPlugin.h"
#import <Cordova/CDV.h>
#import <Parse/Parse.h>
#import <objc/runtime.h>
#import <objc/message.h>

@implementation ParsePushNotificationPlugin

@synthesize callbackIdKeepCallback;
@synthesize applicationId;
@synthesize clientKey;

- (void)setUp: (CDVInvokedUrlCommand*)command {
    NSString* applicationId = [command.arguments objectAtIndex:0];
    NSString* clientKey = [command.arguments objectAtIndex:1];

    self.callbackIdKeepCallback = command.callbackId;

    [self.commandDelegate runInBackground:^{
        [self _setUp:applicationId aClientKey:clientKey];
    }];
}

- (void)getDeviceToken: (CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        [self _getDeviceToken];
    }];
}

- (void)subscribeToChannel: (CDVInvokedUrlCommand *)command {
    NSString* channel = [command.arguments objectAtIndex:0];
    NSLog(@"%@", channel);

    [self.commandDelegate runInBackground:^{
        [self _subscribeToChannel:channel];
    }];
}

- (void)unsubscribe: (CDVInvokedUrlCommand *)command {
    NSString* channel = [command.arguments objectAtIndex:0];
    NSLog(@"%@", channel);

    [self.commandDelegate runInBackground:^{
        [self _unsubscribe:channel];
    }];
}

- (void) getNotifications: (CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        [self _getStoredNotifications];
    }];
}

- (void) _setUp:(NSString *)applicationId aClientKey:(NSString *)clientKey {
    self.applicationId = applicationId;
    self.clientKey = clientKey;

    [Parse setApplicationId:applicationId clientKey:clientKey];
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation save];

    CDVPluginResult* pr = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"onRegisterAsPushNotificationClientSucceeded"];
    [pr setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pr callbackId:callbackIdKeepCallback];
}

- (void) _getDeviceToken {
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    NSString *deviceToken = [currentInstallation deviceToken];
    NSString *installationId = [currentInstallation installationId];

    if (!deviceToken) {
        deviceToken = @"";
    }
    if (!deviceToken) {
        installationId = @"";
    }

    NSDictionary *deviceInfo = @{
        @"getTokenCall" : @"YES",
        @"installationId" : installationId,
        @"deviceToken" : deviceToken,
    };

    //NSString *str = [NSString stringWithFormat:@"Device Token=%@",deviceToken];
    CDVPluginResult* pr = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:deviceInfo];
    [pr setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pr callbackId:callbackIdKeepCallback];
}

- (void) _subscribeToChannel:(NSString *)channel {
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
    [pr setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pr callbackId:callbackIdKeepCallback];
}

- (void) _unsubscribe:(NSString *)channel {
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation removeObject:channel forKey:@"channels"];
    [currentInstallation save];

    CDVPluginResult* pr = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"onUnsubscribeSucceeded"];
    [pr setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pr callbackId:callbackIdKeepCallback];
}

- (void) _getStoredNotifications {
    NSDictionary* dict = [self.getStoredNotifications copy];
    CDVPluginResult* pr = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary: dict];
    [pr setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult: pr callbackId: self.callbackIdKeepCallback];
}

- (void) parseSetupError:(NSString *)msg {
    NSDictionary *errorMessage = @{
     @"parseErrorMsg" : @"YES",
     @"message" : msg
    };

    CDVPluginResult* pr = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:errorMessage];
    [pr setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pr callbackId:callbackIdKeepCallback];
}

- (NSMutableDictionary *)getStoredNotifications {
    NSMutableDictionary* notifications = [NSMutableDictionary dictionary];
    [notifications setObject:@"true" forKey:@"notificationReceived"];
    [notifications setObject:@"iOS notification received" forKey:@"dealerNotification"];
    return notifications;
}
@end

@implementation AppDelegate (ParsePushNotificationPlugin)
NSString const *someKey = @"instance";

#pragma mark Push Notifications
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];

    [PFPush subscribeToChannelInBackground:@"" block:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"ParseStarterProject successfully subscribed to push notifications on the broadcast channel.");
            //[self _getDeviceToken];
        } else {
            NSLog(@"ParseStarterProject failed to subscribe to push notifications on the broadcast channel.");
        }
    }];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSMutableString* errorMsg = [NSMutableString stringWithString:@""];
    if (error.code == 3010) {
        [errorMsg appendString:@"Push notifications are not supported in the iOS Simulator."];
    } else {
        // show some alert or otherwise handle the failure to register.
        [errorMsg appendString:@"application:didFailToRegisterForRemoteNotificationsWithError: %@"];
        [errorMsg appendString:error.localizedDescription];
    }

    //[ParsePushNotificationPlugin parseSetupError: errorMsg];
}
- (NSString *)stringOutputForDictionary:(NSDictionary *)inputDict {
    NSMutableString * outputString = [NSMutableString stringWithCapacity:256];

    NSArray * allKeys = [inputDict allKeys];

    for (NSString * key in allKeys) {
        if ([[inputDict objectForKey:key] isKindOfClass:[NSDictionary class]]) {
            [outputString appendString: [self stringOutputForDictionary: (NSDictionary *)inputDict]];
        }
        else {
            [outputString appendString: key];
            [outputString appendString: @": "];
            [outputString appendString: [[inputDict objectForKey: key] description]];
        }
        [outputString appendString: @"\n"];
    }

    return [NSString stringWithString: outputString];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"Received Notification!");
    if (application.applicationState == UIApplicationStateInactive) {
        [PFPush handlePush:userInfo];
        [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    ParsePushNotificationPlugin* plug = [appDelegate.viewController.pluginObjects objectForKey:@"ParsePushNotificationPlugin"];
    NSMutableDictionary* mutableDict = [plug getStoredNotifications];
    NSDictionary* dict = [NSDictionary dictionaryWithDictionary:mutableDict];

    CDVPluginResult* pr = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary: dict];
    [pr setKeepCallbackAsBool:YES];
    [plug.commandDelegate sendPluginResult: pr callbackId: plug.callbackIdKeepCallback];

}
@end
