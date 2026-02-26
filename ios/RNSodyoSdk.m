#import "RNSodyoSdk.h"
#import "RNSodyoScanner.h"

@implementation RNSodyoSdk

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(
  init:(NSString *)apiKey
  successCallback:(RCTResponseSenderBlock)successCallback
  errorCallback:(RCTResponseSenderBlock)errorCallback
)
{
    RCTLogInfo(@"SodyoSDK: init() - apiKey: %@, successCallback: %@, errorCallback: %@", apiKey, successCallback ? @"provided" : @"nil", errorCallback ? @"provided" : @"nil");

    self.successStartCallback = successCallback;
    self.errorStartCallback = errorCallback;
    [SodyoSDK LoadApp:apiKey Delegate:self MarkerDelegate:self PresentingViewController:nil];
}

RCT_EXPORT_METHOD(createCloseContentListener)
{
    RCTLogInfo(@"SodyoSDK: createCloseContentListener() - isCloseContentObserverExist: %@", self.isCloseContentObserverExist ? @"YES" : @"NO");

    if (self.isCloseContentObserverExist) {
        NSLog(@"SodyoSDK: createCloseContentListener - observer already exists, skipping");
        return;
    }

    self.isCloseContentObserverExist = true;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendCloseContentEvent) name:@"SodyoNotificationCloseIAD" object:nil];
}

// Issue #4 fix: remove notification observer on dealloc
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

RCT_EXPORT_METHOD(start)
{
    NSLog(@"SodyoSDK: start - launching scanner");
    [self launchSodyoScanner];
}

RCT_EXPORT_METHOD(close)
{
    NSLog(@"SodyoSDK: close - closing scanner");
    [self closeScanner];
}

RCT_EXPORT_METHOD(setCustomAdLabel:(NSString *)labels)
{
    NSLog(@"SodyoSDK: setCustomAdLabel - labels: %@", labels);
    [SodyoSDK setCustomAdLabel:labels];
}

RCT_EXPORT_METHOD(setAppUserId:(NSString *)userId)
{
    NSLog(@"SodyoSDK: setAppUserId - userId: %@", userId);
    [SodyoSDK setUserId:userId];
}

RCT_EXPORT_METHOD(setUserInfo:(NSDictionary *) userInfo)
{
    NSLog(@"SodyoSDK: setUserInfo - userInfo: %@", userInfo);
    [SodyoSDK setUserInfo:userInfo];
}

RCT_EXPORT_METHOD(setScannerParams:(NSDictionary *) params)
{
    NSLog(@"SodyoSDK: setScannerParams - params: %@", params);
    [SodyoSDK setScannerParams:params];
}

RCT_EXPORT_METHOD(addScannerParam:(NSString *) key value:(NSString *) value)
{
    NSLog(@"SodyoSDK: addScannerParam - key: %@, value: %@", key, value);
    [SodyoSDK addScannerParams:key value:value];
}

RCT_EXPORT_METHOD(setDynamicProfile:(NSDictionary *) profile)
{
    NSLog(@"SodyoSDK: setDynamicProfile - profile: %@", profile);
    [SodyoSDK setDynamicProfile:profile];
}

RCT_EXPORT_METHOD(setDynamicProfileValue:(NSString *) key value:(NSString *) value)
{
    NSLog(@"SodyoSDK: setDynamicProfileValue - key: %@, value: %@", key, value);
    [SodyoSDK setDynamicProfileValue:key value:value];
}

RCT_EXPORT_METHOD(performMarker:(NSString *) markerId customProperties:(NSDictionary *) customProperties)
{
    NSLog(@"SodyoSDK: performMarker - markerId: %@, customProperties: %@", markerId, customProperties);
    UIViewController *rootViewController = [self getRootViewController];
    NSLog(@"SodyoSDK: performMarker - rootViewController: %@", rootViewController);
    [SodyoSDK setPresentingViewController:rootViewController];
    [SodyoSDK performMarker:markerId customProperties:customProperties];
}

RCT_EXPORT_METHOD(startTroubleshoot)
{
    NSLog(@"SodyoSDK: startTroubleshoot");
    UIViewController *scanner = [RNSodyoScanner getSodyoScanner];
    NSLog(@"SodyoSDK: startTroubleshoot - scanner: %@", scanner);
    [SodyoSDK startTroubleshoot:scanner];
}


RCT_EXPORT_METHOD(setTroubleshootMode)
{
    NSLog(@"SodyoSDK: setTroubleshootMode");
    UIViewController *scanner = [RNSodyoScanner getSodyoScanner];
    NSLog(@"SodyoSDK: setTroubleshootMode - scanner: %@", scanner);
    [SodyoSDK setMode:scanner mode:SodyoModeTroubleshoot];
}

RCT_EXPORT_METHOD(setNormalMode)
{
    NSLog(@"SodyoSDK: setNormalMode");
    UIViewController *scanner = [RNSodyoScanner getSodyoScanner];
    NSLog(@"SodyoSDK: setNormalMode - scanner: %@", scanner);
    [SodyoSDK setMode:scanner mode:SodyoModeNormal];
}

// Issue #3 fix: BOOL instead of BOOL*
RCT_EXPORT_METHOD(setSodyoLogoVisible:(BOOL) isVisible)
{
    NSLog(@"SodyoSDK: setSodyoLogoVisible - isVisible: %@", isVisible ? @"YES" : @"NO");
    if (isVisible) {
        return [SodyoSDK showDefaultOverlay];
    }

    [SodyoSDK hideDefaultOverlay];
}

// Issue #8 fix: guard against nil env value
RCT_EXPORT_METHOD(setEnv:(NSString *) env)
{
    NSLog(@"SodyoSDK: setEnv - env: %@", env);

    NSDictionary *envs = @{ @"DEV": @"3", @"QA": @"1", @"PROD": @"0" };
    NSString *envValue = envs[env];
    if (!envValue) {
        NSLog(@"SodyoSDK: setEnv - Unknown env '%@', defaulting to PROD", env);
        envValue = @"0";
    }
    NSDictionary *params = @{ @"SodyoAdEnv": envValue, @"ScanQR": @"false" };
    NSLog(@"SodyoSDK: setEnv - resolved params: %@", params);
    [SodyoSDK setScannerParams:params];
}

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"EventSodyoError", @"EventMarkerDetectSuccess", @"EventMarkerDetectError", @"EventMarkerContent", @"EventCloseSodyoContent", @"ModeChangeCallback"];
}

// Issue #2 fix: inverted null-check + use shared scanner accessor
- (void) launchSodyoScanner {
    NSLog(@"SodyoSDK: launchSodyoScanner");
    UIViewController *scanner = [RNSodyoScanner getSodyoScanner];
    NSLog(@"SodyoSDK: launchSodyoScanner - scanner: %@", scanner);

    if (!scanner) {
        NSLog(@"SodyoSDK: launchSodyoScanner - scanner not initialized, aborting");
        return;
    }

    if (scanner.isViewLoaded && scanner.view.window) {
        NSLog(@"SodyoSDK: launchSodyoScanner - scanner already active (isViewLoaded: %@, window: %@)", scanner.isViewLoaded ? @"YES" : @"NO", scanner.view.window);
        return;
    }

    UIViewController *rootViewController = [self getRootViewController];
    NSLog(@"SodyoSDK: launchSodyoScanner - rootViewController: %@", rootViewController);
    scanner.modalPresentationStyle = UIModalPresentationFullScreen;
    [SodyoSDK setPresentingViewController:rootViewController];
    [rootViewController presentViewController:scanner animated:YES completion:nil];
}

- (void) closeScanner {
    NSLog(@"SodyoSDK: closeScanner");
    UIViewController *rootViewController = [self getRootViewController];
    NSLog(@"SodyoSDK: closeScanner - rootViewController: %@", rootViewController);
    [rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void) sendCloseContentEvent {
    NSLog(@"SodyoSDK: sendCloseContentEvent - sending EventCloseSodyoContent");
    [self sendEventWithName:@"EventCloseSodyoContent" body:nil];
}

- (NSString *) convertScannerModeToString:(SodyoMode)mode {
    NSLog(@"SodyoSDK: convertScannerModeToString - mode: %ld", (long)mode);
    switch (mode) {
        case SodyoModeTroubleshoot:
            return @"Troubleshoot";
        case SodyoModeNormal:
            return @"Normal";
        default:
            return @"";
    }
}

// Issue #11 fix: UIScene-compatible root view controller access
- (UIViewController *)getRootViewController {
    UIWindow *keyWindow = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) {
                        keyWindow = window;
                        break;
                    }
                }
                if (keyWindow) break;
            }
        }
    }
    if (!keyWindow) {
        keyWindow = [UIApplication sharedApplication].delegate.window;
    }
    return keyWindow.rootViewController;
}

#pragma mark - SodyoSDKDelegate
// Issue #5 fix: nil both callbacks after either fires
- (void) onSodyoAppLoadSuccess:(NSInteger)AppID {
    NSLog(@"SodyoSDK: onSodyoAppLoadSuccess - AppID: %ld, successCallback: %@", (long)AppID, self.successStartCallback ? @"provided" : @"nil");

    if (self.successStartCallback != nil) {
        self.successStartCallback(@[[NSNull null]]);
    }
    self.successStartCallback = nil;
    self.errorStartCallback = nil;
}

// Issue #6 fix: serialize NSError to string
- (void) onSodyoAppLoadFailed:(NSInteger)AppID error:(NSError *)error {
    NSLog(@"SodyoSDK: onSodyoAppLoadFailed - AppID: %ld, error: %@, errorCode: %ld, errorDomain: %@", (long)AppID, error.localizedDescription, (long)error.code, error.domain);
    if (self.errorStartCallback != nil) {
        NSString *message = error.localizedDescription ?: @"Unknown error";
        self.errorStartCallback(@[@{@"error": message}]);
    }
    self.successStartCallback = nil;
    self.errorStartCallback = nil;
}

// Issue #7 fix: guard against nil error description
- (void) sodyoError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *desc = error.localizedDescription ?: @"Unknown error";
        NSLog(@"SodyoSDK: sodyoError - description: %@, code: %ld, domain: %@, userInfo: %@", desc, (long)error.code, error.domain, error.userInfo);
        [self sendEventWithName:@"EventSodyoError" body:@{@"error": desc}];
    });
}

// Issue #9 fix: guard against nil marker data
- (void) SodyoMarkerDetectedWithData:(NSDictionary*)Data {
    NSLog(@"SodyoSDK: SodyoMarkerDetectedWithData - fullData: %@, sodyoMarkerData: %@", Data, Data[@"sodyoMarkerData"]);
    id markerData = Data[@"sodyoMarkerData"] ?: [NSNull null];
    [self sendEventWithName:@"EventMarkerDetectSuccess" body:@{@"data": markerData}];
}

- (void) SodyoMarkerContent:(NSString *)markerId Data:(NSDictionary *)Data {
    NSLog(@"SodyoSDK: SodyoMarkerContent - markerId: %@, Data: %@", markerId, Data);
    id data = Data ?: @{};
    [self sendEventWithName:@"EventMarkerContent" body:@{@"markerId": markerId ?: @"", @"data": data}];
}


- (void) onModeChange:(SodyoMode)from to:(SodyoMode)to {
    NSString* fromConverted = [self convertScannerModeToString:from];
    NSString* toConverted = [self convertScannerModeToString:to];
    NSLog(@"SodyoSDK: onModeChange - from: %@ (%ld) to: %@ (%ld)", fromConverted, (long)from, toConverted, (long)to);

    [self sendEventWithName:@"ModeChangeCallback" body:@{@"oldMode": fromConverted, @"newMode": toConverted}];
}

@end