package com.cranberrygame.cordova.plugin.pushnotification.parsepushnotification;

import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.apache.cordova.CallbackContext;
import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONException;

import android.app.Application;
import android.util.Log;
import com.parse.*;

public class ParsePushNotificationPlugin extends CordovaPlugin {
    private static final String LOG_TAG = "ParsePushNotificationPlugin";
    public static CallbackContext callbackContextKeepCallback = null;

    private static CallbackContext notificationOpenedKeepCB = null;
    private static CallbackContext notificationReceivedKeepCB = null;

    private static boolean destroyed = true;
    public static ParsePushNotificationPlugin selfReference = null;
    public static JSONObject openedNotification = null;
    public static JSONObject receivedNotification = null;

    public static AppState state;

    public enum AppState {
        INITIALIZED,
        FOREGROUND,
        BACKGROUND,
        DESTROYED
    }

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);

        Application app = cordova.getActivity().getApplication();

        String applicationId = getStringByKey(app, "parse_app_id");
        String clientKey = getStringByKey(app, "parse_client_key");

        try {
            // Need to set Parse settings
            Parse.initialize(app, applicationId, clientKey);
            ParseInstallation.getCurrentInstallation().saveInBackground();
        }
        catch(IllegalStateException e) {
            Log.e("Illegal Exception", "Parse initialized already");
        }
    }

    private static String getStringByKey(Application app, String key) {
        int resourceId = app.getResources().getIdentifier(key, "string", app.getPackageName());
        return app.getString(resourceId);
    }

    @Override
    public void pluginInitialize() {
        super.pluginInitialize();

        // Store this instance that get initiated by Cordova plugin automatically
        selfReference = this;

        state = AppState.INITIALIZED;
    }


    @Override
    public void onPause(boolean multitasking) {
        state = AppState.BACKGROUND;

        super.onPause(multitasking);
    }

    @Override
    public void onResume(boolean multitasking) {
        state = AppState.FOREGROUND;
        super.onResume(multitasking);
    }

    @Override
    public void onDestroy() {
        state = AppState.DESTROYED;
        destroyed = true;

        super.onDestroy();
    }

    public static boolean destroyed() {
        return destroyed;
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        state = AppState.FOREGROUND;
        if(action.equals("onNotificationReceived")) {
            notificationReceivedKeepCB = callbackContext;
            if(receivedNotification != null) {
                notificationReceivedCB(receivedNotification);
            }
            return true;
        }
        if(action.equals("onNotificationOpened")) {
            notificationOpenedKeepCB = callbackContext;
            if(openedNotification != null) {
                notificationOpenedCB(openedNotification);
            }
            return true;
        }
        else if (action.equals("getDeviceToken")) {
            callbackContextKeepCallback = callbackContext;

            getDeviceToken(action, args, callbackContext);

            return true;
        }
        else if (action.equals("subscribeToChannel")) {
            callbackContextKeepCallback = callbackContext;

            subscribeToChannel(action, args, callbackContext);

            return true;
        }
        else if (action.equals("unsubscribe")) {
            callbackContextKeepCallback = callbackContext;

            unsubscribe(action, args, callbackContext);

            return true;
        }

        return false; // Returning false results in a "MethodNotFound" error.
    }

    public void notificationOpenedCB(final JSONObject notification) {
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (notificationOpenedKeepCB != null) {
                    PluginResult pr = new PluginResult(PluginResult.Status.OK, notification);
                    pr.setKeepCallback(true);

                    // Remove the notification if it was opened and read
                    openedNotification = null;

                    notificationOpenedKeepCB.sendPluginResult(pr);
                }
                else {
                    Log.e("NOTIFICATION ERROR", "notification Callback not available");
                }
            }
        });
    }

    public void notificationReceivedCB(final JSONObject notification) {
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (notificationReceivedKeepCB != null) {
                    PluginResult pr = new PluginResult(PluginResult.Status.OK, notification);
                    pr.setKeepCallback(true);

                    notificationReceivedKeepCB.sendPluginResult(pr);
                }
                else {
                    Log.e("NOTIFICATION ERROR", "notification Callback not available");
                }
            }
        });
    }

    private void getDeviceToken(String action, JSONArray args, final CallbackContext callbackContext) {
        final String deviceToken = ParseInstallation.getCurrentInstallation().getString("deviceToken");

        try {
            final JSONObject deviceInfo = new JSONObject();
            deviceInfo.put("getTokenCall", true);

            deviceInfo.put("deviceToken", deviceToken);

            cordova.getActivity().runOnUiThread(new Runnable(){
                @Override
                public void run() {
                    _getDeviceToken(deviceInfo, callbackContext);
                }
            });
        } catch (JSONException e) {
            Log.d("DEBUG", e.toString());
        }
    }

    private void _getDeviceToken(JSONObject deviceInfo, CallbackContext callbackContext) {
        PluginResult pr = new PluginResult(PluginResult.Status.OK, deviceInfo);
        pr.setKeepCallback(true);

        callbackContext.sendPluginResult(pr);
    }

    private void subscribeToChannel(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
        final String channel = args.getString(0);
        Log.d(LOG_TAG, String.format("%s", channel));

        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                _subscribeToChannel(channel, callbackContext);
            }
        });
    }

    private void unsubscribe(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        final String channel = args.getString(0);
        Log.d(LOG_TAG, String.format("%s",channel));

        cordova.getActivity().runOnUiThread(new Runnable(){
            @Override
            public void run() {
                _unsubscribe(channel);
            }
        });
    }

    private void _subscribeToChannel(String channel, final CallbackContext callback) {
        ParsePush.subscribeInBackground(channel, new SaveCallback() {
            @Override
            public void done(ParseException e) {
                if (e == null) {
                    PluginResult pr = new PluginResult(PluginResult.Status.OK, "onSubscribeToChannelSucceeded");
                    pr.setKeepCallback(true);
                    callback.sendPluginResult(pr);
                }
                else {
                    PluginResult pr = new PluginResult(PluginResult.Status.ERROR, "onSubscribeToChannelFailed");
                    pr.setKeepCallback(true);
                    callback.sendPluginResult(pr);
                }
            }
        });
    }

    private void _unsubscribe(String channel) {
        ParsePush.unsubscribeInBackground(channel, new SaveCallback() {
            @Override
            public void done(ParseException e) {
                if (e == null) {
                    PluginResult pr = new PluginResult(PluginResult.Status.OK, "onUnsubscribeSucceeded");
                    pr.setKeepCallback(true);
                    callbackContextKeepCallback.sendPluginResult(pr);
                }
                else {
                    PluginResult pr = new PluginResult(PluginResult.Status.ERROR, "onUnsubscribeFailed");
                    pr.setKeepCallback(true);
                    callbackContextKeepCallback.sendPluginResult(pr);
                }
            }
        });
    }
}
