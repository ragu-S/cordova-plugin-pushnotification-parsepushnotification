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
            //[self _getDeviceToken];
        } else {
            NSLog(@"ParseStarterProject failed to subscribe to push notifications on the broadcast channel.");
        }
    }];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (error.code == 3010) {
        NSLog(@"Push notifications are not supported in the iOS Simulator.");
    } else {
        // show some alert or otherwise handle the failure to register.
        NSLog(@"application:didFailToRegisterForRemoteNotificationsWithError: %@", error);
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
    NSLog(@"Received Notification!");
    if (application.applicationState == UIApplicationStateInactive) {
        [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
}
@end

