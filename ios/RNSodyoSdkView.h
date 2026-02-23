#import <UIKit/UIKit.h>

@interface RNSodyoSdkView : UIView
@property (nonatomic, strong) UIView *scannerView;
@property (nonatomic, weak) UIViewController *scannerViewController;
- (instancetype)initWithView:(UIView *)view scanner:(UIViewController *)scanner;
@end