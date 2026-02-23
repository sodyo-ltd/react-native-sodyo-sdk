# Android RNSodyoSdk Code Analysis

## Summary

Analysis of all Android source files in the `react-native-sodyo-sdk` bridge layer. Found **4 critical**, **5 major**, and **6 minor** issues across 4 Java files and `build.gradle`.

---

## Critical Issues

### 1. NullPointerException — `getCurrentActivity()` Used Without Null Check

**File:** `RNSodyoSdkModule.java:235-236, 242-243`

```java
// start()
Activity activity = getCurrentActivity();
activity.startActivityForResult(intent, SODYO_SCANNER_REQUEST_CODE);

// close()
Activity activity = getCurrentActivity();
activity.finishActivity(SODYO_SCANNER_REQUEST_CODE);
```

`getCurrentActivity()` returns `null` when the React Native host activity is not in the foreground (e.g., during transitions, after config changes, or when called too early). This crashes with `NullPointerException`.

The same pattern appears in `setTroubleshootMode()` (line 323), `setNormalMode()` (line 330), `startTroubleshoot()` (line 316), and `performMarker()` (line 309) — **6 call sites total**.

**Severity:** Critical — crash in production when activity is not available.

**Fix:** Add null checks to every call site:

```java
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
```

---

### 2. `IllegalArgumentException` Crash in `setEnv()` — No Validation

**File:** `RNSodyoSdkModule.java:350`

```java
String value = String.valueOf(SodyoEnv.valueOf(env.trim().toUpperCase()).getValue());
```

`Enum.valueOf()` throws `IllegalArgumentException` if the input string doesn't match any enum constant. Any JS call like `setEnv("staging")` crashes the app.

Additionally, if `env` is `null`, `env.trim()` throws `NullPointerException`.

**Severity:** Critical — crash from any unexpected JS input.

**Fix:**

```java
@ReactMethod
private void setEnv(String env) {
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
```

---

### 3. Fragment View is Null After `commitAllowingStateLoss`

**File:** `RNSodyoSdkView.java:67-70`

```java
fragmentTransaction.add(sodyoFragment, TAG_FRAGMENT).commitAllowingStateLoss();
fragmentManager.executePendingTransactions();
view.addView(sodyoFragment.getView(), ...);
```

The fragment is added **without a container ID** (headless fragment). After `commitAllowingStateLoss()` + `executePendingTransactions()`, the fragment's `onCreateView` may not have been called yet, so `sodyoFragment.getView()` can return `null`. Calling `addView(null, ...)` throws `IllegalArgumentException`.

Even if the view is non-null, because the fragment is headless (no container), the fragment lifecycle doesn't manage the view's attachment to the layout — leading to lifecycle mismatches.

**Severity:** Critical — crash or blank scanner view.

**Fix:** Add the fragment to the container by ID instead of headless:

```java
view.setId(View.generateViewId());
fragmentTransaction.add(view.getId(), sodyoFragment, TAG_FRAGMENT).commitAllowingStateLoss();
fragmentManager.executePendingTransactions();
// Fragment's view is now automatically placed inside `view`
```

---

### 4. ActivityEventListener Never Removed — Leak

**File:** `RNSodyoSdkModule.java:75`

```java
this.reactContext.addActivityEventListener(mActivityEventListener);
```

The listener is added in the constructor but never removed. The `RNSodyoSdkModule` holds a reference to `reactContext`, and `reactContext` holds a reference back via the listener — creating a mutual reference that prevents garbage collection of both.

**Severity:** Critical — memory leak of the entire module and React context on reload.

**Fix:** Override `onCatalystInstanceDestroy()`:

```java
@Override
public void onCatalystInstanceDestroy() {
    super.onCatalystInstanceDestroy();
    reactContext.removeActivityEventListener(mActivityEventListener);
}
```

---

## Major Issues

### 5. Deprecated `android.app.Fragment` API

**File:** `RNSodyoSdkView.java:11-12`

```java
import android.app.Fragment;
import android.app.FragmentManager;
```

`android.app.Fragment` was deprecated in API 28 and **removed in API 30+**. The `@SuppressWarnings("deprecation")` annotation hides the warning but doesn't fix the underlying compatibility issue. On newer devices, this code path may fail or behave unpredictably.

**Severity:** Major — forward-compatibility risk on newer Android versions.

**Fix:** Migrate to AndroidX `androidx.fragment.app.Fragment` and `FragmentManager`. This requires the host app to use `AppCompatActivity`/`FragmentActivity` (standard in modern RN apps):

```java
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
// ...
FragmentManager fragmentManager = ((FragmentActivity) currentActivity).getSupportFragmentManager();
```

---

### 6. `Sodyo.getInstance()` Called Without Initialization Guard

**File:** `RNSodyoSdkModule.java:109-111`

```java
Sodyo.getInstance().setSodyoScannerCallback(callbackClosure);
Sodyo.getInstance().setSodyoMarkerContentCallback(callbackClosure);
Sodyo.getInstance().setSodyoModeCallback(callbackClosure);
```

These are called inside `onSodyoAppLoadSuccess`, which is safe. However, `setUserInfo()` at line 251 also calls `Sodyo.getInstance()`. If the JS side calls `setUserInfo` before `init` completes, `getInstance()` may return `null` or throw.

**Severity:** Major — crash if methods called before initialization.

**Fix:** Add initialization guard:

```java
@ReactMethod
public void setUserInfo(ReadableMap userInfo) {
    if (!Sodyo.isInitialized()) {
        Log.w(TAG, "setUserInfo: SDK not initialized yet");
        return;
    }
    if (userInfo != null) {
        Sodyo.getInstance().setUserInfo(ConversionUtil.toMap(userInfo));
    }
}
```

---

### 7. `init()` Silently Ignores Re-initialization Callbacks

**File:** `RNSodyoSdkModule.java:212-215`

```java
if (Sodyo.isInitialized()) {
    Log.i(TAG, "init(): already initialized, ignore");
    return;  // callbacks never invoked
}
```

If the SDK is already initialized, the success/error callbacks passed from JS are silently dropped. The JS `Promise` or callback will never resolve, potentially leaving the app in a waiting state.

**Severity:** Major — JS side hangs waiting for callback that never fires.

**Fix:** Invoke the success callback immediately if already initialized:

```java
if (Sodyo.isInitialized()) {
    Log.i(TAG, "init(): already initialized");
    if (successCallback != null) {
        successCallback.invoke();
    }
    return;
}
```

---

### 8. Nested Array Overwrites Parent List in `ConversionUtil.toList()`

**File:** `ConversionUtil.java:160`

```java
case Array:
    result = toList(readableArray.getArray(index));  // overwrites entire result!
    break;
```

When a nested array is encountered, the **entire `result` list** is replaced with the nested array contents. All previously accumulated items are lost.

**Severity:** Major — data corruption for any array containing nested arrays.

**Fix:**

```java
case Array:
    result.add(toList(readableArray.getArray(index)));
    break;
```

---

### 9. Null Converted to Key/Index String in ConversionUtil

**File:** `ConversionUtil.java:43, 139`

```java
// toObject()
case Null:
    result = key;  // returns the key name as the value
    break;

// toList()
case Null:
    result.add(String.valueOf(index));  // returns "0", "1", etc.
    break;
```

When a `null` value is encountered, instead of returning `null`, it returns the key name or the string index. This silently corrupts data — a map `{name: null}` becomes `{name: "name"}`.

**Severity:** Major — silent data corruption.

**Fix:**

```java
case Null:
    result = null;
    break;

// and in toList:
case Null:
    result.add(null);
    break;
```

---

## Minor Issues

### 10. `@ReactMethod` on `private` Method

**File:** `RNSodyoSdkModule.java:346`

```java
@ReactMethod
private void setEnv(String env) {
```

`@ReactMethod` requires methods to be `public`. While this may work in some React Native versions due to reflection, it violates the contract and may break in future RN versions or with ProGuard/R8 optimization.

**Severity:** Minor — may break silently with build optimizations.

**Fix:** Change to `public`.

---

### 11. `SodyoEnv` Enum Values Appear Swapped

**File:** `RNSodyoSdkModule.java:39-41`

```java
public static enum SodyoEnv {
    DEV(3),
    QA(0),   // QA = 0?
    PROD(1); // PROD = 1?
}
```

Compare to the iOS side (`RNSodyoSdk.m:138`):

```objc
NSDictionary *envs = @{ @"DEV": @"3", @"QA": @"1", @"PROD": @"0" };
```

The values are **different across platforms**:
- iOS: DEV=3, QA=1, PROD=0
- Android: DEV=3, QA=0, PROD=1

This means the same JS call produces different server environments on iOS vs Android.

**Severity:** Minor (but potentially dangerous) — platform behavior inconsistency.

**Fix:** Align values across platforms. Determine the correct mapping from the Sodyo SDK documentation and make both platforms match.

---

### 12. `sendEvent()` Called Without Listener Check

**File:** `RNSodyoSdkModule.java:356-360`

```java
private void sendEvent(String eventName, @Nullable WritableMap params) {
    this.reactContext
        .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
        .emit(eventName, params);
}
```

If the JS module is not loaded yet or the Catalyst instance is destroyed, `getJSModule()` can throw. Events sent during module teardown will crash.

**Severity:** Minor — crash during shutdown/hot reload.

**Fix:**

```java
private void sendEvent(String eventName, @Nullable WritableMap params) {
    if (!reactContext.hasActiveReactInstance()) {
        return;
    }
    reactContext
        .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
        .emit(eventName, params);
}
```

---

### 13. Excessive `Log.i()` in Production

**File:** All Java files.

Every method logs with `Log.i(TAG, ...)`. Android `Log.i` is visible in production logcat and adds overhead.

**Severity:** Minor — performance and information disclosure.

**Fix:** Use `BuildConfig.DEBUG` guard or use `Log.d()` instead:

```java
if (BuildConfig.DEBUG) {
    Log.d(TAG, "start()");
}
```

---

### 14. Outdated `build.gradle` Configuration

**File:** `build.gradle`

```groovy
def DEFAULT_COMPILE_SDK_VERSION = 24       // Android 7.0 — from 2016
def DEFAULT_BUILD_TOOLS_VERSION = "25.0.2" // 2017 vintage
def DEFAULT_TARGET_SDK_VERSION  = 22       // Android 5.1
classpath 'com.android.tools.build:gradle:1.3.1'  // Gradle plugin from 2015
```

- `compileSdkVersion 24` — misses 8 years of API improvements
- `targetSdkVersion 22` — Google Play requires minimum 33+ as of 2024
- `jcenter()` — shut down, only serves cached artifacts
- `gradle:1.3.1` — ancient plugin, incompatible with modern AGP

These defaults are overridden by the host app in most cases, but they cause issues if the host doesn't specify them.

**Severity:** Minor (defaults only) — but causes confusion and build issues.

**Fix:** Update defaults to modern values:

```groovy
def DEFAULT_COMPILE_SDK_VERSION = 34
def DEFAULT_TARGET_SDK_VERSION  = 34
```

Remove `jcenter()` and the `classpath` line (host app provides the plugin).

---

### 15. `toFlatMap()` Assumes All Values Are Strings

**File:** `ConversionUtil.java:117`

```java
result.put(key, readableMap.getString(key));
```

If the map contains non-string values (numbers, booleans), `getString()` throws `ClassCastException` or returns unexpected results.

**Severity:** Minor — crash if non-string values passed to `setScannerParams`.

**Fix:** Convert all values to strings:

```java
ReadableType type = readableMap.getType(key);
switch (type) {
    case String:  result.put(key, readableMap.getString(key)); break;
    case Number:  result.put(key, String.valueOf(readableMap.getDouble(key))); break;
    case Boolean: result.put(key, String.valueOf(readableMap.getBoolean(key))); break;
    default:      result.put(key, String.valueOf(toObject(readableMap, key))); break;
}
```

---

## Cross-Platform Inconsistencies

| Feature | iOS | Android | Issue |
|---------|-----|---------|-------|
| `init` re-call | Overwrites callbacks silently | Silently drops callbacks | Both broken, differently |

---

## Issue Summary Table

| # | Severity | File | Line(s) | Issue |
|---|----------|------|---------|-------|
| 1 | Critical | RNSodyoSdkModule.java | 235,242,309,316,323,330 | Null activity — NPE crash |
| 2 | Critical | RNSodyoSdkModule.java | 350 | `valueOf()` crash on invalid env |
| 3 | Critical | RNSodyoSdkView.java | 67-70 | Fragment view null — crash |
| 4 | Critical | RNSodyoSdkModule.java | 75 | ActivityEventListener never removed — leak |
| 5 | Major | RNSodyoSdkView.java | 11-12 | Deprecated `android.app.Fragment` |
| 6 | Major | RNSodyoSdkModule.java | 251 | `getInstance()` before init — NPE |
| 7 | Major | RNSodyoSdkModule.java | 212-215 | Re-init silently drops callbacks |
| 8 | Major | ConversionUtil.java | 160 | Nested array overwrites parent list |
| 9 | Major | ConversionUtil.java | 43,139 | Null → key/index string — data corruption |
| 10 | Minor | RNSodyoSdkModule.java | 346 | `@ReactMethod` on private method |
| 11 | Minor | RNSodyoSdkModule.java | 39-41 | Env enum values differ from iOS |
| 12 | Minor | RNSodyoSdkModule.java | 356 | `sendEvent` without active instance check |
| 13 | Minor | All files | — | Excessive `Log.i()` in production |
| 14 | Minor | build.gradle | 3-6,15 | Outdated SDK/plugin defaults |
| 15 | Minor | ConversionUtil.java | 117 | `toFlatMap` assumes all values are strings |
