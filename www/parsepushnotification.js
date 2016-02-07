module.exports = {
    setUp: function(appId, clientKey) {
        var self = this;
        cordova.exec(
            function (result) {
                if (typeof result == "string") {
                    if (result == "onSubscribeToChannelSucceeded") {
                        if (self.onSubscribeToChannelSucceeded)
                            self.onSubscribeToChannelSucceeded();
                    }
                    else if (result == "onUnsubscribeSucceeded") {
                        if (self.onUnsubscribeSucceeded)
                            self.onUnsubscribeSucceeded();
                    }
                }
                else {
                    if(result["getTokenCall"]) {
                        if(self.onDeviceTokenReceived)
                            self.onDeviceTokenReceived(result);
                    }
                    else if(result["notificationReceived"]) {
                        if(self.onNotificationReceived)
                            self.onNotificationReceived(result);
                    }
                }
            },
            function (error) {
                if (typeof result == "string") {
                    if (result == "onSubscribeFailed") {
                        if (self.onSubscribeToChannelFailed)
                            self.onSubscribeToChannelFailed();
                    }
                    else if (result == "onUnsubscribeFailed") {
                        if (self.onUnsubscribeFailed)
                            self.onUnsubscribeFailed();
                    }
                }
            },
            'ParsePushNotificationPlugin',
            'setUp',
            [appId, clientKey]
        );
    },

    subscribeToChannel: function(channel, successCB, errorCB) {
        var self = this;
        cordova.exec(
            successCB,
            errorCB,
            'ParsePushNotificationPlugin',
            'subscribeToChannel',
            [channel]
        );
    },
    unsubscribe: function(channel) {
        var self = this;
        cordova.exec(
            null,
            null,
            'ParsePushNotificationPlugin',
            'unsubscribe',
            [channel]
        );
    },
    getDeviceToken: function(successCB, errorCB) {
        cordova.exec(
            successCB,
            errorCB,
            'ParsePushNotificationPlugin',
            'getDeviceToken',
            []
        );
    },
    onNotificationReceived: function(successCB, errorCB) {
        var self = this;
        cordova.exec(
            successCB,
            errorCB,
            'ParsePushNotificationPlugin',
            'onNotificationReceived',
            []
        );
    },
    onNotificationOpened: function(successCB, errorCB) {
        var self = this;
        cordova.exec(
            successCB,
            errorCB,
            'ParsePushNotificationPlugin',
            'onNotificationOpened',
            []
        );
    },
    onSubscribeToChannelSucceeded: null,
    onSubscribeToChannelFailed: null,
    onUnsubscribeSucceeded: null,
    onUnsubscribeFailed: null
};
