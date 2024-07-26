package com.sodyo.RNSodyoSDK;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentTransaction;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;

import android.util.Log;
import android.widget.FrameLayout;

import com.sodyo.sdk.SodyoScannerFragment;

public class RNSodyoSdkView extends SimpleViewManager<FrameLayout> {
    private static final String TAG = "RNSodyoSdkView";
    private static final String TAG_FRAGMENT = "SODYO_SCANNER";
    public static final String REACT_CLASS = "RNSodyoSdkView";

    private final @Nullable ReactApplicationContext mCallerContext;
    private @Nullable SodyoScannerFragment sodyoFragment;
    private boolean isCameraEnabled = true;

    public RNSodyoSdkView(ReactApplicationContext callerContext) {
        mCallerContext = callerContext;
    }

    @NonNull
    @Override
    public String getName() {
        return REACT_CLASS;
    }

    @NonNull
    @Override
    public FrameLayout createViewInstance(@NonNull ThemedReactContext context) {
        Log.i(TAG, "createViewInstance");

        final FrameLayout view = new FrameLayout(context);

        FragmentActivity currentActivity = (FragmentActivity) mCallerContext.getCurrentActivity();
        if (currentActivity == null) {
            Log.e(TAG, "Current activity is null, cannot initialize SodyoScannerFragment");
            return view;
        }

        if (sodyoFragment == null) {
            Log.i(TAG, "init SodyoScannerFragment");
            sodyoFragment = new SodyoScannerFragment();
        }

        FragmentManager fragmentManager = currentActivity.getSupportFragmentManager();
        FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();

        fragmentTransaction.add(sodyoFragment, TAG_FRAGMENT).commitAllowingStateLoss();
        fragmentManager.executePendingTransactions();

        view.addView(sodyoFragment.getView(), new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));
        return view;
    }

    @Override
    public void onDropViewInstance(@NonNull FrameLayout view) {
        super.onDropViewInstance(view);

        Log.i(TAG, "onDropViewInstance");

        sodyoFragment = null;
        isCameraEnabled = true;

        try {
            FragmentActivity currentActivity = (FragmentActivity) mCallerContext.getCurrentActivity();
            if (currentActivity != null) {
                FragmentManager fragmentManager = currentActivity.getSupportFragmentManager();
                Fragment fragment = fragmentManager.findFragmentByTag(TAG_FRAGMENT);

                if (fragment != null) {
                    fragmentManager.beginTransaction().remove(fragment).commitAllowingStateLoss();
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Error dropping view instance", e);
        }
    }

    @ReactProp(name = "isEnabled", defaultBoolean = true)
    public void setIsEnabled(FrameLayout view, boolean isEnabled) {
        if (sodyoFragment == null) {
            return;
        }

        if (isEnabled && !isCameraEnabled) {
            Log.i(TAG, "start camera");
            isCameraEnabled = true;
            sodyoFragment.startCamera();
        }

        if (!isEnabled && isCameraEnabled) {
            Log.i(TAG, "stop camera");
            isCameraEnabled = false;
            sodyoFragment.stopCamera();
        }
    }
}
