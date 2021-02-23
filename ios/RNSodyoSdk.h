
#if __has_include(<React/RCTBridgeModule.h>)
  #import <React/RCTBridgeModule.h>
  #import <React/RCTEventEmitter.h>
  #import <React/RCTLog.h>
#else
  #import "RCTBridgeModule.h"
  #import "RCTEventEmitter.h"
  #import "RCTLog.h"
#endif

#if __has_include(<SodyoSDK/SodyoSDK.h>)
  #import <SodyoSDK/SodyoSDK.h>
#else
  #import "SodyoSDK.h"
#endif

@interface RNSodyoSdk : RCTEventEmitter <RCTBridgeModule, SodyoSDKDelegate, SodyoMarkerDelegate> {
    UIViewController *sodyoScanner;
}

@property (nonatomic, strong) RCTResponseSenderBlock successStartCallback;
@property (nonatomic, strong) RCTResponseSenderBlock errorStartCallback;
@property (nonatomic) BOOL isCloseContentObserverExist;

@end
