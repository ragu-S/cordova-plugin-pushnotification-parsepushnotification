package com.cranberrygame.cordova.plugin.pushnotification.parsepushnotification.ParsePushNotificationPlugin;

import android.app.Application;
import android.util.Log;
import com.parse.Parse;
import com.parse.ParseInstallation;

/**
 * Created by Ragu on 16-05-17.
 */
public class ParseAndroidApplicationClass extends Application {
    @Override
    public void onCreate() {

        super.onCreate();

        String applicationId = ParsePushNotificationPlugin.getStringByKey(this, "parse_app_id");
        String clientKey = ParsePushNotificationPlugin.getStringByKey(this, "parse_client_key");

        try {
            // Need to set Parse settings
            Parse.initialize(this, applicationId, clientKey);
            ParseInstallation.getCurrentInstallation().saveInBackground();
        }
        catch(IllegalStateException e) {
            Log.e("Illegal Exception", "Parse initialized already");
        }
    }
}
