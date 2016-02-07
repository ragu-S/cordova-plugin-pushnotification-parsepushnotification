package com.cranberrygame.cordova.plugin.pushnotification.parsepushnotification;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import com.parse.ParsePushBroadcastReceiver;

import org.json.JSONException;
import org.json.JSONObject;

public class ParseBroadcastReceiver extends ParsePushBroadcastReceiver {
    private static final String LOG_TAG = "ParsePushNotificationPlugin";

    @Override
    protected void onPushReceive(Context context, Intent intent) {
        Log.d(LOG_TAG, String.format("%s", "notificationreceived!"));
        Log.d(LOG_TAG, String.format("%s", "end of log"));

        // Android keeps closing application and terminating Parse
        try {
            JSONObject extras = new JSONObject(intent.getStringExtra("com.parse.Data"));

            if(ParsePushNotificationPlugin.state == ParsePushNotificationPlugin.AppState.FOREGROUND) {
                extras.put("applicationState", "foreground");
            }
            else {
                extras.put("applicationState", "background");
            }
            if(ParsePushNotificationPlugin.selfReference != null) {
                // Do JS callback in app
                ParsePushNotificationPlugin.selfReference.notificationReceivedCB(extras);
            }
        }
        catch (JSONException e) {
            Log.d(LOG_TAG, String.format("%s", "JSON error!"));
        }

        super.onPushReceive(context, intent);
    }
    @Override
    protected void onPushOpen(Context context, Intent intent) {
        Log.d(LOG_TAG, String.format("%s", "notification opened!"));

        try {
            JSONObject extras = new JSONObject(intent.getStringExtra("com.parse.Data"));
            extras.put("notificationOpened", "true");

            if(ParsePushNotificationPlugin.state == ParsePushNotificationPlugin.AppState.FOREGROUND) {
                extras.put("applicationState", "foreground");

                ParsePushNotificationPlugin.openedNotification = extras;

                if(ParsePushNotificationPlugin.selfReference != null) {
                    // Do JS callback in app
                    ParsePushNotificationPlugin.selfReference.notificationOpenedCB(extras);
                }

                Log.d("NOTIFICATION", extras.toString());
            }
            else {
                Log.d("NOTIFICATION", extras.toString());
                extras.put("applicationState", "background");

                ParsePushNotificationPlugin.openedNotification = extras;

                Intent notificationIntent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
                Bundle bundle = intent.getExtras();
                bundle.putString("com.parse.Data", extras.toString());
                notificationIntent.putExtras(bundle);

                // Need to bring the activity back to foreground before calling notificationCB
                context.startActivity(notificationIntent);

                if(ParsePushNotificationPlugin.selfReference != null) {
                    // Do JS callback in app
                    ParsePushNotificationPlugin.selfReference.notificationOpenedCB(extras);
                }
            }
        }
        catch (JSONException e) {
            Log.d(LOG_TAG, String.format("%s", "JSON error!"));
        }
    }
}
