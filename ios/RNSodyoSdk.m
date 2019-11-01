
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

RCT_EXPORT_METHOD(setOverlayView:(NSString *)html)
{
    NSLog(@"setOverlayView");
    self.htmlOverlay = html;
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
    return @[@"EventSodyoError", @"EventMarkerDetectSuccess", @"EventMarkerDetectError", @"EventMarkerContent", @"EventWebViewCallback", @"EventCloseSodyoContent"];
}

- (void)setOverlayWebView
{
    UIView *overlay = [SodyoSDK overlayView];
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    self.webViewOverlay = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0,  rootViewController.view.frame.size.width, rootViewController.view.frame.size.height)];
    self.webViewOverlay.delegate = self;
    self.webViewOverlay.opaque = NO;
    self.webViewOverlay.scrollView.bounces = NO;
    self.webViewOverlay.backgroundColor = [UIColor clearColor];
    self.webViewOverlay.scalesPageToFit = YES;
    [self.webViewOverlay loadHTMLString:self.htmlOverlay baseURL:nil];
    [overlay addSubview:self.webViewOverlay];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        NSURL *url = request.URL;
        NSString *scheme = [url scheme];
        if ([scheme isEqualToString:@"sodyosdk"]) {
            NSString *absoluteUrl = [url absoluteString];
            NSArray *parsedUrl = [absoluteUrl componentsSeparatedByString:@"sodyosdk://"];
            if ([parsedUrl count] < 2) return NO;

            NSString *methodName = parsedUrl[1];
            [self sendEventWithName:@"EventWebViewCallback" body:@{@"callback": methodName}];
        }
    }

    return YES;
}

- (void) launchSodyoScanner {
    NSLog(@"launchSodyoScanner");
    if (!self->sodyoScanner) {
        self->sodyoScanner = [SodyoSDK initSodyoScanner];
    }

    if (!self.webViewOverlay) {
        [self setOverlayWebView];
    }

    if (sodyoScanner.isViewLoaded && sodyoScanner.view.window) {
        NSLog(@"Sodyo scanner already active");
        return;
    }

    if (self.htmlOverlay) {
        [self.webViewOverlay loadHTMLString:self.htmlOverlay baseURL:nil];
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
    NSLog(@"sendCloseContentEcent");
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
