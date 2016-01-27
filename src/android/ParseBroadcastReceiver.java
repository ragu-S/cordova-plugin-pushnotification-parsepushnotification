package com.cranberrygame.cordova.plugin.pushnotification.parsepushnotification;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.util.Log;

import com.parse.Parse;
import com.parse.ParseInstallation;
import com.parse.ParsePushBroadcastReceiver;

import org.json.JSONException;
import org.json.JSONObject;

public class ParseBroadcastReceiver extends ParsePushBroadcastReceiver {
    private static final String LOG_TAG = "ParsePushNotificationPlugin";
    private static ParsePushNotificationPlugin pluginInstance = null;
    @Override
    public void onReceive(Context context, Intent intent) {
        if(ParsePushNotificationPlugin.callbackContextKeepCallback == null) {
            SharedPreferences sharedPref = context.getApplicationContext().getSharedPreferences("cordova-plugin-pushnotification-parse", Context.MODE_PRIVATE);
            String applicationId = sharedPref.getString("applicationId", "");
            String clientKey = sharedPref.getString("clientKey", "");
            Parse.initialize(context.getApplicationContext(), applicationId, clientKey);
        }
        super.onReceive(context, intent);
    }
    @Override
    protected void onPushReceive(Context context, Intent intent) {
        Log.d(LOG_TAG, String.format("%s", "notificationreceived!"));
        Log.d(LOG_TAG, String.format("%s", "end of log"));
        // Android keeps closing application and terminating Parse
        if (ParsePushNotificationPlugin.destroyed()) {
            SharedPreferences sharedPref = context.getApplicationContext().getSharedPreferences("cordova-plugin-pushnotification-parse", Context.MODE_PRIVATE);
            String applicationId = sharedPref.getString("applicationId", "");
            String clientKey = sharedPref.getString("clientKey", "");
            Parse.initialize(context.getApplicationContext(), applicationId, clientKey);
            ParseInstallation.getCurrentInstallation().saveInBackground();
        }

        super.onPushReceive(context, intent);
    }
    @Override
    protected void onPushOpen(Context context, Intent intent) {
        Log.d(LOG_TAG, String.format("%s", "notification opened!"));

        try {

            JSONObject extras = new JSONObject(intent.getStringExtra("com.parse.Data"));
            extras.put("notificationReceived", "true");
            ParsePushNotificationPlugin.receivedNotification = extras;
        }
        catch (JSONException e) {
            Log.d(LOG_TAG, String.format("%s", "JSON error!"));
        }

        super.onPushOpen(context, intent);
    }
}
