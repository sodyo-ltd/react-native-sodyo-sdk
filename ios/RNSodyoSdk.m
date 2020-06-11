
#import "RNSodyoSdk.h"

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

    self.succesStartCallback = successCallback;
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

RCT_EXPORT_METHOD(performMarker:(NSString *) markerId)
{
    NSLog(@"performMarker");
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    [SodyoSDK setPresentingViewController:rootViewController];
    [SodyoSDK performMarker:markerId];
}

RCT_EXPORT_METHOD(setSodyoLogoVisible:(BOOL *) isVisible)
{
    NSLog(@"setSodyoLogoVisible");
    if (isVisible) {
        return [SodyoSDK showDefaultOverlay];
    }

    [SodyoSDK hideDefaultOverlay];
}

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"EventSodyoError", @"EventMarkerDetectSuccess", @"EventMarkerDetectError", @"EventMarkerContent", @"EventCloseSodyoContent"];
}

- (void) launchSodyoScanner {
    NSLog(@"launchSodyoScanner");
    if (!self->sodyoScanner) {
        self->sodyoScanner = [SodyoSDK initSodyoScanner];
    }

    if (sodyoScanner.isViewLoaded && sodyoScanner.view.window) {
        NSLog(@"Sodyo scanner already active");
        return;
    }

    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    self->sodyoScanner.modalPresentationStyle = UIModalPresentationFullScreen;
    [SodyoSDK setPresentingViewController:rootViewController];
    [rootViewController presentViewController:self->sodyoScanner animated:YES completion:nil];
}

- (void) closeScanner {
    NSLog(@"closeScanner");
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    [rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void) sendCloseContentEvent {
    NSLog(@"sendCloseContentEvent");
    [self sendEventWithName:@"EventCloseSodyoContent" body:nil];
}

#pragma mark - SodyoSDKDelegate
- (void) onSodyoAppLoadSuccess:(NSInteger)AppID {
    NSLog(@"onSodyoAppLoadSuccess");

    if (self.succesStartCallback != nil) {
        self.succesStartCallback(@[[NSNull null]]);
        self.succesStartCallback = nil;
    }
}

- (void) onSodyoAppLoadFailed:(NSInteger)AppID error:(NSError *)error {
    NSLog(@"Failed loading Sodyo: %@", error);
    if (self.errorStartCallback != nil) {
        self.errorStartCallback(@[@{@"error": error}]);
        self.errorStartCallback = nil;
    }
}

- (void) sodyoError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"sodyoError: %@", error.userInfo[@"NSLocalizedDescription"]);
        NSArray* params = @[@"sodyoError", error.userInfo[@"NSLocalizedDescription"]];
        [self sendEventWithName:@"EventSodyoError" body:@{@"error": params[1]}];
    });
}

- (void) SodyoMarkerDetectedWithData:(NSDictionary*)Data {
    NSLog(@"SodyoMarkerDetectedWithData: %@", Data[@"sodyoMarkerData"]);
    [self sendEventWithName:@"EventMarkerDetectSuccess" body:@{@"data": Data[@"sodyoMarkerData"]}];
}

- (void) SodyoMarkerContent:(NSString *)markerId Data:(NSDictionary *)Data {
    NSLog(@"SodyoMarkerDetectedWithData: %@", Data);
    [self sendEventWithName:@"EventMarkerContent" body:@{@"markerId": markerId, @"data": Data}];
}
@end
