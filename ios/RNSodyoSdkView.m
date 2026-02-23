#import "RNSodyoSdkView.h"

@implementation RNSodyoSdkView

- (instancetype)initWithView:(UIView *)view scanner:(UIViewController *)scanner {
    NSLog(@"RNSodyoSdkView init");
    self = [super init];

    if (self) {
        _scannerView = view;
        _scannerViewController = scanner;
        [self addSubview:view];
    }

    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    // Temporarily detach scanner view before Fabric re-parents us
    if (_scannerView && _scannerView.superview == self) {
        [_scannerView removeFromSuperview];
    }
    [super willMoveToSuperview:newSuperview];
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    // Reattach scanner view after re-parenting is complete
    if (_scannerView && self.superview && _scannerView.superview != self) {
        [self addSubview:_scannerView];
        _scannerView.frame = self.bounds;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    for (UIView *view in self.subviews) {
        [view setFrame:self.bounds];
    }
}

// Issue #12 fix: remove child view controller on cleanup
- (void)removeFromSuperview {
    if (_scannerViewController) {
        [_scannerViewController willMoveToParentViewController:nil];
        [_scannerViewController removeFromParentViewController];
        _scannerViewController = nil;
    }
    [super removeFromSuperview];
}

@end