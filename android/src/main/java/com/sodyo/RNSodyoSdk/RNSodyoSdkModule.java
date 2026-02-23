package com.sodyo.RNSodyoSDK;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.BaseActivityEventListener;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.bridge.UiThreadUtil;

import java.util.HashMap;
import java.util.Map;

import javax.annotation.Nullable;

import android.util.Log;
import android.content.Intent;
import android.app.Application;
import android.app.Activity;
import android.graphics.Color;

import org.json.JSONObject;

import com.sodyo.sdk.Sodyo;
import com.sodyo.sdk.SodyoInitCallback;
import com.sodyo.sdk.SodyoScannerActivity;
import com.sodyo.sdk.SodyoScannerCallback;
import com.sodyo.sdk.SodyoMarkerContentCallback;
import com.sodyo.sdk.SodyoModeCallback;
import com.sodyo.app_sdk.data.SettingsHelper;

public class RNSodyoSdkModule extends ReactContextBaseJavaModule {
  public static enum SodyoEnv {
    DEV(3),
    QA(0),
    PROD(1);

    private int value;

    private SodyoEnv(int value) {
      this.value = value;
    }

    public int getValue() {
      return value;
    }
  }

  private static final int SODYO_SCANNER_REQUEST_CODE = 2222;

  private static final String TAG = "SodyoSDK";

  private final ReactApplicationContext reactContext;

  private final ActivityEventListener mActivityEventListener = new BaseActivityEventListener() {

    @Override
    public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent intent) {
      Log.i(TAG, "onActivityResult()");

      if (requestCode == SODYO_SCANNER_REQUEST_CODE) {
        sendEvent("EventCloseSodyoScanner", null);
      }
    }
  };

  public RNSodyoSdkModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
    this.reactContext.addActivityEventListener(mActivityEventListener);
  }

  // Issue #4 fix: remove listener on destroy to prevent leak
  @Override
  public void onCatalystInstanceDestroy() {
    super.onCatalystInstanceDestroy();
    reactContext.removeActivityEventListener(mActivityEventListener);
  }

  @Override
  public String getName() {
    return "RNSodyoSdk";
  }

  private class SodyoCallback implements SodyoScannerCallback, SodyoInitCallback, SodyoMarkerContentCallback, SodyoModeCallback {

      private Callback successCallback;
      private Callback errorCallback;
      private boolean isCallbackUsed;

      public SodyoCallback(Callback successCallback, Callback errorCallback) {
          this.successCallback = successCallback;
          this.errorCallback = errorCallback;
      }

      /**
       * SodyoInitCallback implementation
       */
      public void onSodyoAppLoadSuccess() {
          String message = "onSodyoAppLoadSuccess";
          Log.i(TAG, message);

          if (this.successCallback == null || this.isCallbackUsed) {
            return;
          }

          this.successCallback.invoke();
          this.isCallbackUsed = true;

          SodyoCallback callbackClosure = new SodyoCallback(null, null);
          Sodyo.getInstance().setSodyoScannerCallback(callbackClosure);
          Sodyo.getInstance().setSodyoMarkerContentCallback(callbackClosure);
          Sodyo.getInstance().setSodyoModeCallback(callbackClosure);
      }

      /**
       * SodyoInitCallback implementation
       */
      public void onSodyoAppLoadFailed(String error) {
          String message = "onSodyoAppLoadFailed. Error=\"" + error + "\"";
          Log.e(TAG, message);

          if (this.errorCallback == null || this.isCallbackUsed) {
            return;
          }

          this.errorCallback.invoke(error);
          this.isCallbackUsed = true;
      }

      public void permissionError(String err1, String err2) {
      }

      /**
       * SodyoInitCallback implementation
       */
      @Override
      public void sodyoError(Error err) {
          String message = "sodyoError. Error=\"" + err + "\"";
          Log.e(TAG, message);

          WritableMap params = Arguments.createMap();
          params.putString("error", err.getMessage());
          sendEvent("EventSodyoError", params);
      }

      /**
       * SodyoScannerCallback implementation
       */
      @Override
      public void onMarkerDetect(String markerType, String data, String error) {
          Log.i(TAG, "onMarkerDetect()");

          if (data == null) {
              data = "null";
          }

          String message;

          if (error == null) {
              message = "SodyoScannerCallback.onMarkerDetect  data=\"" + data + "\"";
              Log.i(TAG, message);
              WritableMap params = Arguments.createMap();
              params.putString("data", data);
              sendEvent("EventMarkerDetectSuccess", params);
          } else {
              message = "SodyoScannerCallback.onMarkerDetect  data=\"" + data + "\" error=\"" + error + "\"";
              Log.e(TAG, message);
              WritableMap params = Arguments.createMap();
              params.putString("error", error);
              sendEvent("EventMarkerDetectError", params);
          }
      }

      /**
       * SodyoMarkerContentCallback implementation
       */
      @Override
      public void onMarkerContent(String markerId, JSONObject data) {
        Log.i(TAG, "onMarkerContent()");

        WritableMap params = Arguments.createMap();
        params.putString("markerId", markerId);

        if (data == null) {
          params.putString("data", "{}");
        } else {
          params.putString("data", data.toString());
        }

        sendEvent("EventMarkerContent", params);
      }

      /**
       * SodyoModeCallback implementation
       */
      @Override
      public void onModeChange(SettingsHelper.ScannerViewMode oldMode, SettingsHelper.ScannerViewMode newMode) {
        Log.i(TAG, "onModeChange()");

        WritableMap params = Arguments.createMap();

        params.putString("oldMode", oldMode.toString());
        params.putString("newMode", newMode.toString());

        sendEvent("ModeChangeCallback", params);
      }
  }

  // Issue #7 fix: invoke success callback if already initialized
  @ReactMethod
  public void init(final String apiKey, Callback successCallback, Callback errorCallback) {
      Log.i(TAG, "init()");

      if (Sodyo.isInitialized()) {
          Log.i(TAG, "init(): already initialized");
          if (successCallback != null) {
              successCallback.invoke();
          }
          return;
      }

      final SodyoCallback callbackClosure = new SodyoCallback(successCallback, errorCallback);

      UiThreadUtil.runOnUiThread(new Runnable() {
          @Override
          public void run() {
              Sodyo.init(
                      (Application) reactContext.getApplicationContext(),
                      apiKey,
                      callbackClosure
              );
          }
      });
  }

  // Issue #1 fix: null-check getCurrentActivity()
  @ReactMethod
  public void start() {
      Log.i(TAG, "start()");
      Activity activity = getCurrentActivity();
      if (activity == null) {
          Log.e(TAG, "start(): current activity is null");
          return;
      }
      Intent intent = new Intent(activity, SodyoScannerActivity.class);
      activity.startActivityForResult(intent, SODYO_SCANNER_REQUEST_CODE);
  }

  @ReactMethod
  public void close() {
      Log.i(TAG, "close()");
      Activity activity = getCurrentActivity();
      if (activity == null) {
          Log.e(TAG, "close(): current activity is null");
          return;
      }
      activity.finishActivity(SODYO_SCANNER_REQUEST_CODE);
  }

  // Issue #6 fix: guard against uninitialized SDK
  @ReactMethod
  public void setUserInfo(ReadableMap userInfo) {
      Log.i(TAG, "setUserInfo()");

      if (!Sodyo.isInitialized()) {
          Log.w(TAG, "setUserInfo(): SDK not initialized yet");
          return;
      }

      if(userInfo != null) {
        Sodyo.getInstance().setUserInfo(ConversionUtil.toMap(userInfo));
      }
  }

  @ReactMethod
  public void setCustomAdLabel(String label) {
      Log.i(TAG, "setCustomAdLabel()");
      Sodyo.setCustomAdLabel(label);
  }

  @ReactMethod
  public void setAppUserId(String userId) {
      Log.i(TAG, "setAppUserId()");
      Sodyo.setAppUserId(userId);
  }

  @ReactMethod
  public void setScannerParams(ReadableMap scannerPreferences) {
      Log.i(TAG, "setScannerParams()");
      Sodyo.setScannerParams(ConversionUtil.toFlatMap(scannerPreferences));
  }

  @ReactMethod
  public void addScannerParam(String key, String value) {
      Log.i(TAG, "addScannerParam()");
      Sodyo.addScannerParams(key, value);
  }

  @ReactMethod
  public void startScanning() {
      Log.i(TAG, "startScanning()");
      Sodyo.startScanning();
  }

  @ReactMethod
  public void stopScanning() {
      Log.i(TAG, "stopScanning()");
      Sodyo.stopScanning();
  }

  @ReactMethod
  public void setDynamicProfile(ReadableMap profile) {
    Log.i(TAG, "setDynamicProfile()");
    if (profile != null) {
        HashMap<String, Object> profileMap = new HashMap<>(ConversionUtil.toMap(profile));
        Sodyo.setDynamicProfile(profileMap);
    }
  }

  @ReactMethod
  public void setDynamicProfileValue(String key, String value) {
     Log.i(TAG, "setDynamicProfileValue()");
     Sodyo.setDynamicProfileValue(key, value);
  }

  @ReactMethod
  public void performMarker(String markerId, ReadableMap customProperties) {
      Log.i(TAG, "performMarker()");
      Activity activity = getCurrentActivity();
      if (activity == null) {
          Log.e(TAG, "performMarker(): current activity is null");
          return;
      }
      Sodyo.performMarker(markerId, activity, ConversionUtil.toMap(customProperties));
  }

  @ReactMethod
  public void startTroubleshoot() {
      Log.i(TAG, "startTroubleshoot()");
      Activity activity = getCurrentActivity();
      if (activity == null) {
          Log.e(TAG, "startTroubleshoot(): current activity is null");
          return;
      }
      Sodyo.startTroubleshoot(activity);
  }

  @ReactMethod
  public void setTroubleshootMode() {
      Log.i(TAG, "setTroubleshootMode()");
      Activity activity = getCurrentActivity();
      if (activity == null) {
          Log.e(TAG, "setTroubleshootMode(): current activity is null");
          return;
      }
      Sodyo.setMode(activity, SettingsHelper.ScannerViewMode.Troubleshoot);
  }

  @ReactMethod
  public void setNormalMode() {
      Log.i(TAG, "setNormalMode()");
      Activity activity = getCurrentActivity();
      if (activity == null) {
          Log.e(TAG, "setNormalMode(): current activity is null");
          return;
      }
      Sodyo.setMode(activity, SettingsHelper.ScannerViewMode.Normal);
  }

  @ReactMethod(isBlockingSynchronousMethod = true)
  public String getMode() {
    return Sodyo.getMode().name();
  }

  @ReactMethod
  public void setSodyoLogoVisible(Boolean isVisible) {
    Log.i(TAG, "setSodyoLogoVisible()");
    Sodyo.setSodyoLogoVisible(isVisible);
  }

  // Issue #2 fix: validate env input, Issue #10 fix: public instead of private
  @ReactMethod
  public void setEnv(String env) {
      Log.i(TAG, "setEnv:" + env);

      if (env == null) {
          Log.e(TAG, "setEnv: env is null");
          return;
      }

      try {
          SodyoEnv sodyoEnv = SodyoEnv.valueOf(env.trim().toUpperCase());
          Map<String, String> params = new HashMap<>();
          params.put("webad_env", String.valueOf(sodyoEnv.getValue()));
          params.put("scanner_QR_code_enabled", "false");
          Sodyo.setScannerParams(params);
      } catch (IllegalArgumentException e) {
          Log.e(TAG, "setEnv: unknown env '" + env + "', expected DEV/QA/PROD");
      }
  }

  // Issue #12 fix: check for active React instance before sending events
  private void sendEvent(String eventName, @Nullable WritableMap params) {
    if (!reactContext.hasActiveReactInstance()) {
        return;
    }
    reactContext
        .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
        .emit(eventName, params);
  }
}