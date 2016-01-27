package com.cranberrygame.cordova.plugin.pushnotification.parsepushnotification;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.apache.cordova.CallbackContext;
import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONException;
import android.util.Log;
import com.parse.*;
import android.content.SharedPreferences;
import android.content.Context;

public class ParsePushNotificationPlugin extends CordovaPlugin {
    private static final String LOG_TAG = "ParsePushNotificationPlugin";
    public static CallbackContext callbackContextKeepCallback = null;
    private static CallbackContext notificationContextKeepCallback = null;
    private String applicationId;
    private String clientKey;
    private static boolean destroyed = false;
    public static ParsePushNotificationPlugin selfReference = null;
    public static JSONObject receivedNotification = null;
    public static String _appId;
    public static String _clientKey;
    public static AppState state;

    public enum AppState {
        INITIALIZED,
        FOREGROUND,
        BACKGROUND,
        DESTROYED
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
        if(action.equals("registerForNotificationCBs")) {
            notificationContextKeepCallback = callbackContext;
            if(receivedNotification != null) {
                notificationReceivedCB();
            }
            return true;
        } else if (action.equals("setUp")) {
            setUp(action, args, callbackContext);

            return true;
        }
        else if (action.equals("getDeviceToken")) {
            getDeviceToken(action, args, callbackContext);

            return true;
        }
        else if (action.equals("subscribeToChannel")) {
            subscribeToChannel(action, args, callbackContext);

            return true;
        }
        else if (action.equals("unsubscribe")) {
            unsubscribe(action, args, callbackContext);

            return true;
        }

        return false; // Returning false results in a "MethodNotFound" error.
    }

    private void setUp(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if(state == AppState.INITIALIZED) {

            final String applicationId = args.getString(0);
            final String clientKey = args.getString(1);

            _appId = applicationId;
            _clientKey = clientKey;

            Log.d(LOG_TAG, String.format("%s", applicationId));
            Log.d(LOG_TAG, String.format("%s", clientKey));

            callbackContextKeepCallback = callbackContext;

            cordova.getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    _setUp(applicationId, clientKey);
                }
            });
        }
        else {
            Log.e("NOTIFICATION ERROR", "Setup called again, when App is initialized");
        }
    }

    public void notificationReceivedCB() {

        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                _deliverNotificationToUser();
            }
        });
    }

    private void getDeviceToken(String action, JSONArray args, CallbackContext callbackContext) {
        final String deviceToken = ParseInstallation.getCurrentInstallation().getString("deviceToken");

        try {
            final JSONObject deviceInfo = new JSONObject();
            deviceInfo.put("getTokenCall", true);

            deviceInfo.put("deviceToken", deviceToken);

            Log.d("DEVICE_TOKEN", deviceToken);
            cordova.getActivity().runOnUiThread(new Runnable(){
                @Override
                public void run() {
                    _getDeviceToken(deviceInfo);
                }
            });
        } catch (JSONException e) {
            Log.d("DEBUG", e.toString());
        }
    }

    private void _getDeviceToken(JSONObject deviceInfo) {
        PluginResult pr = new PluginResult(PluginResult.Status.OK, deviceInfo);
        pr.setKeepCallback(true);

        callbackContextKeepCallback.sendPluginResult(pr);
    }

    private void subscribeToChannel(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        final String channel = args.getString(0);
        Log.d(LOG_TAG, String.format("%s", channel));

        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                _subscribeToChannel(channel);
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

    private void _setUp(String appId, String clientKey) {
        this.applicationId = appId;
        this.clientKey = clientKey;
        PluginResult pr;

       try {
           // In case it was initialized prior and not destroyed

            Parse.initialize(cordova.getActivity(), applicationId, clientKey);

            ParseInstallation.getCurrentInstallation().save();

            SharedPreferences sharedPref = cordova.getActivity().getSharedPreferences("cordova-plugin-pushnotification-parse", Context.MODE_PRIVATE);
            SharedPreferences.Editor editor = sharedPref.edit();
            editor.putString("applicationId", applicationId);
            editor.putString("clientKey", clientKey);
            editor.apply();

            pr = new PluginResult(PluginResult.Status.OK, "onRegisterAsPushNotificationClientSucceeded");

            pr.setKeepCallback(true);
            callbackContextKeepCallback.sendPluginResult(pr);
        }
        catch (ParseException e) {
            pr = new PluginResult(PluginResult.Status.ERROR, "onRegisterAsPushNotificationClientFailed");
            pr.setKeepCallback(true);
            callbackContextKeepCallback.sendPluginResult(pr);
        }
    }

    // Called when user clicks on a notification
    private void _deliverNotificationToUser() {
        if (notificationContextKeepCallback != null) {
            PluginResult pr = new PluginResult(PluginResult.Status.OK, receivedNotification);

            pr.setKeepCallback(true);
            notificationContextKeepCallback.sendPluginResult(pr);

            // Remove the read notification
            receivedNotification = null;
        }
        else {
            Log.e("NOTIFICATION ERROR", "notification Callback not available");
        }
    }

    private void _subscribeToChannel(String channel) {
        ParsePush.subscribeInBackground(channel, new SaveCallback() {
            @Override
            public void done(ParseException e) {
                if (e == null) {
                    PluginResult pr = new PluginResult(PluginResult.Status.OK, "onSubscribeToChannelSucceeded");
                    pr.setKeepCallback(true);
                    callbackContextKeepCallback.sendPluginResult(pr);
                }
                else {
                    PluginResult pr = new PluginResult(PluginResult.Status.ERROR, "onSubscribeToChannelFailed");
                    pr.setKeepCallback(true);
                    callbackContextKeepCallback.sendPluginResult(pr);
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
