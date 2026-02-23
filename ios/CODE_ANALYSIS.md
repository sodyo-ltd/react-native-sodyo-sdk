# iOS RNSodyoSdk Code Analysis

## Summary

Analysis of all iOS source files in the `react-native-sodyo-sdk` bridge layer. Found **5 critical**, **4 major**, and **5 minor** issues across 6 files.

---

## Critical Issues

### 1. Static Variable in Header File — Duplicate Symbol / Undefined Behavior

**File:** `RNSodyoScanner.h:14`

```objc
static UIViewController* sodyoScanner = nil;
```

A `static` variable in a header creates a **separate copy** in every `.m` file that imports it. `RNSodyoSdk.m`, `RNSodyoSdkManager.m`, and `RNSodyoScanner.m` each get their own independent `sodyoScanner`. This means:

- `RNSodyoSdkManager` sets `sodyoScanner` via `[RNSodyoScanner setSodyoScanner:]`, but that only updates the copy inside `RNSodyoScanner.m`.
- `RNSodyoSdk.m` reads its **own local copy** (`sodyoScanner`) which is always `nil` unless assigned directly in that file.
- `startTroubleshoot` at line 104 uses the local `sodyoScanner` which may be `nil`, causing a silent no-op or crash.

**Severity:** Critical — scanner functionality silently broken across modules.

**Fix:** Remove the `static` variable from the header. Use the `RNSodyoScanner` class methods exclusively:

```objc
// RNSodyoScanner.h — remove line 14 entirely
// RNSodyoScanner.m — store the scanner as a class-level static
static UIViewController* _sharedScanner = nil;

@implementation RNSodyoScanner
+ (UIViewController *)getSodyoScanner { return _sharedScanner; }
+ (void)setSodyoScanner:(UIViewController *)scanner { _sharedScanner = scanner; }
@end
```

Then in `RNSodyoSdk.m`, replace all bare `sodyoScanner` references with `[RNSodyoScanner getSodyoScanner]`.

---

### 2. Inverted Null-Check Logic — Scanner Never Saved

**File:** `RNSodyoSdk.m:153-155`

```objc
if (!sodyoScanner) {
    [RNSodyoScanner setSodyoScanner:sodyoScanner]; // saves nil
}
```

This is inverted. It saves the scanner only when it's `nil`, which stores `nil` into the shared singleton. When `sodyoScanner` is non-nil, it's never persisted.

**Severity:** Critical — the scanner reference is never properly shared.

**Fix:**

```objc
if (sodyoScanner) {
    [RNSodyoScanner setSodyoScanner:sodyoScanner];
}
```

Or better, always assign and let the setter handle dedup (it already does).

---

### 3. `BOOL *` (Pointer) Instead of `BOOL` — Always Truthy

**File:** `RNSodyoSdk.m:124`

```objc
RCT_EXPORT_METHOD(setSodyoLogoVisible:(BOOL *) isVisible)
```

`BOOL *` is a pointer-to-BOOL, not a BOOL. React Native will pass a non-null pointer, so the `if (isVisible)` check at line 127 always evaluates to `true` (non-null pointer), making `hideDefaultOverlay` unreachable.

**Severity:** Critical — logo can never be hidden from JS.

**Fix:**

```objc
RCT_EXPORT_METHOD(setSodyoLogoVisible:(BOOL) isVisible)
```

---

### 4. NSNotificationCenter Observer Never Removed — Memory Leak

**File:** `RNSodyoSdk.m:35`

```objc
[[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(sendCloseContentEvent)
    name:@"SodyoNotificationCloseIAD" object:nil];
```

The observer is added but never removed. Since `NSNotificationCenter` holds an **unsafe unretained reference** (pre-iOS 9 behavior on block-based API, and always for selector-based), this can:

- Cause **crashes** if the module is deallocated while notifications fire.
- Cause **duplicate event delivery** if `createCloseContentListener` semantics change.

**Severity:** Critical — potential crash on deallocation.

**Fix:** Add a `dealloc` method:

```objc
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
```

---

### 5. Callback Retain Cycle — Blocks Held Indefinitely

**File:** `RNSodyoSdk.m:21-22`, `RNSodyoSdk.h:22-23`

```objc
@property (nonatomic, strong) RCTResponseSenderBlock successStartCallback;
@property (nonatomic, strong) RCTResponseSenderBlock errorStartCallback;
```

These blocks are stored as `strong` properties. If `onSodyoAppLoadSuccess` is called, `errorStartCallback` is **never nilled out** (and vice versa). The unused callback retains captured JS context forever.

Additionally, if `init:` is called multiple times, the previous callbacks are silently overwritten and leaked.

**Severity:** Critical — memory leak of JS bridge context.

**Fix:** Nil both callbacks after either fires:

```objc
- (void)onSodyoAppLoadSuccess:(NSInteger)AppID {
    if (self.successStartCallback) {
        self.successStartCallback(@[[NSNull null]]);
    }
    self.successStartCallback = nil;
    self.errorStartCallback = nil;  // release the other one too
}

- (void)onSodyoAppLoadFailed:(NSInteger)AppID error:(NSError *)error {
    if (self.errorStartCallback) {
        self.errorStartCallback(@[@{@"error": error.localizedDescription ?: @"Unknown error"}]);
    }
    self.successStartCallback = nil;  // release the other one too
    self.errorStartCallback = nil;
}
```

---

## Major Issues

### 6. NSError Passed Directly to JS — Crash Risk

**File:** `RNSodyoSdk.m:203`

```objc
self.errorStartCallback(@[@{@"error": error}]);
```

`NSError` is not JSON-serializable. React Native's bridge expects serializable types. This will throw an exception or produce undefined behavior.

**Severity:** Major — crash when SDK load fails.

**Fix:**

```objc
NSString *message = error.localizedDescription ?: @"Unknown error";
self.errorStartCallback(@[@{@"error": message}]);
```

---

### 7. Nil Dictionary Value Crash in `sodyoError:`

**File:** `RNSodyoSdk.m:211`

```objc
NSArray* params = @[@"sodyoError", error.userInfo[@"NSLocalizedDescription"]];
[self sendEventWithName:@"EventSodyoError" body:@{@"error": params[1]}];
```

If `error.userInfo[@"NSLocalizedDescription"]` is `nil`, creating the `NSArray` literal crashes with `NSInvalidArgumentException` (nil inserted into immutable array).

**Severity:** Major — crash on certain error types.

**Fix:**

```objc
NSString *desc = error.localizedDescription ?: @"Unknown error";
[self sendEventWithName:@"EventSodyoError" body:@{@"error": desc}];
```

---

### 8. Nil Dictionary Value Crash in `setEnv:`

**File:** `RNSodyoSdk.m:138-139`

```objc
NSDictionary *envs = @{ @"DEV": @"3", @"QA": @"1", @"PROD": @"0" };
NSDictionary *params = @{ @"SodyoAdEnv" : envs[env], @"ScanQR": @"false" };
```

If `env` is not one of `DEV`, `QA`, `PROD`, then `envs[env]` returns `nil`. Inserting `nil` into an `NSDictionary` literal crashes.

**Severity:** Major — crash on invalid env string from JS.

**Fix:**

```objc
NSString *envValue = envs[env];
if (!envValue) {
    NSLog(@"RNSodyoSdk: Unknown env '%@', defaulting to PROD", env);
    envValue = @"0";
}
NSDictionary *params = @{ @"SodyoAdEnv": envValue, @"ScanQR": @"false" };
```

---

### 9. Nil Value Crash in `SodyoMarkerDetectedWithData:`

**File:** `RNSodyoSdk.m:218`

```objc
[self sendEventWithName:@"EventMarkerDetectSuccess" body:@{@"data": Data[@"sodyoMarkerData"]}];
```

If `Data` is `nil` or `Data[@"sodyoMarkerData"]` is `nil`, creating the dictionary literal crashes.

**Severity:** Major — crash when marker data is missing.

**Fix:**

```objc
id markerData = Data[@"sodyoMarkerData"] ?: [NSNull null];
[self sendEventWithName:@"EventMarkerDetectSuccess" body:@{@"data": markerData}];
```

Apply the same pattern to `SodyoMarkerContent:Data:` at line 223.

---

## Minor Issues

### 10. Method Named `init:` Shadows NSObject

**File:** `RNSodyoSdk.m:14`

```objc
RCT_EXPORT_METHOD(init:(NSString *)apiKey ...)
```

While RCT_EXPORT_METHOD creates a different Objective-C selector internally, naming the JS method `init` is confusing and risks future collision with `NSObject`'s `init` family. Static analyzers may flag this.

**Fix:** Rename to `initialize:` or `setup:` on the native side, or document the JS-side name mapping.

---

### 11. Deprecated `window` Access Pattern

**File:** `RNSodyoSdk.m:95,162,170` and `RNSodyoSdkManager.m:63`

```objc
UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
```

`UIApplicationDelegate.window` is deprecated in iOS 15+ with UIScene. On apps using scenes, this returns `nil`, breaking all scanner presentation.

**Fix:** Use the key window from connected scenes:

```objc
UIWindow *keyWindow = nil;
for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
    if (scene.activationState == UISceneActivationStateForegroundActive) {
        for (UIWindow *window in scene.windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }
    }
}
UIViewController *rootViewController = keyWindow.rootViewController;
```

---

### 12. Child View Controller Not Removed on Cleanup

**File:** `RNSodyoSdkManager.m:68`

```objc
[rootViewController addChildViewController:sodyoScanner];
```

The scanner is added as a child view controller but never removed via `removeFromParentViewController` when the React view is unmounted. This leaks the child VC relationship.

**Fix:** Override cleanup in `RNSodyoSdkView` or the manager to call `[sodyoScanner removeFromParentViewController]`.

---

### 13. `isTroubleShootingEnabled` Has No `false` Handler

**File:** `RNSodyoSdkManager.m:45-59`

```objc
if ([RCTConvert BOOL:json]) {
    [SodyoSDK startTroubleshoot:sodyoScanner];
    return;
}
// nothing happens when false
```

Setting `isTroubleShootingEnabled={false}` is a no-op. There's no call to stop troubleshooting.

**Fix:** Add the false branch, e.g., `[SodyoSDK setMode:sodyoScanner mode:SodyoModeNormal]`.

---

### 14. Excessive `NSLog` in Production

**Files:** All `.m` files

Every method logs via `NSLog`, which writes to the system log in production builds. This is a minor performance issue and exposes internal method names.

**Fix:** Replace with `RCTLogInfo` (already used in one place) or wrap in `#ifdef DEBUG`:

```objc
#ifdef DEBUG
#define SDLog(...) NSLog(__VA_ARGS__)
#else
#define SDLog(...) ((void)0)
#endif
```

---

## Issue Summary Table

| # | Severity | File | Line | Issue |
|---|----------|------|------|-------|
| 1 | Critical | RNSodyoScanner.h | 14 | Static var in header — separate copies per file |
| 2 | Critical | RNSodyoSdk.m | 153 | Inverted null-check — scanner never saved |
| 3 | Critical | RNSodyoSdk.m | 124 | `BOOL *` instead of `BOOL` — always truthy |
| 4 | Critical | RNSodyoSdk.m | 35 | NSNotification observer never removed |
| 5 | Critical | RNSodyoSdk.m | 21-22 | Callback retain cycle — unused block never nilled |
| 6 | Major | RNSodyoSdk.m | 203 | NSError sent to JS — not serializable |
| 7 | Major | RNSodyoSdk.m | 211 | Nil value in array literal — crash |
| 8 | Major | RNSodyoSdk.m | 139 | Nil value in dict literal — crash on bad env |
| 9 | Major | RNSodyoSdk.m | 218 | Nil marker data — crash |
| 10 | Minor | RNSodyoSdk.m | 14 | Method named `init:` shadows NSObject |
| 11 | Minor | Multiple | — | Deprecated `window` access (iOS 15+) |
| 12 | Minor | RNSodyoSdkManager.m | 68 | Child VC never removed |
| 13 | Minor | RNSodyoSdkManager.m | 55 | No false-branch for troubleshooting toggle |
| 14 | Minor | All files | — | Excessive NSLog in production |
