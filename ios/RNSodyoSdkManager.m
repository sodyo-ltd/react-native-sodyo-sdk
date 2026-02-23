#if __has_include(<React/RCTViewManager.h>)
  #import <React/RCTViewManager.h>
  #import <React/RCTConvert.h>
#else
  #import "RCTConvert.h"
  #import "RCTViewManager.h"
#endif

#if __has_include(<SodyoSDK/SodyoSDK.h>)
  #import <SodyoSDK/SodyoSDK.h>
#else
  #import "SodyoSDK.h"
#endif

#import <UIKit/UIKit.h>
#import "RNSodyoSdkView.h"
#import "RNSodyoScanner.h"

@interface RNSodyoSdkManager : RCTViewManager
@end

@implementation RNSodyoSdkManager

RCT_EXPORT_MODULE(RNSodyoSdkView)

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

RCT_CUSTOM_VIEW_PROPERTY(isEnabled, BOOL, UIView)
{
    NSLog(@"RNSodyoSdkManager set isEnabled");

    UIViewController *scanner = [RNSodyoScanner getSodyoScanner];

    if (!scanner) {
        return;
    }

    if ([RCTConvert BOOL:json]) {
        [SodyoSDK startScanning:scanner];
        return;
    }

    [SodyoSDK stopScanning:scanner];
}

// Issue #13 fix: add false branch for troubleshooting toggle
RCT_CUSTOM_VIEW_PROPERTY(isTroubleShootingEnabled, BOOL, UIView)
{
    NSLog(@"RNSodyoSdkManager set isTroubleShootingEnabled");

    UIViewController *scanner = [RNSodyoScanner getSodyoScanner];

    if (!scanner) {
        return;
    }

    if ([RCTConvert BOOL:json]) {
        [SodyoSDK startTroubleshoot:scanner];
        return;
    }

    [SodyoSDK setMode:scanner mode:SodyoModeNormal];
}

- (UIView *)view
{
    UIViewController *rootViewController = [self getRootViewController];

    UIViewController *scanner = [SodyoSDK initSodyoScanner];

    [RNSodyoScanner setSodyoScanner:scanner];
    [rootViewController addChildViewController:scanner];

    RNSodyoSdkView *view = [[RNSodyoSdkView alloc] initWithView:scanner.view scanner:scanner];

    [SodyoSDK setPresentingViewController:rootViewController];
    [scanner didMoveToParentViewController:rootViewController];

    return view;
}

@end