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
#import "RNSodyoSdkView.m"
#import "RNSodyoScanner.h"

@interface RNSodyoSdkManager : RCTViewManager {
}
@end

@implementation RNSodyoSdkManager

RCT_EXPORT_MODULE(RNSodyoSdkView)

RCT_CUSTOM_VIEW_PROPERTY(isEnabled, BOOL, UIView)
{
    NSLog(@"RNSodyoSdkManager set isEnabled");

    sodyoScanner = [RNSodyoScanner getSodyoScanner];

    if (!sodyoScanner) {
        return;
    }

    if ([RCTConvert BOOL:json]) {
        [SodyoSDK startScanning:sodyoScanner];
        return;
    }

    [SodyoSDK stopScanning:sodyoScanner];
}

RCT_CUSTOM_VIEW_PROPERTY(isTroubleShootingEnabled, BOOL, UIView)
{
    NSLog(@"RNSodyoSdkManager set isTroubleShootingEnabled");

    sodyoScanner = [RNSodyoScanner getSodyoScanner];

    if (!sodyoScanner) {
        return;
    }

    if ([RCTConvert BOOL:json]) {
        [SodyoSDK startTroubleshoot:sodyoScanner];
        return;
    }
}

- (UIView *)view
{
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;

    sodyoScanner = [SodyoSDK initSodyoScanner];

    [RNSodyoScanner setSodyoScanner:sodyoScanner];
    [rootViewController addChildViewController:sodyoScanner];

    RNSodyoSdkView *view = [[RNSodyoSdkView alloc] initWithView:sodyoScanner.view];

    [SodyoSDK setPresentingViewController:rootViewController];
    [sodyoScanner didMoveToParentViewController:rootViewController];

    return view;
}

@end

