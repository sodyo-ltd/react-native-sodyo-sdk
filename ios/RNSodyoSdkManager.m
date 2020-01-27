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

@interface RNSodyoSdkManager : RCTViewManager {
    UIViewController *sodyoScanner;
}
@end

@implementation RNSodyoSdkManager

RCT_EXPORT_MODULE(RNSodyoSdkView)

RCT_CUSTOM_VIEW_PROPERTY(isEnabled, BOOL, UIView)
{
    NSLog(@"RNSodyoSdkManager set isEnabled");

    if (!self->sodyoScanner) {
        return;
    }

    if ([RCTConvert BOOL:json]) {
        [SodyoSDK startScanning:self->sodyoScanner];
        return;
    }

    [SodyoSDK stopScanning:self->sodyoScanner];
}

- (UIView *)view
{
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;

    self->sodyoScanner = [SodyoSDK initSodyoScanner];
    [rootViewController addChildViewController:sodyoScanner];

    RNSodyoSdkView *view = [[RNSodyoSdkView alloc] initWithView:sodyoScanner.view];

    [SodyoSDK setPresentingViewController:rootViewController];
    [sodyoScanner didMoveToParentViewController:rootViewController];

    return view;
}

@end

