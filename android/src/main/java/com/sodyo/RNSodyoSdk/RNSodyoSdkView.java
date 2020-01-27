
package com.sodyo.RNSodyoSDK;

import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.annotations.ReactProp;

import android.util.Log;
import android.widget.FrameLayout;
import android.app.Fragment;
import android.app.FragmentManager;
import android.app.FragmentTransaction;
import javax.annotation.Nullable;

import com.sodyo.sdk.SodyoScannerFragment;

public class RNSodyoSdkView extends SimpleViewManager<FrameLayout> {
    static final String TAG = "RNSodyoSdkView";

    static final String TAG_FRAGMENT = "SODYO_SCANNER";

    public static final String REACT_CLASS = "RNSodyoSdkView";

    private final @Nullable ReactApplicationContext mCallerContext;

    private @Nullable SodyoScannerFragment sodyoFragment;

    private boolean isCameraEnabled = true;

    @Override
    public String getName() {
        return REACT_CLASS;
    }

    public RNSodyoSdkView(ReactApplicationContext callerContext) {
        mCallerContext = callerContext;
    }

    @Override
    public FrameLayout createViewInstance(ThemedReactContext context) {
        Log.i(TAG,"createViewInstance");

        final FrameLayout view = new FrameLayout(context);

        if (sodyoFragment == null) {
          Log.i(TAG,"init SodyoScannerFragment");
          sodyoFragment = new SodyoScannerFragment();
        }

        FragmentManager fragmentManager = mCallerContext.getCurrentActivity().getFragmentManager();
        FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();

        fragmentTransaction.add(sodyoFragment, TAG_FRAGMENT).commit();

        fragmentManager.executePendingTransactions();

        view.addView(sodyoFragment.getView(), FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT);
        return view;
    }

    @Override
    public void onDropViewInstance(FrameLayout view) {
        super.onDropViewInstance(view);

        Log.i(TAG,"onDropViewInstance");

        sodyoFragment = null;
        isCameraEnabled = true;

        try {
          FragmentManager fragmentManager = mCallerContext.getCurrentActivity().getFragmentManager();
          Fragment fragment = fragmentManager.findFragmentByTag(TAG_FRAGMENT);

          if (fragment != null) {
              fragmentManager.beginTransaction().remove(fragment).commit();
          }
        } catch (Exception e) {
          e.printStackTrace();
        }
    }

    @ReactProp(name = "isEnabled", defaultBoolean=true)
    public void setIsEnabled(FrameLayout view, boolean isEnabled) {
      if (sodyoFragment == null) {
        return;
      }

      if (isEnabled && !isCameraEnabled) {
        Log.i(TAG,"start camera");
        isCameraEnabled = true;
        sodyoFragment.startCamera();
      }

      if (!isEnabled && isCameraEnabled) {
        Log.i(TAG,"stop camera");
        isCameraEnabled = false;
        sodyoFragment.stopCamera();
      }
    }
}
