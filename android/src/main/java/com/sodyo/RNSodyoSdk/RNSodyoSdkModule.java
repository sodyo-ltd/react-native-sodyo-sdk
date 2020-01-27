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
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.graphics.Color;

import org.json.JSONObject;

import com.sodyo.sdk.Sodyo;
import com.sodyo.sdk.SodyoInitCallback;
import com.sodyo.sdk.SodyoScannerActivity;
import com.sodyo.sdk.SodyoScannerCallback;
import com.sodyo.sdk.SodyoMarkerContentCallback;

public class RNSodyoSdkModule extends ReactContextBaseJavaModule {
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

  @Override
  public String getName() {
    return "RNSodyoSdk";
  }

  private class SodyoCallback implements SodyoScannerCallback, SodyoInitCallback, SodyoMarkerContentCallback {

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
  }

  @ReactMethod
  public void init(final String apiKey, Callback successCallback, Callback errorCallback) {
      Log.i(TAG, "init()");

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

  @ReactMethod
  public void start() {
      Log.i(TAG, "start()");
      Intent intent = new Intent(this.reactContext, SodyoScannerActivity.class);
      Activity activity = getCurrentActivity();
      activity.startActivityForResult(intent, SODYO_SCANNER_REQUEST_CODE);
  }

  @ReactMethod
  public void close() {
      Log.i(TAG, "close()");
      Activity activity = getCurrentActivity();
      activity.finishActivity(SODYO_SCANNER_REQUEST_CODE);
  }

  @ReactMethod
  public void setUserInfo(ReadableMap userInfo) {
      Log.i(TAG, "setUserInfo()");

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
      Sodyo.setScannerParams(ConversionUtil.toMap(scannerPreferences));
  }

  @ReactMethod
  public void setOverlayView(final String html) {
      Log.i(TAG, "setOverlayView()");

      UiThreadUtil.runOnUiThread(new Runnable() {
          @Override
          public void run() {
              WebView webView = new WebView(reactContext);
              webView.loadDataWithBaseURL("", html, "text/html", "UTF-8", "");
              webView.setBackgroundColor(Color.TRANSPARENT);
              webView.setWebViewClient(new WebViewClient() {
                  @Override
                  public boolean shouldOverrideUrlLoading(WebView view, String url) {
                      String[] parsedUrl = url.split("sodyosdk://");

                      if (parsedUrl.length >= 2) {
                          callOverlayCallback(parsedUrl[1]);
                      }

                      return true;
                  }
              });
              Sodyo.setOverlayView(webView);
          }
      });
  }

  @ReactMethod
  public void performMarker(String markerId) {
      Log.i(TAG, "performMarker()");
      Activity activity = getCurrentActivity();
      Sodyo.performMarker(markerId, activity);
  }

  @ReactMethod
  public void setSodyoLogoVisible(Boolean isVisible) {
    Log.i(TAG, "setSodyoLogoVisible()");
    Sodyo.setSodyoLogoVisible(isVisible);
  }

  private void callOverlayCallback(String callbackName) {
      Log.i(TAG, "callOverlayCallback()");

      WritableMap params = Arguments.createMap();
      params.putString("callback", callbackName);
      this.sendEvent("EventWebViewCallback", params);
  }

  private void sendEvent(String eventName, @Nullable WritableMap params) {
    this.reactContext
        .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
        .emit(eventName, params);
  }
}
