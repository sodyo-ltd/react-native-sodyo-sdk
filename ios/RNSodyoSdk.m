
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
    RCTLogInfo(@"SodyoSDK: init()");

    self.successStartCallback = successCallback;
    self.errorStartCallback = errorCallback;
    [SodyoSDK LoadApp:apiKey Delegate:self MarkerDelegate:self PresentingViewController:nil];
}

RCT_EXPORT_METHOD(createCloseContentListener)
{
    RCTLogInfo(@"SodyoSDK: createCloseContentListener()");

    if (self.isCloseContentObserverExist) {
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
    NSLog(@"start");
    [self launchSodyoScanner];
}

RCT_EXPORT_METHOD(close)
{
    NSLog(@"close");
    [self closeScanner];
}

RCT_EXPORT_METHOD(setCustomAdLabel:(NSString *)labels)
{
    NSLog(@"setCustomAdLabel");
    [SodyoSDK setCustomAdLabel:labels];
}

RCT_EXPORT_METHOD(setAppUserId:(NSString *)userId)
{
    NSLog(@"setAppUserId");
    [SodyoSDK setUserId:userId];
}

RCT_EXPORT_METHOD(setUserInfo:(NSDictionary *) userInfo)
{
    NSLog(@"setUserInfo");
    [SodyoSDK setUserInfo:userInfo];
}

RCT_EXPORT_METHOD(setScannerParams:(NSDictionary *) params)
{
    NSLog(@"setScannerParams");
    [SodyoSDK setScannerParams:params];
}

RCT_EXPORT_METHOD(addScannerParam:(NSString *) key value:(NSString *) value)
{
    NSLog(@"addScannerParam");
    [SodyoSDK addScannerParams:key value:value];
}

RCT_EXPORT_METHOD(setDynamicProfile:(NSDictionary *) profile)
{
    NSLog(@"setDynamicProfile");
    [SodyoSDK setDynamicProfile:profile];
}

RCT_EXPORT_METHOD(setDynamicProfileValue:(NSString *) key value:(NSString *) value)
{
    NSLog(@"setDynamicProfileValue");
    [SodyoSDK setDynamicProfileValue:key value:value];
}

RCT_EXPORT_METHOD(performMarker:(NSString *) markerId customProperties:(NSDictionary *) customProperties)
{
    NSLog(@"performMarker");
    UIViewController *rootViewController = [self getRootViewController];
    [SodyoSDK setPresentingViewController:rootViewController];
    [SodyoSDK performMarker:markerId customProperties:customProperties];
}

RCT_EXPORT_METHOD(startTroubleshoot)
{
    NSLog(@"startTroubleshoot");
    UIViewController *scanner = [RNSodyoScanner getSodyoScanner];
    [SodyoSDK startTroubleshoot:scanner];
}


RCT_EXPORT_METHOD(setTroubleshootMode)
{
    NSLog(@"setTroubleshootMode");
    UIViewController *scanner = [RNSodyoScanner getSodyoScanner];
    [SodyoSDK setMode:scanner mode:SodyoModeTroubleshoot];
}

RCT_EXPORT_METHOD(setNormalMode)
{
    NSLog(@"setNormalMode");
    UIViewController *scanner = [RNSodyoScanner getSodyoScanner];
    [SodyoSDK setMode:scanner mode:SodyoModeNormal];
}

// Issue #3 fix: BOOL instead of BOOL*
RCT_EXPORT_METHOD(setSodyoLogoVisible:(BOOL) isVisible)
{
    NSLog(@"setSodyoLogoVisible");
    if (isVisible) {
        return [SodyoSDK showDefaultOverlay];
    }

    [SodyoSDK hideDefaultOverlay];
}

// Issue #8 fix: guard against nil env value
RCT_EXPORT_METHOD(setEnv:(NSString *) env)
{
    NSLog(@"setEnv");

    NSDictionary *envs = @{ @"DEV": @"3", @"QA": @"1", @"PROD": @"0" };
    NSString *envValue = envs[env];
    if (!envValue) {
        NSLog(@"RNSodyoSdk: Unknown env '%@', defaulting to PROD", env);
        envValue = @"0";
    }
    NSDictionary *params = @{ @"SodyoAdEnv": envValue, @"ScanQR": @"false" };
    [SodyoSDK setScannerParams:params];
}

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"EventSodyoError", @"EventMarkerDetectSuccess", @"EventMarkerDetectError", @"EventMarkerContent", @"EventCloseSodyoContent", @"ModeChangeCallback"];
}

// Issue #2 fix: inverted null-check + use shared scanner accessor
- (void) launchSodyoScanner {
    NSLog(@"launchSodyoScanner");
    UIViewController *scanner = [RNSodyoScanner getSodyoScanner];

    if (!scanner) {
        NSLog(@"Sodyo scanner not initialized");
        return;
    }

    if (scanner.isViewLoaded && scanner.view.window) {
        NSLog(@"Sodyo scanner already active");
        return;
    }

    UIViewController *rootViewController = [self getRootViewController];
    scanner.modalPresentationStyle = UIModalPresentationFullScreen;
    [SodyoSDK setPresentingViewController:rootViewController];
    [rootViewController presentViewController:scanner animated:YES completion:nil];
}

- (void) closeScanner {
    NSLog(@"closeScanner");
    UIViewController *rootViewController = [self getRootViewController];
    [rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void) sendCloseContentEvent {
    NSLog(@"sendCloseContentEvent");
    [self sendEventWithName:@"EventCloseSodyoContent" body:nil];
}

- (NSString *) convertScannerModeToString:(SodyoMode)mode {
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
    NSLog(@"onSodyoAppLoadSuccess");

    if (self.successStartCallback != nil) {
        self.successStartCallback(@[[NSNull null]]);
    }
    self.successStartCallback = nil;
    self.errorStartCallback = nil;
}

// Issue #6 fix: serialize NSError to string
- (void) onSodyoAppLoadFailed:(NSInteger)AppID error:(NSError *)error {
    NSLog(@"Failed loading Sodyo: %@", error);
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
        NSLog(@"sodyoError: %@", desc);
        [self sendEventWithName:@"EventSodyoError" body:@{@"error": desc}];
    });
}

// Issue #9 fix: guard against nil marker data
- (void) SodyoMarkerDetectedWithData:(NSDictionary*)Data {
    NSLog(@"SodyoMarkerDetectedWithData: %@", Data[@"sodyoMarkerData"]);
    id markerData = Data[@"sodyoMarkerData"] ?: [NSNull null];
    [self sendEventWithName:@"EventMarkerDetectSuccess" body:@{@"data": markerData}];
}

- (void) SodyoMarkerContent:(NSString *)markerId Data:(NSDictionary *)Data {
    NSLog(@"SodyoMarkerContent: %@", Data);
    id data = Data ?: @{};
    [self sendEventWithName:@"EventMarkerContent" body:@{@"markerId": markerId ?: @"", @"data": data}];
}


- (void) onModeChange:(SodyoMode)from to:(SodyoMode)to {
    NSLog(@"onModeChange");
    NSString* fromConverted = [self convertScannerModeToString:from];
    NSString* toConverted = [self convertScannerModeToString:to];

    [self sendEventWithName:@"ModeChangeCallback" body:@{@"oldMode": fromConverted, @"newMode": toConverted}];
}

@end